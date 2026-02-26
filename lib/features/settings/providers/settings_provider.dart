import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/database/preferences_service.dart';
import '../../../core/providers/providers.dart';

/// Settings state for the app's general preferences (STNG-01, STNG-05).
class AppSettings {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final int dailyGoalMinutes;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.notificationsEnabled = true,
    this.dailyGoalMinutes = 120,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    int? dailyGoalMinutes,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
    );
  }
}

/// Manages app settings: theme, notifications, daily goal, data export/reset.
class SettingsNotifier extends StateNotifier<AppSettings> {
  final PreferencesService _prefs;
  final DatabaseHelper _db;

  SettingsNotifier({
    required PreferencesService prefs,
    required DatabaseHelper db,
  })  : _prefs = prefs,
        _db = db,
        super(AppSettings(
          themeMode: prefs.themeMode,
          notificationsEnabled: prefs.notificationsEnabled,
          dailyGoalMinutes: prefs.dailyGoalMinutes,
        ));

  /// Toggles between dark and light theme (STNG-01).
  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  /// Toggles notification preferences (STNG-01).
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setNotificationsEnabled(enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  /// Updates the daily screen time goal.
  Future<void> setDailyGoalMinutes(int minutes) async {
    await _prefs.setDailyGoalMinutes(minutes);
    state = state.copyWith(dailyGoalMinutes: minutes);
  }

  /// Exports all data as CSV and returns the file path (STNG-05).
  Future<String> exportDataAsCsv() async {
    if (_db.isStub) {
      throw StateError('Export is not available on web');
    }

    final db = await _db.database;

    // Query all tables.
    final dailyStats = await db.query('daily_stats', orderBy: 'date ASC');
    final intentionLogs =
        await db.query('intention_logs', orderBy: 'timestamp ASC');
    final frictionEvents =
        await db.query('friction_events', orderBy: 'timestamp ASC');

    final buffer = StringBuffer();

    // Daily Stats section.
    buffer.writeln('=== Daily Stats ===');
    if (dailyStats.isNotEmpty) {
      final headers = dailyStats.first.keys.toList();
      final rows = dailyStats.map((r) => r.values.toList()).toList();
      buffer.write(const ListToCsvConverter().convert([headers, ...rows]));
    }
    buffer.writeln('\n');

    // Intention Logs section.
    buffer.writeln('=== Intention Logs ===');
    if (intentionLogs.isNotEmpty) {
      final headers = intentionLogs.first.keys.toList();
      final rows = intentionLogs.map((r) => r.values.toList()).toList();
      buffer.write(const ListToCsvConverter().convert([headers, ...rows]));
    }
    buffer.writeln('\n');

    // Friction Events section.
    buffer.writeln('=== Friction Events ===');
    if (frictionEvents.isNotEmpty) {
      final headers = frictionEvents.first.keys.toList();
      final rows = frictionEvents.map((r) => r.values.toList()).toList();
      buffer.write(const ListToCsvConverter().convert([headers, ...rows]));
    }

    // Write to file.
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filePath = '${directory.path}/zenscreen_export_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    return filePath;
  }

  /// Resets all data except premium status (STNG-05).
  Future<void> resetAllData() async {
    if (!_db.isStub) {
      final db = await _db.database;

      // Clear all tables.
      await db.delete('daily_stats');
      await db.delete('intention_logs');
      await db.delete('friction_events');
      await db.delete('blocked_apps');
      await db.delete('blocking_schedules');
      await db.delete('daily_limits');
      await db.delete('profile_blocked_groups');
    }

    // Reset preferences but keep premium status and onboarding.
    await _prefs.setDailyGoalMinutes(120);
    state = state.copyWith(dailyGoalMinutes: 120);
  }
}

/// Global provider for app settings.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(
    prefs: ref.watch(preferencesServiceProvider),
    db: ref.watch(databaseProvider),
  );
});
