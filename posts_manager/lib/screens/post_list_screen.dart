import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../exceptions/api_exceptions.dart';
import 'post_detail_screen.dart';
import 'post_form_screen.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final PostService _service = PostService();

  late Future<List<Post>> _postsFuture;

  // Local in-memory list — source of truth after first load
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _postsFuture = _loadPosts();
  }

  Future<List<Post>> _loadPosts() async {
    final posts = await _service.fetchPosts();
    // Renumber from 1 so IDs are always clean sequential numbers
    _posts = posts.asMap().entries.map((e) {
      return e.value.copyWith(id: e.key + 1);
    }).toList();
    return _posts;
  }

  void _refresh() {
    setState(() => _postsFuture = _loadPosts());
  }

  String _friendlyError(Object error) {
    if (error is NetworkException) return error.message;
    if (error is ServerException) return 'Server error (${error.statusCode})';
    if (error is DataParseException) return 'Could not read data from server.';
    return 'Something went wrong. Please try again.';
  }

  // ─── Renumber all posts sequentially ─────────────────────────────────────
  void _renumber() {
    setState(() {
      _posts = _posts.asMap().entries.map((e) {
        return e.value.copyWith(id: e.key + 1);
      }).toList();
    });
  }

  // ─── ADD post locally ─────────────────────────────────────────────────────
  void _addPostLocally(Post post) {
    setState(() {
      final nextId = _posts.isNotEmpty
          ? (_posts.map((p) => p.id ?? 0).reduce((a, b) => a > b ? a : b) + 1)
          : 1;
      _posts.add(post.copyWith(id: nextId)); // add at END with correct next ID
    });
  }

  // ─── UPDATE post locally ──────────────────────────────────────────────────
  void _updatePostLocally(Post updated) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == updated.id);
      if (index != -1) _posts[index] = updated;
    });
  }

  // ─── DELETE post locally ──────────────────────────────────────────────────
  void _deletePostLocally(int id) {
    setState(() => _posts.removeWhere((p) => p.id == id));
    _renumber(); // resequence all IDs after deletion
  }

  Future<void> _confirmDelete(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Delete "${post.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deletePost(post.id!);
      _deletePostLocally(post.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Post deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Posts Manager',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh from server',
              onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          // 1. Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading posts…', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 2. Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(_friendlyError(snapshot.error!),
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again')),
                  ],
                ),
              ),
            );
          }

          // 3. Data — use _posts (local list) not snapshot.data
          if (_posts.isEmpty) {
            return const Center(
              child: Text('No posts yet. Create one!',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              final post = _posts[index];
              return _PostCard(
                post: post,
                onTap: () async {
                  final result = await Navigator.push<dynamic>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PostDetailScreen(post: post)),
                  );
                  // Handle delete from detail screen
                  if (result is String && result.startsWith('deleted:')) {
                    final deletedId = int.tryParse(result.split(':').last);
                    if (deletedId != null) _deletePostLocally(deletedId);
                  }
                  // Handle edit from detail screen
                  if (result is Post) {
                    _updatePostLocally(result);
                  }
                },
                onEdit: () async {
                  final updated = await Navigator.push<Post>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PostFormScreen(post: post)),
                  );
                  if (updated != null) _updatePostLocally(updated);
                },
                onDelete: () => _confirmDelete(post),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<Post>(
            context,
            MaterialPageRoute(builder: (_) => const PostFormScreen()),
          );
          if (created != null) _addPostLocally(created);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─── Post Card ────────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      '${post.id}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ActionChip(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: Colors.blue,
                      onTap: onEdit),
                  const SizedBox(width: 8),
                  _ActionChip(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: Colors.red,
                      onTap: onDelete),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Action Chip ──────────────────────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(20),
          color: color.withOpacity(0.07),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
