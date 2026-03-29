import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../exceptions/api_exceptions.dart';

class PostFormScreen extends StatefulWidget {
  /// Pass a [post] to edit; leave null to create a new one.
  final Post? post;
  const PostFormScreen({super.key, this.post});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  bool get _isEditing => widget.post != null;
  bool _loading = false;

  final PostService _service = PostService();

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleCtrl.text = widget.post!.title;
      _bodyCtrl.text = widget.post!.body;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  String _friendlyError(Object e) {
    if (e is NetworkException) return e.message;
    if (e is ServerException) return 'Server error (${e.statusCode})';
    return 'Something went wrong. Please try again.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_isEditing) {
        final updated = widget.post!.copyWith(
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
        );
        await _service.updatePost(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, updated); // ← returns updated post to list
        }
      } else {
        final newPost = Post(
          userId: 1,
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
        );
        final created = await _service.createPost(newPost);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New Post created Successfull!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, created); // ← returns created post to list
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Post' : 'New Post'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Title field ────────────────────────────────────────────
              const Text(
                'Title',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                decoration: _inputDecoration('Enter post title'),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Body field ─────────────────────────────────────────────
              const Text(
                'Body',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bodyCtrl,
                decoration: _inputDecoration('Write the post content…'),
                maxLines: 8,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Body is required' : null,
              ),
              const SizedBox(height: 32),

              // ── Submit button ──────────────────────────────────────────
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Create Post',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
