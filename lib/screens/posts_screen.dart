import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  static const String _url = 'https://jsonplaceholder.typicode.com/posts';

  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  // ---------- GET ----------
  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse(_url));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _posts = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              'Failed to load posts (status code: ${response.statusCode}).';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not connect. Check your internet.\n$e';
        _isLoading = false;
      });
    }
  }

  // ---------- POST ----------
  Future<void> _createPost(String title, String body) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'title': title, 'body': body, 'userId': 1}),
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        _showMessage('Post created successfully!');
      } else {
        _showMessage('Failed to create post (status ${response.statusCode}).',
            isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error sending post: $e', isError: true);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.red.shade700 : const Color(0xFF15803D),
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Post'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title cannot be empty'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: bodyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Body'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Body cannot be empty'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (send == true) {
      await _createPost(titleCtrl.text.trim(), bodyCtrl.text.trim());
    }
  }

  // ---------- UI ----------
  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildBody() {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, color: scheme.error, size: 56),
                const SizedBox(height: 12),
                Text('Something went wrong',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error)),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _fetchPosts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: Text('${post['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(
              _cap(post['title']),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _cap(post['body']),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurface.withAlpha(170)),
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: scheme.primary),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/details',
                arguments: {
                  'id': post['id'],
                  'title': post['title'],
                  'body': post['body'],
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorites',
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('New post'),
      ),
    );
  }
}
