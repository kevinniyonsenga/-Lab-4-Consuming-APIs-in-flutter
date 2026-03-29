import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../exceptions/api_exceptions.dart';
import 'post_form_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _service = PostService();

  // Use local post state — no re-fetch needed
  late Post _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
  }

  String _friendlyError(Object e) {
    if (e is NetworkException) return e.message;
    if (e is ServerException) return 'Server error (${e.statusCode})';
    return 'Unable to complete the action.';
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
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
      await _service.deletePost(_currentPost.id!);
      if (mounted) {
        // Return a signal to the list screen to remove this post
        Navigator.pop(context, 'deleted:${_currentPost.id}');
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Post Detail'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () async {
              final updated = await Navigator.push<Post>(
                context,
                MaterialPageRoute(
                    builder: (_) => PostFormScreen(post: _currentPost)),
              );
              if (updated != null) {
                // Update local state so detail view reflects changes instantly
                setState(() => _currentPost = updated);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _delete,
          ),
        ],
      ),

      // ── No FutureBuilder needed — we already have the post locally ────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User badge row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    'U${_currentPost.userId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Text('User ${_currentPost.userId}',
                    style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                Chip(
                  label: Text('ID: ${_currentPost.id}'),
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              _currentPost.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const Divider(height: 32),

            // Body
            Text(
              _currentPost.body,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF444444),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
