import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int id;
  String title, setup, punchline, type, status, tags, time, notes;
  int inSetlist, setlistOrder;
  Joke({this.id = 0, required this.title, required this.setup, required this.punchline, this.type = 'observation', this.status = 'raw', this.tags = '', this.time = '1:00', this.notes = '', this.inSetlist = 0, this.setlistOrder = 0});
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'setup': setup, 'punchline': punchline, 'type': type, 'status': status, 'tags': tags, 'time': time, 'notes': notes, 'inSetlist': inSetlist, 'setlistOrder': setlistOrder};
  factory Joke.fromJson(Map<String, dynamic> j) => Joke(id: j['id'], title: j['title'], setup: j['setup'], punchline: j['punchline'], type: j['type'], status: j['status'], tags: j['tags'], time: j['time'], notes: j['notes'], inSetlist: j['inSetlist'] ?? 0, setlistOrder: j['setlistOrder'] ?? 0);
}

class Storage {
  static const _key = 'jokes';
  static Future<List<Joke>> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s == null) return [];
    final list = jsonDecode(s) as List;
    return list.map((j) => Joke.fromJson(j)).toList();
  }
  static Future<void> save(List<Joke> jokes) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(jokes.map((j) => j.toJson()).toList()));
  }
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
  Future<void> _load() async { final all = await Storage.load(); setState(() { jokes = all.where((j) {
    final q = search.toLowerCase();
    final matchSearch = search.isEmpty || j.title.toLowerCase().contains(q) || j.setup.toLowerCase().contains(q) || j.punchline.toLowerCase().contains(q) || j.tags.toLowerCase().contains(q);
    final matchStatus = statusFilter == null || j.status == statusFilter;
    final matchType = typeFilter == null || j.type == typeFilter;
    return matchSearch && matchStatus && matchType;
  }).toList(); }); }
  Future<void> _delete(Joke j) async { final all = await Storage.load(); all.removeWhere((x) => x.id == j.id); await Storage.save(all); _load(); }
  Future<void> _addSet(Joke j) async { final all = await Storage.load(); if (!all.any((x) => x.id == j.id && x.inSetlist == 1)) { final idx = all.indexWhere((x) => x.id == j.id); if (idx != -1) { all[idx].inSetlist = 1; all[idx].setlistOrder = all.where((x) => x.inSetlist == 1).length - 1; await Storage.save(all); } } }
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
    final all = await Storage.load();
    final j = Joke(id: widget.joke?.id ?? DateTime.now().millisecondsSinceEpoch, title: _title.text.trim(), setup: _setup.text.trim(), punchline: _punchline.text.trim(), type: _type, status: _status, tags: _tags.text.trim(), time: _time.text.trim(), notes: _notes.text.trim(), inSetlist: widget.joke?.inSetlist ?? 0, setlistOrder: widget.joke?.setlistOrder ?? 0);
    if (widget.joke == null) { all.add(j); } else { final idx = all.indexWhere((x) => x.id == j.id); if (idx != -1) all[idx] = j; }
    await Storage.save(all);
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
  Future<void> _load() async { final all = await Storage.load(); setState(() => setlist = all.where((j) => j.inSetlist == 1).toList()..sort((a, b) => a.setlistOrder.compareTo(b.setlistOrder))); }
  Future<void> _remove(int id) async { final all = await Storage.load(); final idx = all.indexWhere((x) => x.id == id); if (idx != -1) { all[idx].inSetlist = 0; all[idx].setlistOrder = 0; } await Storage.save(all); _load(); }
  Future<void> _clear() async { final all = await Storage.load(); for (final j in all) { j.inSetlist = 0; j.setlistOrder = 0; } await Storage.save(all); _load(); }
  int _sec() { int t = 0; for (final j in setlist) { final p = j.time.split(':'); t += (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0); } return t; }
  @override
  Widget build(BuildContext context) {
    final sec = _sec();
    return Column(children: [
      if (setlist.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Шуток: ${setlist.length}'), Text('Время: ${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}')])), Expanded(child: setlist.isEmpty ? const Center(child: Text('Сет-лист пуст')) : ReorderableListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: setlist.length, onReorder: (o, n) async { if (n > o) n--; final item = setlist.removeAt(o); setlist.insert(n, item); final all = await Storage.load(); for (int i = 0; i < setlist.length; i++) { final idx = all.indexWhere((x) => x.id == setlist[i].id); if (idx != -1) all[idx].setlistOrder = i; } await Storage.save(all); setState(() {}); }, itemBuilder: (c, i) => ListTile(key: ValueKey(setlist[i].id), leading: CircleAvatar(child: Text('${i + 1}')), title: Text(setlist[i].title), subtitle: Text('${setlist[i].time} · ${setlist[i].tags.split(',').first}'), trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _remove(setlist[i].id))))),
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
  Future<void> _load() async { final all = await Storage.load(); final t = all.length; final r = all.where((j) => j.status == 'ready' || j.status == 'stage').length; final rw = all.where((j) => j.status == 'raw').length; final sl = all.where((j) => j.inSetlist == 1).length; final sc = <String, int>{}; for (final j in all) { sc[j.status] = (sc[j.status] ?? 0) + 1; } setState(() => stats = {'total': t, 'ready': r, 'raw': rw, 'setlist': sl, 'statusCounts': sc}); }
  @override
  Widget build(BuildContext context) {
    if (stats == null) return const Center(child: CircularProgressIndicator());
    final t = stats!['total'] as int; final r = stats!['ready'] as int; final rw = stats!['raw'] as int; final sl = stats!['setlist'] as int; final sc = stats!['statusCounts'] as Map<String, int>;
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 1.4, mainAxisSpacing: 12, crossAxisSpacing: 12, children: [_card(t.toString(), 'Всего'), _card(r.toString(), 'Готовых'), _card(rw.toString(), 'Сырых'), _card(sl.toString(), 'В сете')]),
      const SizedBox(height: 24), const Text('По статусам', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)), const SizedBox(height: 12),
      ...sc.entries.map((e) { final mx = t == 0 ? 1 : t; return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [SizedBox(width: 100, child: Text(stMap[e.key] ?? e.key, style: const TextStyle(fontSize: 13))), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: e.value / mx, minHeight: 18, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation(stColor[e.key] ?? Colors.grey)))), const SizedBox(width: 8), SizedBox(width: 30, child: Text('${e.value}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))])); }).toList(),
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
  Future<void> _load() async { final all = await Storage.load(); setState(() => setlist = all.where((j) => j.inSetlist == 1).toList()..sort((a, b) => a.setlistOrder.compareTo(b.setlistOrder))); }
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
