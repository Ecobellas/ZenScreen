import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const _dbName = 'zenscreen.db';
  static const _dbVersion = 2;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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
    await _createFrictionEventsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createFrictionEventsTable(db);
    }
  }

  Future<void> _createFrictionEventsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS friction_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        app_package TEXT NOT NULL,
        app_name TEXT NOT NULL DEFAULT '',
        friction_type INTEGER NOT NULL DEFAULT 0,
        user_action INTEGER NOT NULL DEFAULT 0,
        intention_type INTEGER,
        duration_seconds INTEGER DEFAULT 0
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

  /// Retrieves all app groups.
  Future<List<Map<String, dynamic>>> getAppGroups() async {
    final db = await database;
    return db.query('app_groups');
  }

  /// Retrieves all blocked apps in a given group.
  Future<List<Map<String, dynamic>>> getBlockedApps(int groupId) async {
    final db = await database;
    return db.query(
      'blocked_apps',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }

  /// Updates the friction type for an app group.
  Future<void> updateGroupFrictionType(int groupId, int frictionType) async {
    final db = await database;
    await db.update(
      'app_groups',
      {'friction_type': frictionType},
      where: 'id = ?',
      whereArgs: [groupId],
    );
  }

  /// Inserts a friction event log.
  Future<int> insertFrictionEvent(Map<String, dynamic> event) async {
    final db = await database;
    return db.insert('friction_events', event);
  }

  /// Retrieves friction events for a given date range.
  Future<List<Map<String, dynamic>>> getFrictionEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await database;
    return db.query(
      'friction_events',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
  }
}
