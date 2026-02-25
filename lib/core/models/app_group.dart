import 'enums.dart';

class AppGroup {
  final int? id;
  final String name;
  final String icon;
  final FrictionType frictionType;
  final int dailyLimitMinutes;
  final bool isStrictMode;

  const AppGroup({
    this.id,
    required this.name,
    this.icon = 'apps',
    this.frictionType = FrictionType.wait,
    this.dailyLimitMinutes = 60,
    this.isStrictMode = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'friction_type': frictionType.index,
        'daily_limit_minutes': dailyLimitMinutes,
        'is_strict_mode': isStrictMode ? 1 : 0,
      };

  factory AppGroup.fromMap(Map<String, dynamic> map) => AppGroup(
        id: map['id'] as int?,
        name: map['name'] as String,
        icon: map['icon'] as String? ?? 'apps',
        frictionType: FrictionType.values[map['friction_type'] as int? ?? 0],
        dailyLimitMinutes: map['daily_limit_minutes'] as int? ?? 60,
        isStrictMode: (map['is_strict_mode'] as int? ?? 0) == 1,
      );
}
