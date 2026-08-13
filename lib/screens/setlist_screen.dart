import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/joke.dart';
import '../widgets/joke_card.dart';
import 'joke_detail_screen.dart';

class SetlistScreen extends StatefulWidget {
  const SetlistScreen({super.key});

  @override
  State<SetlistScreen> createState() => _SetlistScreenState();
}

class _SetlistScreenState extends State<SetlistScreen> {
  List<Joke> _setlist = [];
  List<Joke> _available = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final setlist = await DatabaseHelper.instance.getSetlist();
    final all = await DatabaseHelper.instance.getAllJokes();
    final available = all.where((j) => (j.status == 'ready' || j.status == 'stage') && !setlist.any((s) => s.id == j.id)).toList();
    setState(() {
      _setlist = setlist;
      _available = available;
      _loading = false;
    });
  }

  Future<void> _addToSetlist(Joke joke) async {
    await DatabaseHelper.instance.addToSetlist(joke.id!, _setlist.length);
    _loadData();
  }

  Future<void> _removeFromSetlist(int index) async {
    await DatabaseHelper.instance.removeFromSetlist(_setlist[index].id!);
    _loadData();
  }

  Future<void> _moveItem(int index, int direction) async {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _setlist.length) return;
    final temp = _setlist[index];
    _setlist[index] = _setlist[newIndex];
    _setlist[newIndex] = temp;
    for (int i = 0; i < _setlist.length; i++) {
      await DatabaseHelper.instance.updateSetlistOrder(_setlist[i].id!, i);
    }
    _loadData();
  }

  Future<void> _clearSetlist() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить сет-лист?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Очистить')),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.clearSetlist();
      _loadData();
    }
  }

  int _totalSeconds() {
    int total = 0;
    for (final j in _setlist) {
      final parts = j.time.split(':');
      total += (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final totalSec = _totalSeconds();
    final totalMin = totalSec ~/ 60;
    final totalSecRem = totalSec % 60;

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (_setlist.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Шуток: \${_setlist.length}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('Время: \$totalMin:\${totalSecRem.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              Expanded(
                child: _setlist.isEmpty
                    ? const Center(child: Text('Сет-лист пуст'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _setlist.length,
                        onReorder: (oldIndex, newIndex) async {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _setlist.removeAt(oldIndex);
                          _setlist.insert(newIndex, item);
                          for (int i = 0; i < _setlist.length; i++) {
                            await DatabaseHelper.instance.updateSetlistOrder(_setlist[i].id!, i);
                          }
                          _loadData();
                        },
                        itemBuilder: (ctx, i) => ListTile(
                          key: ValueKey(_setlist[i].id),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            child: Text('\${i + 1}', style: const TextStyle(fontSize: 14)),
                          ),
                          title: Text(_setlist[i].title, overflow: TextOverflow.ellipsis),
                          subtitle: Text('\${_setlist[i].time} · \${_setlist[i].tags.split(',').first}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_upward, size: 18),
                                onPressed: i > 0 ? () => _moveItem(i, -1) : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_downward, size: 18),
                                onPressed: i < _setlist.length - 1 ? () => _moveItem(i, 1) : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                                onPressed: () => _removeFromSetlist(i),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => JokeDetailScreen(joke: _setlist[i])),
                          ),
                        ),
                      ),
              ),
              if (_available.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Доступные для сета', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _available.length,
                    itemBuilder: (ctx, i) => SizedBox(
                      width: 240,
                      child: JokeCard(
                        joke: _available[i],
                        onAddToSetlist: () => _addToSetlist(_available[i]),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => JokeDetailScreen(joke: _available[i])),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (_setlist.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _clearSetlist,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red),
                      child: const Text('Очистить сет-лист'),
                    ),
                  ),
                ),
            ],
          );
  }
}
