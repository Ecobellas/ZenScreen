import '../../../core/models/enums.dart';

/// A single app entry within the weekly report's top apps list.
class TopAppEntry {
  final String appName;
  final int durationMinutes;

  const TopAppEntry({
    required this.appName,
    required this.durationMinutes,
  });

  Map<String, dynamic> toMap() => {
        'appName': appName,
        'durationMinutes': durationMinutes,
      };

  factory TopAppEntry.fromMap(Map<String, dynamic> map) => TopAppEntry(
        appName: map['appName'] as String,
        durationMinutes: map['durationMinutes'] as int,
      );
}

/// Health score trend direction.
enum ScoreTrend { up, down, stable }

/// Weekly report data model (REPT-01, REPT-02).
class WeeklyReport {
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final int totalScreenTimeMinutes;
  final int lastWeekScreenTimeMinutes;
  final double screenTimeChangePercent;
  final List<TopAppEntry> topApps;
  final int healthScoreAverage;
  final ScoreTrend healthScoreTrend;
  final Map<IntentionType, int> intentionBreakdown;
  final String motivationalMessage;
  final String weeklyTip;

  const WeeklyReport({
    required this.weekStartDate,
    required this.weekEndDate,
    required this.totalScreenTimeMinutes,
    required this.lastWeekScreenTimeMinutes,
    required this.screenTimeChangePercent,
    required this.topApps,
    required this.healthScoreAverage,
    required this.healthScoreTrend,
    required this.intentionBreakdown,
    required this.motivationalMessage,
    required this.weeklyTip,
  });

  Map<String, dynamic> toMap() => {
        'weekStartDate': weekStartDate.toIso8601String(),
        'weekEndDate': weekEndDate.toIso8601String(),
        'totalScreenTimeMinutes': totalScreenTimeMinutes,
        'lastWeekScreenTimeMinutes': lastWeekScreenTimeMinutes,
        'screenTimeChangePercent': screenTimeChangePercent,
        'topApps': topApps.map((a) => a.toMap()).toList(),
        'healthScoreAverage': healthScoreAverage,
        'healthScoreTrend': healthScoreTrend.name,
        'intentionBreakdown': intentionBreakdown.map(
          (k, v) => MapEntry(k.index.toString(), v),
        ),
        'motivationalMessage': motivationalMessage,
        'weeklyTip': weeklyTip,
      };

  factory WeeklyReport.fromMap(Map<String, dynamic> map) {
    final topAppsRaw = map['topApps'] as List<dynamic>;
    final intentionRaw =
        map['intentionBreakdown'] as Map<String, dynamic>;

    return WeeklyReport(
      weekStartDate: DateTime.parse(map['weekStartDate'] as String),
      weekEndDate: DateTime.parse(map['weekEndDate'] as String),
      totalScreenTimeMinutes: map['totalScreenTimeMinutes'] as int,
      lastWeekScreenTimeMinutes: map['lastWeekScreenTimeMinutes'] as int,
      screenTimeChangePercent:
          (map['screenTimeChangePercent'] as num).toDouble(),
      topApps: topAppsRaw
          .map((a) => TopAppEntry.fromMap(a as Map<String, dynamic>))
          .toList(),
      healthScoreAverage: map['healthScoreAverage'] as int,
      healthScoreTrend: ScoreTrend.values.firstWhere(
        (t) => t.name == map['healthScoreTrend'],
        orElse: () => ScoreTrend.stable,
      ),
      intentionBreakdown: intentionRaw.map(
        (k, v) => MapEntry(IntentionType.values[int.parse(k)], v as int),
      ),
      motivationalMessage: map['motivationalMessage'] as String,
      weeklyTip: map['weeklyTip'] as String,
    );
  }
}
