import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  void _saveToFavorites(BuildContext context, Map<String, dynamic> args) {
    final box = Hive.box('favoritesBox');
    final int id = args['id'];

    String message;
    Color color;

    if (box.containsKey(id)) {
      message = 'This post is already in your favorites.';
      color = Colors.orange.shade800;
    } else {
      box.put(id, {
        'id': id,
        'title': args['title'],
        'body': args['body'],
        'note': '',
      });
      message = 'Saved to favorites!';
      color = const Color(0xFF15803D);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final scheme = Theme.of(context).colorScheme;
    final box = Hive.box('favoritesBox');
    final String title = args['title'];
    final String body = args['body'];

    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      avatar: Icon(Icons.tag,
                          size: 18, color: scheme.onPrimaryContainer),
                      label: Text('Post ${args['id']}',
                          style: TextStyle(color: scheme.onPrimaryContainer)),
                      backgroundColor: scheme.primaryContainer,
                      side: BorderSide.none,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _cap(title),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    Text(
                      _cap(body),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: scheme.onSurface.withAlpha(200)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box b, _) {
                final saved = b.containsKey(args['id']);
                return FilledButton.icon(
                  onPressed: () => _saveToFavorites(context, args),
                  icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
                  label:
                      Text(saved ? 'Saved to Favorites' : 'Save to Favorites'),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
