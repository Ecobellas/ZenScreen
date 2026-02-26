import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/providers.dart';
import '../../analytics/providers/health_score_provider.dart';
import '../../analytics/providers/statistics_provider.dart';
import '../models/weekly_report.dart';

/// Pool of motivational messages chosen based on performance.
const _motivationalMessages = [
  'Amazing week! You\'re building strong digital habits.',
  'Great progress! Your screen time is trending in the right direction.',
  'You\'re becoming more mindful about your screen time. Keep it up!',
  'Solid week! Small consistent changes lead to big results.',
  'Your discipline is paying off. You\'re in control of your screen time.',
  'Every mindful moment counts. You\'re doing better than you think!',
  'You showed real commitment this week. Be proud of yourself!',
  'Progress isn\'t always linear, but you\'re on the right path.',
  'Your future self will thank you for the choices you made this week.',
  'Remember: it\'s not about perfection, it\'s about awareness.',
  'You\'re proving that change is possible, one day at a time.',
  'Your health score shows real improvement. That takes dedication!',
];

/// Pool of weekly tips.
const _weeklyTips = [
  'Try putting your phone in another room during meals this week.',
  'Set a specific "phone-free" hour each evening before bed.',
  'When you feel the urge to scroll, take three deep breaths first.',
  'Challenge yourself: can you go the first hour of your day phone-free?',
  'Try replacing one social media check with a 5-minute walk.',
  'Use the intention feature to pause and ask "why am I opening this?"',
  'Consider enabling Strict Mode during your most productive hours.',
  'Batch your app checks: try checking social media only 3 times today.',
  'Place your charger away from your bed to reduce nighttime scrolling.',
  'Try a "digital sunset" — no screens after 9 PM.',
  'Set up app groups to organize and limit your most-used apps.',
  'Review your top apps — are they adding value to your life?',
];

/// State for the report feature.
class ReportState {
  final List<WeeklyReport> reports;
  final bool isLoading;
  final int currentIndex;

  const ReportState({
    this.reports = const [],
    this.isLoading = false,
    this.currentIndex = 0,
  });

  ReportState copyWith({
    List<WeeklyReport>? reports,
    bool? isLoading,
    int? currentIndex,
  }) {
    return ReportState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  WeeklyReport? get currentReport =>
      reports.isNotEmpty && currentIndex < reports.length
          ? reports[currentIndex]
          : null;

  bool get hasPrevious => currentIndex < reports.length - 1;
  bool get hasNext => currentIndex > 0;
}

/// Manages weekly report generation and retrieval (REPT-01, REPT-02).
class ReportNotifier extends StateNotifier<ReportState> {
  final DatabaseHelper _db;
  final HealthScoreNotifier _healthNotifier;
  final StatisticsNotifier _statsNotifier;

  ReportNotifier({
    required DatabaseHelper db,
    required HealthScoreNotifier healthNotifier,
    required StatisticsNotifier statsNotifier,
  })  : _db = db,
        _healthNotifier = healthNotifier,
        _statsNotifier = statsNotifier,
        super(const ReportState(isLoading: true)) {
    _loadReports();
  }

  Future<void> _loadReports() async {
    state = state.copyWith(isLoading: true);
    try {
      // Generate latest report if needed, then return stored list.
      await generateWeeklyReport();
    } catch (_) {
      // Gracefully handle — report generation is best-effort.
    }
    state = state.copyWith(isLoading: false);
  }

  /// Generates a weekly report for the most recent completed week.
  Future<void> generateWeeklyReport() async {
    state = state.copyWith(isLoading: true);

    final now = DateTime.now();
    // Find the start of this week (Monday).
    final weekday = now.weekday; // 1 = Monday
    final thisMonday = DateTime(now.year, now.month, now.day - (weekday - 1));
    final lastMonday = thisMonday.subtract(const Duration(days: 7));
    final lastSunday = thisMonday.subtract(const Duration(days: 1));
    final twoWeeksAgo = lastMonday.subtract(const Duration(days: 7));

    // Aggregate this past week's data (last Monday to last Sunday).
    int totalScreenTime = 0;
    int lastWeekScreenTime = 0;

    for (int i = 0; i < 7; i++) {
      final thisDate = lastMonday.add(Duration(days: i));
      final prevDate = twoWeeksAgo.add(Duration(days: i));

      final thisStats = await _statsNotifier.getStatsForDate(thisDate);
      final prevStats = await _statsNotifier.getStatsForDate(prevDate);

      totalScreenTime += thisStats?.totalScreenTimeMinutes ?? 0;
      lastWeekScreenTime += prevStats?.totalScreenTimeMinutes ?? 0;
    }

    // Screen time change percent.
    double changePercent = 0;
    if (lastWeekScreenTime > 0) {
      changePercent =
          ((totalScreenTime - lastWeekScreenTime) / lastWeekScreenTime) * 100;
    }

    // Top 5 apps — aggregate across the week.
    final appUsage = <String, int>{};
    for (int i = 0; i < 7; i++) {
      final date = lastMonday.add(Duration(days: i));
      final apps = await _statsNotifier.getPerAppBreakdown(date);
      for (final app in apps) {
        appUsage[app.appName] =
            (appUsage[app.appName] ?? 0) + app.duration.inMinutes;
      }
    }
    final sortedApps = appUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topApps = sortedApps
        .take(5)
        .map((e) => TopAppEntry(appName: e.key, durationMinutes: e.value))
        .toList();

    // Health score average + trend.
    int scoreSum = 0;
    int scoreCount = 0;
    int firstHalfSum = 0;
    int secondHalfSum = 0;
    for (int i = 0; i < 7; i++) {
      final date = lastMonday.add(Duration(days: i));
      final score = await _healthNotifier.scoreForDate(date);
      scoreSum += score;
      scoreCount++;
      if (i < 3) {
        firstHalfSum += score;
      } else {
        secondHalfSum += score;
      }
    }
    final avgScore = scoreCount > 0 ? scoreSum ~/ scoreCount : 100;

    ScoreTrend trend;
    final firstAvg = firstHalfSum / 3;
    final secondAvg = secondHalfSum / 4;
    if (secondAvg > firstAvg + 3) {
      trend = ScoreTrend.up;
    } else if (secondAvg < firstAvg - 3) {
      trend = ScoreTrend.down;
    } else {
      trend = ScoreTrend.stable;
    }

    // Intention breakdown — aggregate across the week.
    final intentionCounts = <IntentionType, int>{
      for (final type in IntentionType.values) type: 0,
    };
    if (!_db.isStub) {
      final db = await _db.database;
      final intentionRows = await db.query(
        'intention_logs',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [
          lastMonday.toIso8601String(),
          lastSunday
              .add(const Duration(hours: 23, minutes: 59, seconds: 59))
              .toIso8601String(),
        ],
      );
      for (final row in intentionRows) {
        final type =
            IntentionType.values[row['intention_type'] as int? ?? 0];
        intentionCounts[type] = (intentionCounts[type] ?? 0) + 1;
      }
    }

    // Choose motivational message and tip based on performance.
    final rng = Random(lastMonday.millisecondsSinceEpoch);
    final messageIndex = changePercent <= 0
        ? rng.nextInt(6) // Good performance → encouraging messages (first half)
        : 6 + rng.nextInt(6); // Needs improvement → supportive messages
    final tipIndex = rng.nextInt(_weeklyTips.length);

    final report = WeeklyReport(
      weekStartDate: lastMonday,
      weekEndDate: lastSunday,
      totalScreenTimeMinutes: totalScreenTime,
      lastWeekScreenTimeMinutes: lastWeekScreenTime,
      screenTimeChangePercent: changePercent,
      topApps: topApps,
      healthScoreAverage: avgScore,
      healthScoreTrend: trend,
      intentionBreakdown: intentionCounts,
      motivationalMessage: _motivationalMessages[messageIndex],
      weeklyTip: _weeklyTips[tipIndex],
    );

    // Add to reports list (avoid duplicates by checking weekStartDate).
    final existing = state.reports.toList();
    final dupIndex = existing.indexWhere(
      (r) =>
          r.weekStartDate.toIso8601String() ==
          report.weekStartDate.toIso8601String(),
    );
    if (dupIndex >= 0) {
      existing[dupIndex] = report;
    } else {
      existing.insert(0, report);
    }

    state = state.copyWith(reports: existing, isLoading: false);
  }

  /// Returns the latest report, or null.
  WeeklyReport? getLatestReport() => state.currentReport;

  /// Returns all generated reports.
  List<WeeklyReport> getAllReports() => state.reports;

  /// Navigate to the previous (older) report.
  void showPreviousReport() {
    if (state.hasPrevious) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  /// Navigate to the next (newer) report.
  void showNextReport() {
    if (state.hasNext) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }
}

/// Global provider for weekly reports.
final reportProvider =
    StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier(
    db: ref.watch(databaseProvider),
    healthNotifier: ref.watch(healthScoreProvider.notifier),
    statsNotifier: ref.watch(statisticsProvider.notifier),
  );
});
