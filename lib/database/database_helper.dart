import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/joke.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('punchline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE jokes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        setup TEXT NOT NULL,
        punchline TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        tags TEXT NOT NULL,
        time TEXT NOT NULL,
        notes TEXT NOT NULL,
        inSetlist INTEGER NOT NULL DEFAULT 0,
        setlistOrder INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> insertJoke(Joke joke) async {
    final db = await database;
    return await db.insert('jokes', joke.toMap());
  }

  Future<List<Joke>> getAllJokes() async {
    final db = await database;
    final maps = await db.query('jokes', orderBy: 'id DESC');
    return maps.map((m) => Joke.fromMap(m)).toList();
  }

  Future<List<Joke>> searchJokes(String query, String? status, String? type) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> args = [];

    if (query.isNotEmpty) {
      where += " AND (title LIKE ? OR setup LIKE ? OR punchline LIKE ? OR tags LIKE ?)";
      final q = '%\$query%';
      args.addAll([q, q, q, q]);
    }
    if (status != null && status.isNotEmpty) {
      where += " AND status = ?";
      args.add(status);
    }
    if (type != null && type.isNotEmpty) {
      where += " AND type = ?";
      args.add(type);
    }

    final maps = await db.query('jokes', where: where, whereArgs: args, orderBy: 'id DESC');
    return maps.map((m) => Joke.fromMap(m)).toList();
  }

  Future<int> updateJoke(Joke joke) async {
    final db = await database;
    return await db.update('jokes', joke.toMap(), where: 'id = ?', whereArgs: [joke.id]);
  }

  Future<int> deleteJoke(int id) async {
    final db = await database;
    return await db.delete('jokes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Joke>> getSetlist() async {
    final db = await database;
    final maps = await db.query('jokes', where: 'inSetlist = 1', orderBy: 'setlistOrder ASC');
    return maps.map((m) => Joke.fromMap(m)).toList();
  }

  Future<void> addToSetlist(int id, int order) async {
    final db = await database;
    await db.update('jokes', {'inSetlist': 1, 'setlistOrder': order}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> removeFromSetlist(int id) async {
    final db = await database;
    await db.update('jokes', {'inSetlist': 0, 'setlistOrder': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSetlistOrder(int id, int order) async {
    final db = await database;
    await db.update('jokes', {'setlistOrder': order}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearSetlist() async {
    final db = await database;
    await db.update('jokes', {'inSetlist': 0, 'setlistOrder': 0});
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final total = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM jokes')) ?? 0;
    final ready = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM jokes WHERE status IN ('ready','stage')")) ?? 0;
    final raw = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM jokes WHERE status = 'raw'")) ?? 0;
    final setlistCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM jokes WHERE inSetlist = 1')) ?? 0;

    final statusCounts = await db.rawQuery(
      'SELECT status, COUNT(*) as cnt FROM jokes GROUP BY status'
    );

    final typeCounts = await db.rawQuery(
      'SELECT type, COUNT(*) as cnt FROM jokes GROUP BY type'
    );

    return {
      'total': total,
      'ready': ready,
      'raw': raw,
      'setlist': setlistCount,
      'statusCounts': statusCounts,
      'typeCounts': typeCounts,
    };
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
