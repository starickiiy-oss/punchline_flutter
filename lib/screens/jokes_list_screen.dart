import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/joke.dart';
import '../widgets/joke_card.dart';
import 'add_edit_joke_screen.dart';
import 'joke_detail_screen.dart';

class JokesListScreen extends StatefulWidget {
  const JokesListScreen({super.key});

  @override
  State<JokesListScreen> createState() => _JokesListScreenState();
}

class _JokesListScreenState extends State<JokesListScreen> {
  List<Joke> _jokes = [];
  String _search = '';
  String? _statusFilter;
  String? _typeFilter;
  bool _loading = true;

  final Map<String, String> statusLabels = {
    'raw': 'Сырая идея',
    'wip': 'На проработке',
    'ready': 'Рабочая',
    'stage': 'В сете',
    'dead': 'Списана',
  };

  final Map<String, String> typeLabels = {
    'observation': 'Наблюдение',
    'story': 'История',
    'oneline': 'Одностишье',
    'crowd': 'Взаимодействие',
    'sketch': 'Скетч',
  };

  @override
  void initState() {
    super.initState();
    _loadJokes();
  }

  Future<void> _loadJokes() async {
    setState(() => _loading = true);
    final jokes = await DatabaseHelper.instance.searchJokes(_search, _statusFilter, _typeFilter);
    setState(() {
      _jokes = jokes;
      _loading = false;
    });
  }

  Future<void> _deleteJoke(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить шутку?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteJoke(id);
      _loadJokes();
    }
  }

  Future<void> _addToSetlist(Joke joke) async {
    final setlist = await DatabaseHelper.instance.getSetlist();
    if (setlist.any((j) => j.id == joke.id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Уже в сет-листе')));
      return;
    }
    await DatabaseHelper.instance.addToSetlist(joke.id!, setlist.length);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Добавлено в сет-лист')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск по шуткам, тегам...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (v) {
                  _search = v;
                  _loadJokes();
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _statusFilter,
                      hint: const Text('Статус'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Все статусы')),
                        ...statusLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                      ],
                      onChanged: (v) {
                        setState(() => _statusFilter = v);
                        _loadJokes();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _typeFilter,
                      hint: const Text('Тип'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Все типы')),
                        ...typeLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                      ],
                      onChanged: (v) {
                        setState(() => _typeFilter = v);
                        _loadJokes();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _jokes.isEmpty
                  ? const Center(child: Text('Ничего не найдено'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _jokes.length,
                      itemBuilder: (ctx, i) => JokeCard(
                        joke: _jokes[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => JokeDetailScreen(joke: _jokes[i])),
                        ),
                        onEdit: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddEditJokeScreen(joke: _jokes[i])),
                          );
                          if (result == true) _loadJokes();
                        },
                        onDelete: () => _deleteJoke(_jokes[i].id!),
                        onAddToSetlist: () => _addToSetlist(_jokes[i]),
                      ),
                    ),
        ),
      ],
    );
  }
}
