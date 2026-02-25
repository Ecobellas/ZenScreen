import 'enums.dart';

class IntentionLog {
  final int? id;
  final DateTime timestamp;
  final String appPackage;
  final IntentionType intention;
  final bool didProceed;
  final int sessionDurationSeconds;

  const IntentionLog({
    this.id,
    required this.timestamp,
    required this.appPackage,
    required this.intention,
    this.didProceed = false,
    this.sessionDurationSeconds = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'app_package': appPackage,
        'intention_type': intention.index,
        'did_proceed': didProceed ? 1 : 0,
        'session_duration': sessionDurationSeconds,
      };

  factory IntentionLog.fromMap(Map<String, dynamic> map) => IntentionLog(
        id: map['id'] as int?,
        timestamp: DateTime.parse(map['timestamp'] as String),
        appPackage: map['app_package'] as String,
        intention: IntentionType.values[map['intention_type'] as int? ?? 0],
        didProceed: (map['did_proceed'] as int? ?? 0) == 1,
        sessionDurationSeconds: map['session_duration'] as int? ?? 0,
      );
}
