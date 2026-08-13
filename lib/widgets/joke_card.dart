import 'package:flutter/material.dart';
import '../models/joke.dart';
import 'status_chip.dart';

class JokeCard extends StatelessWidget {
  final Joke joke;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddToSetlist;
  final VoidCallback? onTap;

  const JokeCard({
    super.key,
    required this.joke,
    this.onEdit,
    this.onDelete,
    this.onAddToSetlist,
    this.onTap,
  });

  static const Map<String, String> typeLabels = {
    'observation': 'Наблюдение',
    'story': 'История',
    'oneline': 'Одностишье',
    'crowd': 'Взаимодействие',
    'sketch': 'Скетч',
  };

  @override
  Widget build(BuildContext context) {
    final tags = joke.tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      joke.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (onAddToSetlist != null)
                    IconButton(
                      icon: const Icon(Icons.playlist_add, size: 20),
                      onPressed: onAddToSetlist,
                      tooltip: 'В сет-лист',
                    ),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Редактировать',
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Удалить',
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                joke.setup,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                joke.punchline,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(tag, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  )),
                  StatusChip(status: joke.status),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(joke.time, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ],
              ),
              if (joke.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.comment, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        joke.notes,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
