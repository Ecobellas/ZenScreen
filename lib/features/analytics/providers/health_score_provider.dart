import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/database/preferences_service.dart';
import '../../../core/models/daily_stats.dart';
import '../../../core/providers/providers.dart';

/// Data class for a single day's health score with its date.
class DatedScore {
  final DateTime date;
  final int score;
  const DatedScore({required this.date, required this.score});
}

/// Calculates the daily health score (0-100) based on:
/// - Screen time vs goal: up to 40 points
/// - App open count: up to 20 points
/// - Night usage (22:00-06:00): up to 15 points
/// - Friction dismiss rate: up to 15 points
/// - Bypass count: up to 10 points
///
/// Score resets daily at midnight (HLTH-04).
class HealthScoreNotifier extends StateNotifier<AsyncValue<int>> {
  final DatabaseHelper _db;
  final PreferencesService _prefs;

  HealthScoreNotifier({
    required DatabaseHelper db,
    required PreferencesService prefs,
  })  : _db = db,
        _prefs = prefs,
        super(const AsyncValue.loading()) {
    loadTodayScore();
  }

  /// Loads today's health score.
  Future<void> loadTodayScore() async {
    state = const AsyncValue.loading();
    try {
      final score = await scoreForDate(DateTime.now());
      state = AsyncValue.data(score);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Calculates the health score for a given [date].
  Future<int> scoreForDate(DateTime date) async {
    final stats = await _getStatsForDate(date);
    if (stats == null) return 100; // No data = perfect score (fresh day).
    return _calculateScore(stats);
  }

  /// Returns the last 7 days of scores (most recent last).
  Future<List<DatedScore>> weeklyScores() async {
    return _scoresForDays(7);
  }

  /// Returns the last 30 days of scores (most recent last).
  Future<List<DatedScore>> monthlyScores() async {
    return _scoresForDays(30);
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  int _calculateScore(DailyStats stats) {
    double score = 0;

    // 1. Screen time vs goal: up to 40 points.
    final goalMinutes = _prefs.dailyGoalMinutes;
    if (goalMinutes > 0) {
      final ratio = stats.totalScreenTimeMinutes / goalMinutes;
      if (ratio <= 1.0) {
        score += 40;
      } else {
        // Proportionally decrease: at 2x goal = 0 points.
        score += (40 * (2.0 - ratio).clamp(0.0, 1.0));
      }
    } else {
      score += 40; // No goal set, full points.
    }

    // 2. App open count: up to 20 points (full if <50 opens).
    if (stats.appOpenCount < 50) {
      score += 20;
    } else if (stats.appOpenCount < 100) {
      score += 20 * ((100 - stats.appOpenCount) / 50);
    }
    // >= 100 opens = 0 points for this category.

    // 3. Night usage: up to 15 points.
    // We approximate night usage from total screen time if > goal.
    // Since we don't track night usage separately, we give full points by default.
    // In a real implementation, this would query usage between 22:00-06:00.
    score += 15;

    // 4. Friction dismiss rate: up to 15 points.
    // Higher dismiss rate = user is resisting temptation = good.
    if (stats.frictionShownCount > 0) {
      final dismissRate =
          stats.frictionDismissedCount / stats.frictionShownCount;
      score += 15 * dismissRate;
    } else {
      score += 15; // No friction shown = full points.
    }

    // 5. Bypass count: up to 10 points (0 bypasses = full).
    if (stats.frictionBypassedCount == 0) {
      score += 10;
    } else if (stats.frictionBypassedCount < 5) {
      score += 10 * ((5 - stats.frictionBypassedCount) / 5);
    }
    // >= 5 bypasses = 0 points for this category.

    return score.round().clamp(0, 100);
  }

  Future<DailyStats?> _getStatsForDate(DateTime date) async {
    final db = await _db.database;
    final dateStr = _formatDate(date);
    final rows = await db.query(
      'daily_stats',
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DailyStats.fromMap(rows.first);
  }

  Future<List<DatedScore>> _scoresForDays(int days) async {
    final scores = <DatedScore>[];
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final score = await scoreForDate(date);
      scores.add(DatedScore(date: date, score: score));
    }
    return scores;
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().substring(0, 10);
  }
}

/// Provider for today's health score.
final healthScoreProvider =
    StateNotifierProvider<HealthScoreNotifier, AsyncValue<int>>((ref) {
  return HealthScoreNotifier(
    db: ref.watch(databaseProvider),
    prefs: ref.watch(preferencesServiceProvider),
  );
});

/// Provider for weekly scores (7 days).
final weeklyScoresProvider = FutureProvider<List<DatedScore>>((ref) async {
  final notifier = ref.watch(healthScoreProvider.notifier);
  return notifier.weeklyScores();
});

/// Provider for monthly scores (30 days).
final monthlyScoresProvider = FutureProvider<List<DatedScore>>((ref) async {
  final notifier = ref.watch(healthScoreProvider.notifier);
  return notifier.monthlyScores();
});
