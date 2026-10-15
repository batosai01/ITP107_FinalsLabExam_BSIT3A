import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  // ---------- UPDATE ----------
  Future<void> _editNote(BuildContext context, Map post) async {
    final controller = TextEditingController(text: post['note'] ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Personal Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Write a short note...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final box = Hive.box('favoritesBox');
      final updated = Map<String, dynamic>.from(post);
      updated['note'] = controller.text.trim();
      await box.put(post['id'], updated);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note updated!'),
            backgroundColor: Color(0xFF15803D),
          ),
        );
      }
    }
  }

  // ---------- DELETE ----------
  Future<void> _delete(BuildContext context, int id) async {
    await Hive.box('favoritesBox').delete(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Removed from favorites.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('favoritesBox');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          // ---------- READ ----------
          final favorites = b.values.toList();

          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 72, color: scheme.primary.withAlpha(110)),
                    const SizedBox(height: 16),
                    Text('No favorites yet',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                      'Open a post and tap "Save to Favorites" to see it here.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(180, 48)),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Browse posts'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 24),
            itemCount: favorites.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    '${favorites.length} saved '
                    '${favorites.length == 1 ? 'post' : 'posts'}  •  swipe left to remove',
                    style: TextStyle(
                      color: scheme.onSurface.withAlpha(150),
                      fontSize: 13,
                    ),
                  ),
                );
              }

              final post = Map<String, dynamic>.from(favorites[index - 1]);
              final note = (post['note'] ?? '') as String;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Dismissible(
                  key: ValueKey(post['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _delete(context, post['id']),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            foregroundColor: scheme.onPrimaryContainer,
                            child: Text('${post['id']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _cap(post['title']),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        scheme.primaryContainer.withAlpha(120),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.sticky_note_2_outlined,
                                          size: 16,
                                          color: scheme.onPrimaryContainer),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          note.isEmpty ? 'No note yet' : note,
                                          style: TextStyle(
                                            fontStyle: note.isEmpty
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                            color: scheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined,
                                    color: scheme.primary),
                                tooltip: 'Edit note',
                                onPressed: () => _editNote(context, post),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.red.shade300),
                                tooltip: 'Remove',
                                onPressed: () => _delete(context, post['id']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
