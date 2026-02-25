import '../../../core/models/enums.dart';

/// The action the user took when presented with a friction overlay.
enum FrictionAction { gaveUp, proceededAnyway }

/// Records a single friction event for analytics and logging.
class FrictionEvent {
  final int? id;
  final String packageName;
  final String appName;
  final FrictionType frictionType;
  final DateTime timestamp;
  final FrictionAction userAction;
  final IntentionType? intention;
  final int durationSeconds;

  const FrictionEvent({
    this.id,
    required this.packageName,
    required this.appName,
    required this.frictionType,
    required this.timestamp,
    required this.userAction,
    this.intention,
    required this.durationSeconds,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'app_package': packageName,
        'app_name': appName,
        'friction_type': frictionType.index,
        'user_action': userAction.index,
        'intention_type': intention?.index,
        'duration_seconds': durationSeconds,
      };

  factory FrictionEvent.fromMap(Map<String, dynamic> map) => FrictionEvent(
        id: map['id'] as int?,
        packageName: map['app_package'] as String,
        appName: map['app_name'] as String? ?? '',
        frictionType: FrictionType.values[map['friction_type'] as int? ?? 0],
        timestamp: DateTime.parse(map['timestamp'] as String),
        userAction: FrictionAction.values[map['user_action'] as int? ?? 0],
        intention: map['intention_type'] != null
            ? IntentionType.values[map['intention_type'] as int]
            : null,
        durationSeconds: map['duration_seconds'] as int? ?? 0,
      );
}
