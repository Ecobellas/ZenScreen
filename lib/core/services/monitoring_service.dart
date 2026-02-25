import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'platform_channel.dart';

/// Represents a real-time event when a monitored app is opened.
class AppOpenEvent {
  /// Package identifier of the opened app.
  final String packageName;

  /// Human-readable name of the opened app.
  final String appName;

  /// Timestamp (ms since epoch) when the app was detected as opened.
  final int timestamp;

  const AppOpenEvent({
    required this.packageName,
    required this.appName,
    required this.timestamp,
  });

  /// Creates an [AppOpenEvent] from a platform event map.
  factory AppOpenEvent.fromMap(Map<String, dynamic> map) {
    return AppOpenEvent(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }

  /// Returns [timestamp] as a [DateTime].
  DateTime get time => DateTime.fromMillisecondsSinceEpoch(timestamp);

  @override
  String toString() => 'AppOpenEvent($appName at $time)';
}

/// Controls the native background monitoring service and provides
/// a stream of real-time app-open events via [EventChannel].
class MonitoringService {
  final PlatformChannelService _platform;

  static const EventChannel _eventChannel =
      EventChannel('com.zenscreen/app_events');

  /// Cached broadcast stream so multiple listeners share one subscription.
  Stream<AppOpenEvent>? _eventStream;

  MonitoringService(this._platform);

  // ---------------------------------------------------------------------------
  // Service lifecycle
  // ---------------------------------------------------------------------------

  /// Starts the native background monitoring service.
  ///
  /// On Android this launches a foreground service. On iOS this is currently
  /// a stub (Screen Time API requires entitlements).
  Future<bool> startMonitoring() async {
    return _platform.startMonitoringService();
  }

  /// Stops the native background monitoring service.
  Future<bool> stopMonitoring() async {
    return _platform.stopMonitoringService();
  }

  /// Returns whether the monitoring service is currently running.
  Future<bool> isMonitoring() async {
    return _platform.isServiceRunning();
  }

  // ---------------------------------------------------------------------------
  // Event stream
  // ---------------------------------------------------------------------------

  /// A broadcast stream of [AppOpenEvent]s emitted by the native service
  /// whenever a monitored app is opened.
  ///
  /// Returns an empty stream on unsupported platforms (web/desktop).
  Stream<AppOpenEvent> get appOpenEvents {
    if (kIsWeb) return const Stream.empty();

    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) =>
            AppOpenEvent.fromMap(Map<String, dynamic>.from(event as Map)))
        .asBroadcastStream();

    return _eventStream!;
  }
}
