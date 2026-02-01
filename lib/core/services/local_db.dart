import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// [LocalDB] 负责本地 SQLite 数据的持久化。
/// 采用单例模式，确保全局只有一个数据库连接。
class LocalDB {
  // 1. 私有构造函数与单例实现
  LocalDB._internal();
  static final LocalDB instance = LocalDB._internal();

  // 2. 数据库实例，使用 getter 确保安全访问
  Database? _database;

  // 锁机制：防止多个线程同时初始化数据库
  bool _isInitializing = false;

  /// 获取数据库实例的异步 Getter
  /// 遵循 Google 风格：将初始化逻辑封装在访问器内，调用者无需手动调用 init()
  Future<Database> get database async {
    if (_database != null) return _database!;

    // 简单的并发保护
    if (_isInitializing) {
      while (_database == null) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _database!;
    }

    _isInitializing = true;
    _database = await _initDatabase();
    _isInitializing = false;
    return _database!;
  }

  /// 私有初始化逻辑
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'neural_deck.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  /// 数据库表创建逻辑 (独立提取，提高可读性)
  Future<void> _onCreate(Database db, int version) async {
    // 使用 Batch 操作提升多表创建性能
    final batch = db.batch();

    // 卡片表：存储 AI 学习数据
    batch.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        raw_text TEXT NOT NULL,
        translated_text TEXT,
        ai_rating TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // 日志表：系统行为审计
    batch.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await batch.commit();
  }

  // --- 数据操作 API ---

  /// 插入数据
  Future<int> insertData(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace, // 冲突处理策略
    );
  }

  /// 查询所有数据
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table, orderBy: "id DESC");
  }
}
