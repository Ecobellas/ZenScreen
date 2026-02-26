import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/models/daily_stats.dart';
import '../../../core/providers/providers.dart';

/// A single data point for screen time charts.
class ScreenTimeEntry {
  final DateTime date;
  final Duration duration;
  const ScreenTimeEntry({required this.date, required this.duration});
}

/// Per-app usage data.
class AppUsageEntry {
  final String appPackage;
  final String appName;
  final Duration duration;
  final int openCount;
  const AppUsageEntry({
    required this.appPackage,
    required this.appName,
    required this.duration,
    required this.openCount,
  });
}

/// Weekly comparison data.
class WeeklyComparison {
  final Duration thisWeekTotal;
  final Duration lastWeekTotal;
  final double percentChange;
  const WeeklyComparison({
    required this.thisWeekTotal,
    required this.lastWeekTotal,
    required this.percentChange,
  });
}

/// Provides aggregated statistics data for charts and displays.
class StatisticsNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseHelper _db;

  StatisticsNotifier({required DatabaseHelper db})
      : _db = db,
        super(const AsyncValue.data(null));

  /// Gets screen time for a specific date.
  Future<Duration> getDailyScreenTime(DateTime date) async {
    final stats = await _getStatsForDate(date);
    if (stats == null) return Duration.zero;
    return Duration(minutes: stats.totalScreenTimeMinutes);
  }

  /// Gets daily screen time for the last 7 days.
  Future<List<ScreenTimeEntry>> getWeeklyScreenTime() async {
    return _getScreenTimeRange(7);
  }

  /// Gets daily screen time for the last 30 days.
  Future<List<ScreenTimeEntry>> getMonthlyScreenTime() async {
    return _getScreenTimeRange(30);
  }

  /// Gets per-app usage breakdown for a date, sorted by usage.
  Future<List<AppUsageEntry>> getPerAppBreakdown(DateTime date) async {
    if (_db.isStub) return [];
    final db = await _db.database;
    final dateStr = date.toIso8601String().substring(0, 10);

    // Get friction events for this date to aggregate per-app data.
    final rows = await db.rawQuery('''
      SELECT app_package, app_name,
             COUNT(*) as open_count,
             SUM(duration_seconds) as total_seconds
      FROM friction_events
      WHERE timestamp LIKE ?
      GROUP BY app_package
      ORDER BY total_seconds DESC
    ''', ['$dateStr%']);

    return rows.map((r) {
      final pkg = r['app_package'] as String;
      final name = r['app_name'] as String? ?? pkg;
      return AppUsageEntry(
        appPackage: pkg,
        appName: name.isNotEmpty ? name : _friendlyName(pkg),
        duration: Duration(seconds: r['total_seconds'] as int? ?? 0),
        openCount: r['open_count'] as int? ?? 0,
      );
    }).toList();
  }

  /// Compares this week's total vs last week's total.
  Future<WeeklyComparison> getWeeklyComparison() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int thisWeek = 0;
    int lastWeek = 0;

    for (int i = 0; i < 7; i++) {
      final thisDate = today.subtract(Duration(days: i));
      final lastDate = today.subtract(Duration(days: i + 7));

      final thisStats = await _getStatsForDate(thisDate);
      final lastStats = await _getStatsForDate(lastDate);

      thisWeek += thisStats?.totalScreenTimeMinutes ?? 0;
      lastWeek += lastStats?.totalScreenTimeMinutes ?? 0;
    }

    double percentChange = 0;
    if (lastWeek > 0) {
      percentChange = ((thisWeek - lastWeek) / lastWeek) * 100;
    }

    return WeeklyComparison(
      thisWeekTotal: Duration(minutes: thisWeek),
      lastWeekTotal: Duration(minutes: lastWeek),
      percentChange: percentChange,
    );
  }

  /// Gets top N apps for a date.
  Future<List<AppUsageEntry>> getTopApps(int count, DateTime date) async {
    final all = await getPerAppBreakdown(date);
    return all.take(count).toList();
  }

  /// Gets daily stats for a specific date.
  Future<DailyStats?> getStatsForDate(DateTime date) async {
    return _getStatsForDate(date);
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<List<ScreenTimeEntry>> _getScreenTimeRange(int days) async {
    final entries = <ScreenTimeEntry>[];
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final stats = await _getStatsForDate(date);
      entries.add(ScreenTimeEntry(
        date: date,
        duration: Duration(minutes: stats?.totalScreenTimeMinutes ?? 0),
      ));
    }
    return entries;
  }

  Future<DailyStats?> _getStatsForDate(DateTime date) async {
    if (_db.isStub) return null;
    final db = await _db.database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await db.query(
      'daily_stats',
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DailyStats.fromMap(rows.first);
  }

  String _friendlyName(String packageName) {
    final parts = packageName.split('.');
    if (parts.length > 1) {
      final name = parts.last;
      return name[0].toUpperCase() + name.substring(1);
    }
    return packageName;
  }
}

/// Global provider for statistics data.
final statisticsProvider =
    StateNotifierProvider<StatisticsNotifier, AsyncValue<void>>((ref) {
  return StatisticsNotifier(db: ref.watch(databaseProvider));
});

/// Provider for today's DailyStats.
final todayStatsProvider = FutureProvider<DailyStats?>((ref) async {
  final notifier = ref.watch(statisticsProvider.notifier);
  return notifier.getStatsForDate(DateTime.now());
});

/// Provider for weekly screen time data.
final weeklyScreenTimeProvider =
    FutureProvider<List<ScreenTimeEntry>>((ref) async {
  final notifier = ref.watch(statisticsProvider.notifier);
  return notifier.getWeeklyScreenTime();
});

/// Provider for monthly screen time data.
final monthlyScreenTimeProvider =
    FutureProvider<List<ScreenTimeEntry>>((ref) async {
  final notifier = ref.watch(statisticsProvider.notifier);
  return notifier.getMonthlyScreenTime();
});

/// Provider for weekly comparison.
final weeklyComparisonProvider =
    FutureProvider<WeeklyComparison>((ref) async {
  final notifier = ref.watch(statisticsProvider.notifier);
  return notifier.getWeeklyComparison();
});

/// Provider for today's top 3 apps.
final topAppsProvider = FutureProvider<List<AppUsageEntry>>((ref) async {
  final notifier = ref.watch(statisticsProvider.notifier);
  return notifier.getTopApps(3, DateTime.now());
});

/// Provider for today's per-app breakdown.
final appBreakdownProvider = FutureProvider<List<AppUsageEntry>>((ref) async {
  final notifier = ref.watch(statisticsProvider.notifier);
  return notifier.getPerAppBreakdown(DateTime.now());
});
