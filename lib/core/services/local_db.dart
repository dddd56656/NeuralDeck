import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// [LocalDB] 负责本地数据持久化，新增了 lore_cache 表。
class LocalDB {
  LocalDB._internal();
  static final LocalDB instance = LocalDB._internal();

  Database? _database;
  Completer<Database>? _dbCompleter;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (_dbCompleter != null) return _dbCompleter!.future;

    _dbCompleter = Completer<Database>();
    try {
      _database = await _initDatabase();
      _dbCompleter!.complete(_database);
    } catch (e) {
      _dbCompleter!.completeError(e);
      _dbCompleter = null;
      rethrow;
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'neural_deck.db');

    // 注意：如果增加了新表，建议增加 version 版本号
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 升级数据库以添加 lore_cache 表
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE lore_cache (
          tags TEXT PRIMARY KEY,
          content TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 核心卡片表
    batch.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        raw_text TEXT NOT NULL,
        translated_text TEXT,
        ai_rating TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // 赛博背景描述缓存表
    batch.execute('''
      CREATE TABLE lore_cache (
        tags TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 日志审计表
    batch.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await batch.commit();
  }

  // --- 缓存操作 API ---

  /// 获取缓存的赛博描述
  Future<String?> getCachedLore(String tags) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lore_cache',
      where: 'tags = ?',
      whereArgs: [tags],
    );
    if (maps.isNotEmpty) {
      return maps.first['content'] as String;
    }
    return null;
  }

  /// 将生成的描述存入缓存，修复报错：'saveLoreToCache' isn't defined
  Future<void> saveLoreToCache(String tags, String content) async {
    final db = await database;
    await db.insert('lore_cache', {
      'tags': tags,
      'content': content,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- 基础数据操作 ---

  Future<int> insertData(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table, orderBy: "id DESC");
  }
}
