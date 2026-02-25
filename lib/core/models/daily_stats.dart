class DailyStats {
  final int? id;
  final DateTime date;
  final int totalScreenTimeMinutes;
  final int appOpenCount;
  final int frictionShownCount;
  final int frictionDismissedCount;
  final int frictionBypassedCount;
  final int healthScore;

  const DailyStats({
    this.id,
    required this.date,
    this.totalScreenTimeMinutes = 0,
    this.appOpenCount = 0,
    this.frictionShownCount = 0,
    this.frictionDismissedCount = 0,
    this.frictionBypassedCount = 0,
    this.healthScore = 100,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String().substring(0, 10),
        'total_screen_time': totalScreenTimeMinutes,
        'app_open_count': appOpenCount,
        'friction_shown': frictionShownCount,
        'friction_dismissed': frictionDismissedCount,
        'friction_bypassed': frictionBypassedCount,
        'health_score': healthScore,
      };

  factory DailyStats.fromMap(Map<String, dynamic> map) => DailyStats(
        id: map['id'] as int?,
        date: DateTime.parse(map['date'] as String),
        totalScreenTimeMinutes: map['total_screen_time'] as int? ?? 0,
        appOpenCount: map['app_open_count'] as int? ?? 0,
        frictionShownCount: map['friction_shown'] as int? ?? 0,
        frictionDismissedCount: map['friction_dismissed'] as int? ?? 0,
        frictionBypassedCount: map['friction_bypassed'] as int? ?? 0,
        healthScore: map['health_score'] as int? ?? 100,
      );
}
