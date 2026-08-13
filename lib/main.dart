import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

void main() => runApp(const PunchlineApp());

class PunchlineApp extends StatelessWidget {
  const PunchlineApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Панчлайн',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.black),
      home: const HomeScreen(),
    );
  }
}

class Joke {
  final int? id;
  final String title;
  final String setup;
  final String punchline;
  final String type;
  final String status;
  final String tags;
  final String time;
  final String notes;
  final int inSetlist;
  final int setlistOrder;
  Joke({this.id, required this.title, required this.setup, required this.punchline, required this.type, required this.status, required this.tags, required this.time, required this.notes, this.inSetlist = 0, this.setlistOrder = 0});
  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'setup': setup, 'punchline': punchline, 'type': type, 'status': status, 'tags': tags, 'time': time, 'notes': notes, 'inSetlist': inSetlist, 'setlistOrder': setlistOrder};
  factory Joke.fromMap(Map<String, dynamic> m) => Joke(id: m['id'], title: m['title'], setup: m['setup'], punchline: m['punchline'], type: m['type'], status: m['status'], tags: m['tags'], time: m['time'], notes: m['notes'], inSetlist: m['inSetlist'] ?? 0, setlistOrder: m['setlistOrder'] ?? 0);
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _db;
  DatabaseHelper._init();
  Future<Database> get database async { _db ??= await _initDB('punchline.db'); return _db!; }
  Future<Database> _initDB(String f) async { final p = await getDatabasesPath(); return await openDatabase(join(p, f), version: 1, onCreate: _create); }
  Future _create(Database db, int v) async => await db.execute('CREATE TABLE jokes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, setup TEXT, punchline TEXT, type TEXT, status TEXT, tags TEXT, time TEXT, notes TEXT, inSetlist INTEGER DEFAULT 0, setlistOrder INTEGER DEFAULT 0)');
  Future<int> insert(Joke j) async { final db = await database; return await db.insert('jokes', j.toMap()); }
  Future<List<Joke>> getAll() async { final db = await database; final m = await db.query('jokes', orderBy: 'id DESC'); return m.map((x) => Joke.fromMap(x)).toList(); }
  Future<List<Joke>> search(String q, String? st, String? tp) async { final db = await database; String w = '1=1'; List<dynamic> a = []; if (q.isNotEmpty) { w += ' AND (title LIKE ? OR setup LIKE ? OR punchline LIKE ? OR tags LIKE ?)'; final x = '%$q%'; a.addAll([x,x,x,x]); } if (st != null) { w += ' AND status = ?'; a.add(st); } if (tp != null) { w += ' AND type = ?'; a.add(tp); } final m = await db.query('jokes', where: w, whereArgs: a, orderBy: 'id DESC'); return m.map((x) => Joke.fromMap(x)).toList(); }
  Future<int> update(Joke j) async { final db = await database; return await db.update('jokes', j.toMap(), where: 'id = ?', whereArgs: [j.id]); }
  Future<int> delete(int id) async { final db = await database; return await db.delete('jokes', where: 'id = ?', whereArgs: [id]); }
  Future<List<Joke>> getSetlist() async { final db = await database; final m = await db.query('jokes', where: 'inSetlist = 1', orderBy: 'setlistOrder ASC'); return m.map((x) => Joke.fromMap(x)).toList(); }
  Future<void> addToSetlist(int id, int order) async { final db = await database; await db.update('jokes', {'inSetlist': 1, 'setlistOrder': order}, where: 'id = ?', whereArgs: [id]); }
  Future<void> removeFromSetlist(int id) async { final db = await database; await db.update('jokes', {'inSetlist': 0, 'setlistOrder': 0}, where: 'id = ?', whereArgs: [id]); }
  Future<void> clearSetlist() async { final db = await database; await db.update('jokes', {'inSetlist': 0, 'setlistOrder': 0}); }
  Future<Map<String, dynamic>> stats() async { final db = await database; final t = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM jokes')) ?? 0; final r = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM jokes WHERE status IN('ready','stage')")) ?? 0; final rw = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM jokes WHERE status='raw'")) ?? 0; final s = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM jokes WHERE inSetlist=1')) ?? 0; final sc = await db.rawQuery('SELECT status, COUNT(*) as c FROM jokes GROUP BY status'); return {'total': t, 'ready': r, 'raw': rw, 'setlist': s, 'statusCounts': sc}; }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int idx = 0;
  final screens = [const JokesScreen(), const SetlistScreen(), const StatsScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: screens[idx], bottomNavigationBar: NavigationBar(selectedIndex: idx, onDestinationSelected: (i) => setState(() => idx = i), destinations: const [NavigationDestination(icon: Icon(Icons.list), label: 'Шутки'), NavigationDestination(icon: Icon(Icons.playlist_play), label: 'Сет-лист'), NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Статистика')]), floatingActionButton: idx == 0 ? FloatingActionButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditScreen())).then((_) => setState(() {})), child: const Icon(Icons.add)) : null);
  }
}

class JokesScreen extends StatefulWidget {
  const JokesScreen({super.key});
  @override
  State<JokesScreen> createState() => _JokesScreenState();
}

class _JokesScreenState extends State<JokesScreen> {
  List<Joke> jokes = [];
  String search = '';
  String? statusFilter;
  String? typeFilter;
  final stMap = {'raw': 'Сырая', 'wip': 'Проработка', 'ready': 'Рабочая', 'stage': 'В сете', 'dead': 'Списана'};
  final tpMap = {'observation': 'Наблюдение', 'story': 'История', 'oneline': 'Одностишье', 'crowd': 'Взаимодействие', 'sketch': 'Скетч'};
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final j = await DatabaseHelper.instance.search(search, statusFilter, typeFilter); setState(() => jokes = j); }
  Future<void> _delete(Joke j) async { await DatabaseHelper.instance.delete(j.id!); _load(); }
  Future<void> _addSet(Joke j) async { final s = await DatabaseHelper.instance.getSetlist(); if (!s.any((x) => x.id == j.id)) await DatabaseHelper.instance.addToSetlist(j.id!, s.length); }
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        SearchBar(hintText: 'Поиск...', onChanged: (v) { search = v; _load(); }),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: statusFilter, hint: const Text('Статус'), items: [null, ...stMap.keys].map((k) => DropdownMenuItem(value: k, child: Text(k == null ? 'Все' : stMap[k]!))).toList(), onChanged: (v) { setState(() => statusFilter = v); _load(); })),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField<String>(value: typeFilter, hint: const Text('Тип'), items: [null, ...tpMap.keys].map((k) => DropdownMenuItem(value: k, child: Text(k == null ? 'Все' : tpMap[k]!))).toList(), onChanged: (v) { setState(() => typeFilter = v); _load(); })),
        ]),
      ])),
      Expanded(child: jokes.isEmpty ? const Center(child: Text('Ничего не найдено')) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: jokes.length, itemBuilder: (c, i) {
        final j = jokes[i]; final tags = j.tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
        return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(j.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))), IconButton(icon: const Icon(Icons.playlist_add), onPressed: () => _addSet(j)), IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditScreen(joke: j))).then((_) => _load())), IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(j))]),
          const SizedBox(height: 6), Text(j.setup, style: TextStyle(fontSize: 14, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4), Text(j.punchline, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10), Wrap(spacing: 6, children: [...tags.map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact)), Chip(label: Text(stMap[j.status] ?? j.status)), Chip(label: Text(j.time))]),
        ])));
      })),
    ]);
  }
}

class AddEditScreen extends StatefulWidget {
  final Joke? joke;
  const AddEditScreen({super.key, this.joke});
  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _title = TextEditingController(), _setup = TextEditingController(), _punchline = TextEditingController(), _tags = TextEditingController(), _time = TextEditingController(text: '1:00'), _notes = TextEditingController();
  String _type = 'observation', _status = 'raw';
  final tpMap = {'observation': 'Наблюдение', 'story': 'История', 'oneline': 'Одностишье', 'crowd': 'Взаимодействие', 'sketch': 'Скетч'};
  final stMap = {'raw': 'Сырая идея', 'wip': 'На проработке', 'ready': 'Рабочая', 'stage': 'В сете', 'dead': 'Списана'};
  @override
  void initState() { super.initState(); if (widget.joke != null) { final j = widget.joke!; _title.text = j.title; _setup.text = j.setup; _punchline.text = j.punchline; _tags.text = j.tags; _time.text = j.time; _notes.text = j.notes; _type = j.type; _status = j.status; } }
  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _setup.text.trim().isEmpty || _punchline.text.trim().isEmpty) return;
    final j = Joke(id: widget.joke?.id, title: _title.text.trim(), setup: _setup.text.trim(), punchline: _punchline.text.trim(), type: _type, status: _status, tags: _tags.text.trim(), time: _time.text.trim(), notes: _notes.text.trim(), inSetlist: widget.joke?.inSetlist ?? 0, setlistOrder: widget.joke?.setlistOrder ?? 0);
    if (widget.joke == null) await DatabaseHelper.instance.insert(j); else await DatabaseHelper.instance.update(j);
    if (mounted) Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(widget.joke == null ? 'Новая шутка' : 'Редактировать')), body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _title, decoration: const InputDecoration(labelText: 'Заголовок')),
      const SizedBox(height: 16), Row(children: [Expanded(child: DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(labelText: 'Тип'), items: tpMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (v) => setState(() => _type = v!))), const SizedBox(width: 16), Expanded(child: DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'Статус'), items: stMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (v) => setState(() => _status = v!)))]),
      const SizedBox(height: 16), TextField(controller: _setup, decoration: const InputDecoration(labelText: 'Сетап'), maxLines: 3), const SizedBox(height: 16), TextField(controller: _punchline, decoration: const InputDecoration(labelText: 'Панчлайн'), maxLines: 3),
      const SizedBox(height: 16), Row(children: [Expanded(flex: 2, child: TextField(controller: _tags, decoration: const InputDecoration(labelText: 'Теги'))), const SizedBox(width: 16), Expanded(child: TextField(controller: _time, decoration: const InputDecoration(labelText: 'Время')))]),
      const SizedBox(height: 16), TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Заметки'), maxLines: 3),
      const SizedBox(height: 24), SizedBox(width: double.infinity, child: FilledButton(onPressed: _save, child: const Text('СОХРАНИТЬ'))),
    ])));
  }
}

class SetlistScreen extends StatefulWidget {
  const SetlistScreen({super.key});
  @override
  State<SetlistScreen> createState() => _SetlistScreenState();
}

class _SetlistScreenState extends State<SetlistScreen> {
  List<Joke> setlist = [];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final s = await DatabaseHelper.instance.getSetlist(); setState(() => setlist = s); }
  Future<void> _remove(int id) async { await DatabaseHelper.instance.removeFromSetlist(id); _load(); }
  Future<void> _clear() async { await DatabaseHelper.instance.clearSetlist(); _load(); }
  int _sec() { int t = 0; for (final j in setlist) { final p = j.time.split(':'); t += (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0); } return t; }
  @override
  Widget build(BuildContext context) {
    final sec = _sec();
    return Column(children: [
      if (setlist.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Шуток: ${setlist.length}'), Text('Время: ${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}')])), Expanded(child: setlist.isEmpty ? const Center(child: Text('Сет-лист пуст')) : ReorderableListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: setlist.length, onReorder: (o, n) async { if (n > o) n--; final item = setlist.removeAt(o); setlist.insert(n, item); for (int i = 0; i < setlist.length; i++) { /* order update */ } setState(() {}); }, itemBuilder: (c, i) => ListTile(key: ValueKey(setlist[i].id), leading: CircleAvatar(child: Text('${i + 1}')), title: Text(setlist[i].title), subtitle: Text('${setlist[i].time} · ${setlist[i].tags.split(',').first}'), trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _remove(setlist[i].id!))))),
      if (setlist.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: OutlinedButton(onPressed: _clear, child: const Text('Очистить'))), const SizedBox(width: 12), Expanded(child: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerformanceScreen())), child: const Text('РЕЖИМ ВЫСТУПЛЕНИЯ')))])),
    ]);
  }
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? stats;
  final stMap = {'raw': 'Сырая', 'wip': 'Проработка', 'ready': 'Рабочая', 'stage': 'В сете', 'dead': 'Списана'};
  final stColor = {'raw': Colors.grey, 'wip': Colors.orange, 'ready': Colors.green, 'stage': Colors.blue, 'dead': Colors.red};
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final s = await DatabaseHelper.instance.stats(); setState(() => stats = s); }
  @override
  Widget build(BuildContext context) {
    if (stats == null) return const Center(child: CircularProgressIndicator());
    final t = stats!['total'] as int; final r = stats!['ready'] as int; final rw = stats!['raw'] as int; final sl = stats!['setlist'] as int; final sc = stats!['statusCounts'] as List<dynamic>;
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 1.4, mainAxisSpacing: 12, crossAxisSpacing: 12, children: [_card(t.toString(), 'Всего'), _card(r.toString(), 'Готовых'), _card(rw.toString(), 'Сырых'), _card(sl.toString(), 'В сете')]),
      const SizedBox(height: 24), const Text('По статусам', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)), const SizedBox(height: 12),
      ...sc.map((s) { final st = s['status'] as String; final c = s['c'] as int; final mx = t == 0 ? 1 : t; return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [SizedBox(width: 100, child: Text(stMap[st] ?? st, style: const TextStyle(fontSize: 13))), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: c / mx, minHeight: 18, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation(stColor[st] ?? Colors.grey)))), const SizedBox(width: 8), SizedBox(width: 30, child: Text('$c', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))])); }).toList(),
    ]));
  }
  Widget _card(String v, String l) => Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(16), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(v, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text(l, style: TextStyle(fontSize: 12, color: Colors.grey[600]))]));
}

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});
  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  List<Joke> setlist = [];
  int idx = 0;
  bool show = false;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final s = await DatabaseHelper.instance.getSetlist(); setState(() => setlist = s); }
  @override
  Widget build(BuildContext context) {
    if (setlist.isEmpty) return const Scaffold(body: Center(child: Text('Сет-лист пуст')));
    final j = setlist[idx];
    return Scaffold(backgroundColor: Colors.black, body: SafeArea(child: GestureDetector(onTap: () => setState(() => show = !show), onHorizontalDragEnd: (d) { if (d.primaryVelocity == null) return; if (d.primaryVelocity! < -200 && idx < setlist.length - 1) setState(() { idx++; show = false; }); else if (d.primaryVelocity! > 200 && idx > 0) setState(() { idx--; show = false; }); }, child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${idx + 1} / ${setlist.length}', style: TextStyle(color: Colors.grey[500], fontSize: 14)), Text(j.time, style: TextStyle(color: Colors.grey[500], fontSize: 14))]),
      const SizedBox(height: 40), Text(j.title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w500)), const SizedBox(height: 32),
      if (show) ...[Text(j.setup, style: TextStyle(color: Colors.grey[300], fontSize: 20, height: 1.4)), const SizedBox(height: 24), Text(j.punchline, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500, height: 1.4))] else ...[const Spacer(), Center(child: Text('Нажмите, чтобы показать текст', style: TextStyle(color: Colors.grey[600], fontSize: 16))), const Spacer()],
      const SizedBox(height: 40), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [if (idx > 0) TextButton.icon(onPressed: () => setState(() { idx--; show = false; }), icon: const Icon(Icons.arrow_back, color: Colors.white), label: const Text('Назад', style: TextStyle(color: Colors.white))) else const SizedBox(), if (idx < setlist.length - 1) TextButton.icon(onPressed: () => setState(() { idx++; show = false; }), icon: const Icon(Icons.arrow_forward, color: Colors.white), label: const Text('Вперёд', style: TextStyle(color: Colors.white))) else const SizedBox()]),
    ])))));
  }
}
