import 'package:flutter/material.dart';

class TimeProfile {
  final int? id;
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<int> activeDays; // 1=Mon, 7=Sun
  final bool isStrictMode;
  final List<int> blockedGroupIds;

  const TimeProfile({
    this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.activeDays = const [1, 2, 3, 4, 5, 6, 7],
    this.isStrictMode = false,
    this.blockedGroupIds = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'start_hour': startTime.hour,
        'start_minute': startTime.minute,
        'end_hour': endTime.hour,
        'end_minute': endTime.minute,
        'active_days': activeDays.join(','),
        'is_strict_mode': isStrictMode ? 1 : 0,
      };

  factory TimeProfile.fromMap(Map<String, dynamic> map) => TimeProfile(
        id: map['id'] as int?,
        name: map['name'] as String,
        startTime: TimeOfDay(
            hour: map['start_hour'] as int, minute: map['start_minute'] as int),
        endTime: TimeOfDay(
            hour: map['end_hour'] as int, minute: map['end_minute'] as int),
        activeDays: (map['active_days'] as String)
            .split(',')
            .map(int.parse)
            .toList(),
        isStrictMode: (map['is_strict_mode'] as int? ?? 0) == 1,
      );
}
