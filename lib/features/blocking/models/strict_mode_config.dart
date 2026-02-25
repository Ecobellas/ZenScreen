import 'package:flutter/material.dart';

/// Configuration for Strict Mode (STRK-01 to STRK-04).
///
/// When Strict Mode is active, blocked apps are completely inaccessible
/// with only an emergency bypass option (60s wait + confirmation).
class StrictModeConfig {
  /// Whether Strict Mode is currently turned on.
  final bool isActive;

  /// Start time of the strict mode window.
  final TimeOfDay startTime;

  /// End time of the strict mode window.
  final TimeOfDay endTime;

  /// Whether this is a recurring scheduled strict mode period (STRK-04).
  final bool isScheduled;

  /// Days of week for recurring schedule. 1=Monday .. 7=Sunday.
  final List<int> scheduledDays;

  /// When strict mode was last activated (null if never).
  final DateTime? activatedAt;

  const StrictModeConfig({
    this.isActive = false,
    this.startTime = const TimeOfDay(hour: 22, minute: 0),
    this.endTime = const TimeOfDay(hour: 7, minute: 0),
    this.isScheduled = false,
    this.scheduledDays = const [],
    this.activatedAt,
  });

  StrictModeConfig copyWith({
    bool? isActive,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isScheduled,
    List<int>? scheduledDays,
    DateTime? activatedAt,
    bool clearActivatedAt = false,
  }) {
    return StrictModeConfig(
      isActive: isActive ?? this.isActive,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      activatedAt:
          clearActivatedAt ? null : (activatedAt ?? this.activatedAt),
    );
  }

  /// Checks whether strict mode is currently in effect based on the
  /// scheduled time window and day of week.
  bool isCurrentlyActive() {
    if (!isActive) return false;

    // If not scheduled, it's a one-off activation -- always active while on.
    if (!isScheduled) return true;

    final now = DateTime.now();
    if (!scheduledDays.contains(now.weekday)) return false;

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    // Handle overnight windows (e.g., 22:00 - 07:00).
    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  Map<String, dynamic> toMap() => {
        'is_active': isActive ? 1 : 0,
        'start_hour': startTime.hour,
        'start_minute': startTime.minute,
        'end_hour': endTime.hour,
        'end_minute': endTime.minute,
        'is_scheduled': isScheduled ? 1 : 0,
        'scheduled_days':
            scheduledDays.isNotEmpty ? scheduledDays.join(',') : '',
        'activated_at': activatedAt?.toIso8601String(),
      };

  factory StrictModeConfig.fromMap(Map<String, dynamic> map) {
    final daysStr = map['scheduled_days'] as String? ?? '';
    return StrictModeConfig(
      isActive: (map['is_active'] as int? ?? 0) == 1,
      startTime: TimeOfDay(
        hour: map['start_hour'] as int? ?? 22,
        minute: map['start_minute'] as int? ?? 0,
      ),
      endTime: TimeOfDay(
        hour: map['end_hour'] as int? ?? 7,
        minute: map['end_minute'] as int? ?? 0,
      ),
      isScheduled: (map['is_scheduled'] as int? ?? 0) == 1,
      scheduledDays: daysStr.isNotEmpty
          ? daysStr.split(',').map(int.parse).toList()
          : [],
      activatedAt: map['activated_at'] != null
          ? DateTime.tryParse(map['activated_at'] as String)
          : null,
    );
  }
}
