import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const _dbName = 'zenscreen.db';
  static const _dbVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE daily_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        total_screen_time INTEGER DEFAULT 0,
        app_open_count INTEGER DEFAULT 0,
        friction_shown INTEGER DEFAULT 0,
        friction_dismissed INTEGER DEFAULT 0,
        friction_bypassed INTEGER DEFAULT 0,
        health_score INTEGER DEFAULT 100
      )
    ''');
    await db.execute('''
      CREATE TABLE intention_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        app_package TEXT NOT NULL,
        intention_type INTEGER NOT NULL,
        did_proceed INTEGER DEFAULT 0,
        session_duration INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE app_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT DEFAULT 'apps',
        friction_type INTEGER DEFAULT 0,
        daily_limit_minutes INTEGER DEFAULT 60,
        is_strict_mode INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE blocked_apps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        package_name TEXT NOT NULL,
        app_name TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES app_groups(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE time_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_hour INTEGER NOT NULL,
        start_minute INTEGER NOT NULL,
        end_hour INTEGER NOT NULL,
        end_minute INTEGER NOT NULL,
        active_days TEXT DEFAULT '1,2,3,4,5,6,7',
        is_strict_mode INTEGER DEFAULT 0
      )
    ''');
  }

  /// Insert a new app group and return its ID.
  Future<int> insertAppGroup({
    required String name,
    String icon = 'apps',
    int frictionType = 0,
    int dailyLimitMinutes = 60,
    bool isStrictMode = false,
  }) async {
    final db = await database;
    return db.insert('app_groups', {
      'name': name,
      'icon': icon,
      'friction_type': frictionType,
      'daily_limit_minutes': dailyLimitMinutes,
      'is_strict_mode': isStrictMode ? 1 : 0,
    });
  }

  /// Insert a blocked app into a group.
  Future<int> insertBlockedApp({
    required int groupId,
    required String packageName,
    required String appName,
  }) async {
    final db = await database;
    return db.insert('blocked_apps', {
      'group_id': groupId,
      'package_name': packageName,
      'app_name': appName,
    });
  }
}
