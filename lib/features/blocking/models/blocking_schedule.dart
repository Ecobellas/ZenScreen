import 'package:flutter/material.dart';

/// A time-based blocking schedule for an app group (BLCK-01).
///
/// Defines a recurring window (start/end time + days of week) during which
/// all apps in the associated group are blocked.
class BlockingSchedule {
  final int? id;
  final int groupId;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  /// Days of week when this schedule is active. 1=Monday .. 7=Sunday.
  final List<int> daysOfWeek;
  final bool isActive;

  const BlockingSchedule({
    this.id,
    required this.groupId,
    required this.startTime,
    required this.endTime,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    this.isActive = true,
  });

  BlockingSchedule copyWith({
    int? id,
    int? groupId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? daysOfWeek,
    bool? isActive,
  }) {
    return BlockingSchedule(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Whether this schedule is currently active (right now, on this day/time).
  bool isCurrentlyActive() {
    if (!isActive) return false;

    final now = DateTime.now();
    // DateTime.weekday: 1=Monday .. 7=Sunday (matches our format).
    if (!daysOfWeek.contains(now.weekday)) return false;

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    // Handle overnight schedules (e.g., 22:00 - 07:00).
    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'group_id': groupId,
        'start_hour': startTime.hour,
        'start_minute': startTime.minute,
        'end_hour': endTime.hour,
        'end_minute': endTime.minute,
        'days_of_week': daysOfWeek.join(','),
        'is_active': isActive ? 1 : 0,
      };

  factory BlockingSchedule.fromMap(Map<String, dynamic> map) {
    return BlockingSchedule(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      startTime: TimeOfDay(
        hour: map['start_hour'] as int,
        minute: map['start_minute'] as int,
      ),
      endTime: TimeOfDay(
        hour: map['end_hour'] as int,
        minute: map['end_minute'] as int,
      ),
      daysOfWeek: (map['days_of_week'] as String)
          .split(',')
          .map(int.parse)
          .toList(),
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  /// Human-readable time range string (e.g., "22:00 - 07:00").
  String get timeRangeString {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(startTime.hour)}:${pad(startTime.minute)} - '
        '${pad(endTime.hour)}:${pad(endTime.minute)}';
  }

  /// Human-readable days string (e.g., "Mon-Fri" or "Every day").
  String get daysString {
    if (daysOfWeek.length == 7) return 'Every day';
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return daysOfWeek.map((d) => names[d]).join(', ');
  }
}
