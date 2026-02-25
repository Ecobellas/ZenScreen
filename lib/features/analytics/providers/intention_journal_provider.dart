import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/intention_log.dart';
import '../../../core/providers/providers.dart';

/// Aggregated intention data for charts and insights.
class IntentionBreakdown {
  final DateTime date;
  final Map<IntentionType, int> counts;

  const IntentionBreakdown({required this.date, required this.counts});

  int get total => counts.values.fold(0, (a, b) => a + b);

  /// Returns the dominant intention type and its percentage.
  (IntentionType, double)? get dominant {
    if (total == 0) return null;
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    return (top.key, (top.value / total) * 100);
  }
}

/// Provides intention journal data for analytics.
class IntentionJournalNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseHelper _db;

  IntentionJournalNotifier({required DatabaseHelper db})
      : _db = db,
        super(const AsyncValue.data(null));

  /// Gets the intention breakdown for a specific date (for pie chart).
  Future<IntentionBreakdown> getDailyBreakdown(DateTime date) async {
    final db = await _db.database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await db.query(
      'intention_logs',
      where: 'timestamp LIKE ?',
      whereArgs: ['$dateStr%'],
    );

    final counts = <IntentionType, int>{
      for (final type in IntentionType.values) type: 0,
    };
    for (final row in rows) {
      final type = IntentionType.values[row['intention_type'] as int? ?? 0];
      counts[type] = (counts[type] ?? 0) + 1;
    }

    return IntentionBreakdown(date: date, counts: counts);
  }

  /// Gets weekly intention trends (7 daily breakdowns).
  Future<List<IntentionBreakdown>> getWeeklyTrends() async {
    final trends = <IntentionBreakdown>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final breakdown = await getDailyBreakdown(date);
      trends.add(breakdown);
    }
    return trends;
  }

  /// Generates insight text like:
  /// "This week you opened Instagram mostly out of Boredom (65%)"
  Future<String> getInsightText() async {
    final db = await _db.database;
    final now = DateTime.now();
    final weekAgo = DateTime(now.year, now.month, now.day - 7);

    final rows = await db.query(
      'intention_logs',
      where: 'timestamp >= ?',
      whereArgs: [weekAgo.toIso8601String()],
    );

    if (rows.isEmpty) {
      return 'No intention data this week. Use apps with friction enabled to start tracking.';
    }

    // Group by app and intention.
    final appIntentions = <String, Map<IntentionType, int>>{};
    for (final row in rows) {
      final app = row['app_package'] as String;
      final type = IntentionType.values[row['intention_type'] as int? ?? 0];
      appIntentions.putIfAbsent(app, () => {});
      appIntentions[app]![type] = (appIntentions[app]![type] ?? 0) + 1;
    }

    // Find the app with the most logs.
    String? topApp;
    int topCount = 0;
    for (final entry in appIntentions.entries) {
      final count = entry.value.values.fold(0, (a, b) => a + b);
      if (count > topCount) {
        topCount = count;
        topApp = entry.key;
      }
    }

    if (topApp == null) {
      return 'Start using friction-enabled apps to see insights.';
    }

    // Find dominant intention for that app.
    final intentions = appIntentions[topApp]!;
    final sorted = intentions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dominant = sorted.first;
    final percentage = ((dominant.value / topCount) * 100).round();

    final appName = _friendlyAppName(topApp);
    final intentionName = _intentionLabel(dominant.key);

    return 'This week you opened $appName mostly out of $intentionName ($percentage%)';
  }

  /// Gets filtered intention logs.
  Future<List<IntentionLog>> getFilteredLogs({
    String? appPackage,
    IntentionType? intentionType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db.database;

    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (appPackage != null) {
      where.add('app_package = ?');
      whereArgs.add(appPackage);
    }
    if (intentionType != null) {
      where.add('intention_type = ?');
      whereArgs.add(intentionType.index);
    }
    if (startDate != null) {
      where.add('timestamp >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where.add('timestamp <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final rows = await db.query(
      'intention_logs',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
    );

    return rows.map((r) => IntentionLog.fromMap(r)).toList();
  }

  /// Gets top apps by a specific intention type.
  Future<List<(String, int)>> getTopAppsByIntention(
      IntentionType type) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT app_package, COUNT(*) as count FROM intention_logs '
      'WHERE intention_type = ? '
      'GROUP BY app_package ORDER BY count DESC',
      [type.index],
    );
    return rows
        .map((r) => (r['app_package'] as String, r['count'] as int))
        .toList();
  }

  String _friendlyAppName(String packageName) {
    // Extract last segment of package name as a readable name.
    final parts = packageName.split('.');
    if (parts.length > 1) {
      final name = parts.last;
      return name[0].toUpperCase() + name.substring(1);
    }
    return packageName;
  }

  String _intentionLabel(IntentionType type) {
    switch (type) {
      case IntentionType.work:
        return 'Work';
      case IntentionType.social:
        return 'Social';
      case IntentionType.boredom:
        return 'Boredom';
      case IntentionType.justChecking:
        return 'Just Checking';
    }
  }
}

/// Global provider for intention journal.
final intentionJournalProvider =
    StateNotifierProvider<IntentionJournalNotifier, AsyncValue<void>>((ref) {
  return IntentionJournalNotifier(db: ref.watch(databaseProvider));
});

/// Provider for today's intention breakdown (pie chart).
final todayIntentionBreakdownProvider =
    FutureProvider<IntentionBreakdown>((ref) async {
  final notifier = ref.watch(intentionJournalProvider.notifier);
  return notifier.getDailyBreakdown(DateTime.now());
});

/// Provider for weekly intention trends.
final weeklyIntentionTrendsProvider =
    FutureProvider<List<IntentionBreakdown>>((ref) async {
  final notifier = ref.watch(intentionJournalProvider.notifier);
  return notifier.getWeeklyTrends();
});

/// Provider for insight text.
final intentionInsightProvider = FutureProvider<String>((ref) async {
  final notifier = ref.watch(intentionJournalProvider.notifier);
  return notifier.getInsightText();
});

/// Provider for all recent intention logs (last 7 days).
final recentIntentionLogsProvider =
    FutureProvider<List<IntentionLog>>((ref) async {
  final notifier = ref.watch(intentionJournalProvider.notifier);
  final now = DateTime.now();
  return notifier.getFilteredLogs(
    startDate: DateTime(now.year, now.month, now.day - 7),
  );
});
