/// Daily time limit for an app group (BLCK-02).
///
/// Tracks how many minutes per day a group of apps can be used.
/// When [currentUsageMinutes] reaches [limitMinutes], all apps in
/// the group are blocked for the remainder of the day.
class DailyLimit {
  final int? id;
  final int groupId;

  /// Maximum allowed usage in minutes per day.
  final int limitMinutes;

  /// Current usage accumulated today (in minutes).
  final int currentUsageMinutes;
  final bool isActive;

  const DailyLimit({
    this.id,
    required this.groupId,
    required this.limitMinutes,
    this.currentUsageMinutes = 0,
    this.isActive = true,
  });

  DailyLimit copyWith({
    int? id,
    int? groupId,
    int? limitMinutes,
    int? currentUsageMinutes,
    bool? isActive,
  }) {
    return DailyLimit(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      limitMinutes: limitMinutes ?? this.limitMinutes,
      currentUsageMinutes: currentUsageMinutes ?? this.currentUsageMinutes,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Minutes remaining before the daily limit is exhausted.
  int get remainingMinutes =>
      (limitMinutes - currentUsageMinutes).clamp(0, limitMinutes);

  /// Whether the daily limit has been fully used up.
  bool get isExhausted => isActive && currentUsageMinutes >= limitMinutes;

  /// Whether 5 or fewer minutes remain (BLCK-03 warning threshold).
  bool get isWarning =>
      isActive &&
      !isExhausted &&
      remainingMinutes <= 5 &&
      remainingMinutes > 0;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'group_id': groupId,
        'limit_minutes': limitMinutes,
        'current_usage_minutes': currentUsageMinutes,
        'is_active': isActive ? 1 : 0,
      };

  factory DailyLimit.fromMap(Map<String, dynamic> map) {
    return DailyLimit(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      limitMinutes: map['limit_minutes'] as int,
      currentUsageMinutes: map['current_usage_minutes'] as int? ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}
