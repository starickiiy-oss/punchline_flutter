import 'package:flutter/material.dart';
import '../models/joke.dart';
import '../database/database_helper.dart';
import 'add_edit_joke_screen.dart';

class JokeDetailScreen extends StatelessWidget {
  final Joke joke;
  const JokeDetailScreen({super.key, required this.joke});

  static const Map<String, String> typeLabels = {
    'observation': 'Наблюдение',
    'story': 'История',
    'oneline': 'Одностишье',
    'crowd': 'Взаимодействие',
    'sketch': 'Скетч',
  };

  static const Map<String, String> statusLabels = {
    'raw': 'Сырая идея',
    'wip': 'На проработке',
    'ready': 'Рабочая',
    'stage': 'В сете',
    'dead': 'Списана',
  };

  @override
  Widget build(BuildContext context) {
    final tags = joke.tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Шутка'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditJokeScreen(joke: joke)),
              );
              if (result == true && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(joke.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(typeLabels[joke.type] ?? joke.type)),
                Chip(
                  label: Text(statusLabels[joke.status] ?? joke.status),
                  backgroundColor: _statusColor(joke.status),
                ),
                Chip(label: Text(joke.time)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Сетап', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(joke.setup, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Text('Панчлайн', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(joke.punchline, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            const Text('Теги', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: tags.map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact)).toList(),
            ),
            if (joke.notes.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Заметки со сцены', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(joke.notes, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  Color? _statusColor(String status) {
    switch (status) {
      case 'ready': return Colors.green[100];
      case 'stage': return Colors.blue[100];
      case 'wip': return Colors.orange[100];
      case 'dead': return Colors.red[100];
      default: return Colors.grey[200];
    }
  }
}
