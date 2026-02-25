import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const _dbName = 'zenscreen.db';
  static const _dbVersion = 3;

  /// Returns true when running on web (DB unavailable).
  bool get isStub => kIsWeb;

  Future<Database> get database async {
    if (kIsWeb) {
      throw StateError('SQLite is not available on web');
    }
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
    await _createBlockingTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createFrictionEventsTable(db);
    }
    if (oldVersion < 3) {
      await _createBlockingTables(db);
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

  /// Creates the Phase 5 blocking and strict mode tables.
  Future<void> _createBlockingTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS blocking_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        start_hour INTEGER NOT NULL,
        start_minute INTEGER NOT NULL,
        end_hour INTEGER NOT NULL,
        end_minute INTEGER NOT NULL,
        days_of_week TEXT DEFAULT '1,2,3,4,5,6,7',
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (group_id) REFERENCES app_groups(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_limits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL UNIQUE,
        limit_minutes INTEGER NOT NULL DEFAULT 60,
        current_usage_minutes INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (group_id) REFERENCES app_groups(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS strict_mode_config (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        is_active INTEGER DEFAULT 0,
        start_hour INTEGER DEFAULT 22,
        start_minute INTEGER DEFAULT 0,
        end_hour INTEGER DEFAULT 7,
        end_minute INTEGER DEFAULT 0,
        is_scheduled INTEGER DEFAULT 0,
        scheduled_days TEXT DEFAULT '',
        activated_at TEXT
      )
    ''');
    // Insert default strict mode config row if it doesn't exist.
    await db.insert(
      'strict_mode_config',
      {
        'id': 1,
        'is_active': 0,
        'start_hour': 22,
        'start_minute': 0,
        'end_hour': 7,
        'end_minute': 0,
        'is_scheduled': 0,
        'scheduled_days': '',
        'activated_at': null,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    // Add profile_id column to time_profiles for linking to blocked groups.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profile_blocked_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        group_id INTEGER NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES time_profiles(id) ON DELETE CASCADE,
        FOREIGN KEY (group_id) REFERENCES app_groups(id) ON DELETE CASCADE
      )
    ''');
  }

  // ---------------------------------------------------------------------------
  // App Groups CRUD
  // ---------------------------------------------------------------------------

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

  /// Updates an app group.
  Future<void> updateAppGroup(int id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('app_groups', values, where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes an app group and its associated blocked apps (CASCADE).
  Future<void> deleteAppGroup(int id) async {
    final db = await database;
    await db.delete('app_groups', where: 'id = ?', whereArgs: [id]);
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

  /// Removes a blocked app from a group.
  Future<void> removeBlockedApp(int groupId, String packageName) async {
    final db = await database;
    await db.delete(
      'blocked_apps',
      where: 'group_id = ? AND package_name = ?',
      whereArgs: [groupId, packageName],
    );
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

  /// Retrieves all blocked apps across all groups.
  Future<List<Map<String, dynamic>>> getAllBlockedApps() async {
    final db = await database;
    return db.query('blocked_apps');
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

  // ---------------------------------------------------------------------------
  // Blocking Schedules CRUD
  // ---------------------------------------------------------------------------

  /// Inserts a blocking schedule.
  Future<int> insertBlockingSchedule(Map<String, dynamic> schedule) async {
    final db = await database;
    return db.insert('blocking_schedules', schedule);
  }

  /// Updates a blocking schedule.
  Future<void> updateBlockingSchedule(
      int id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('blocking_schedules', values,
        where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes a blocking schedule.
  Future<void> deleteBlockingSchedule(int id) async {
    final db = await database;
    await db.delete('blocking_schedules', where: 'id = ?', whereArgs: [id]);
  }

  /// Retrieves all blocking schedules.
  Future<List<Map<String, dynamic>>> getBlockingSchedules() async {
    final db = await database;
    return db.query('blocking_schedules');
  }

  /// Retrieves blocking schedules for a specific group.
  Future<List<Map<String, dynamic>>> getSchedulesForGroup(int groupId) async {
    final db = await database;
    return db.query('blocking_schedules',
        where: 'group_id = ?', whereArgs: [groupId]);
  }

  // ---------------------------------------------------------------------------
  // Daily Limits CRUD
  // ---------------------------------------------------------------------------

  /// Inserts or replaces a daily limit for a group.
  Future<int> upsertDailyLimit(Map<String, dynamic> limit) async {
    final db = await database;
    return db.insert('daily_limits', limit,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Retrieves all daily limits.
  Future<List<Map<String, dynamic>>> getDailyLimits() async {
    final db = await database;
    return db.query('daily_limits');
  }

  /// Retrieves the daily limit for a specific group.
  Future<Map<String, dynamic>?> getDailyLimitForGroup(int groupId) async {
    final db = await database;
    final rows = await db.query('daily_limits',
        where: 'group_id = ?', whereArgs: [groupId], limit: 1);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Updates usage minutes for a daily limit.
  Future<void> updateDailyLimitUsage(int groupId, int usageMinutes) async {
    final db = await database;
    await db.update(
      'daily_limits',
      {'current_usage_minutes': usageMinutes},
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }

  /// Resets all daily limit usage counters (called at midnight).
  Future<void> resetAllDailyUsage() async {
    final db = await database;
    await db.update('daily_limits', {'current_usage_minutes': 0});
  }

  /// Deletes a daily limit.
  Future<void> deleteDailyLimit(int groupId) async {
    final db = await database;
    await db.delete('daily_limits',
        where: 'group_id = ?', whereArgs: [groupId]);
  }

  // ---------------------------------------------------------------------------
  // Strict Mode Config CRUD
  // ---------------------------------------------------------------------------

  /// Retrieves the strict mode configuration (singleton row).
  Future<Map<String, dynamic>?> getStrictModeConfig() async {
    final db = await database;
    final rows =
        await db.query('strict_mode_config', where: 'id = ?', whereArgs: [1]);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Updates the strict mode configuration.
  Future<void> updateStrictModeConfig(Map<String, dynamic> config) async {
    final db = await database;
    await db.update('strict_mode_config', config,
        where: 'id = ?', whereArgs: [1]);
  }

  // ---------------------------------------------------------------------------
  // Time Profiles CRUD
  // ---------------------------------------------------------------------------

  /// Inserts a time profile and returns its ID.
  Future<int> insertTimeProfile(Map<String, dynamic> profile) async {
    final db = await database;
    return db.insert('time_profiles', profile);
  }

  /// Updates a time profile.
  Future<void> updateTimeProfile(
      int id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('time_profiles', values,
        where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes a time profile.
  Future<void> deleteTimeProfile(int id) async {
    final db = await database;
    // Also clean up profile_blocked_groups.
    await db.delete('profile_blocked_groups',
        where: 'profile_id = ?', whereArgs: [id]);
    await db.delete('time_profiles', where: 'id = ?', whereArgs: [id]);
  }

  /// Retrieves all time profiles.
  Future<List<Map<String, dynamic>>> getTimeProfiles() async {
    final db = await database;
    return db.query('time_profiles');
  }

  /// Sets the blocked group IDs for a profile.
  Future<void> setProfileBlockedGroups(
      int profileId, List<int> groupIds) async {
    final db = await database;
    await db.delete('profile_blocked_groups',
        where: 'profile_id = ?', whereArgs: [profileId]);
    for (final gid in groupIds) {
      await db.insert('profile_blocked_groups', {
        'profile_id': profileId,
        'group_id': gid,
      });
    }
  }

  /// Retrieves blocked group IDs for a profile.
  Future<List<int>> getProfileBlockedGroups(int profileId) async {
    final db = await database;
    final rows = await db.query('profile_blocked_groups',
        where: 'profile_id = ?', whereArgs: [profileId]);
    return rows.map((r) => r['group_id'] as int).toList();
  }

  // ---------------------------------------------------------------------------
  // Friction Events
  // ---------------------------------------------------------------------------

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
