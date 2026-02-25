import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';

/// Central Method Channel service for native platform communication.
///
/// Provides a unified interface for Flutter to call native iOS/Android APIs
/// for permissions, usage stats, and monitoring services.
class PlatformChannelService {
  static const MethodChannel _channel = MethodChannel('com.zenscreen/platform');

  /// Whether the current platform supports native method channels.
  bool get _isSupported => !kIsWeb;

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  /// Requests usage stats permission (Android: UsageAccess, iOS: Screen Time).
  /// Returns true if permission was granted.
  Future<bool> requestUsagePermission() async {
    if (!_isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('requestUsagePermission');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('PlatformChannel: requestUsagePermission failed: $e');
      return false;
    }
  }

  /// Requests notification permission.
  /// Returns true if permission was granted.
  Future<bool> requestNotificationPermission() async {
    if (!_isSupported) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('requestNotificationPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('PlatformChannel: requestNotificationPermission failed: $e');
      return false;
    }
  }

  /// Requests overlay / draw-over-apps permission (Android only).
  /// Returns true if permission was granted.
  Future<bool> requestOverlayPermission() async {
    if (!_isSupported) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('requestOverlayPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('PlatformChannel: requestOverlayPermission failed: $e');
      return false;
    }
  }

  /// Checks if usage stats permission is granted.
  Future<bool> checkUsagePermission() async {
    if (!_isSupported) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('checkUsagePermission');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('PlatformChannel: checkUsagePermission failed: $e');
      return false;
    }
  }

  /// Checks if notification permission is granted.
  Future<bool> checkNotificationPermission() async {
    if (!_isSupported) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('checkNotificationPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('PlatformChannel: checkNotificationPermission failed: $e');
      return false;
    }
  }

  /// Checks if overlay permission is granted.
  Future<bool> checkOverlayPermission() async {
    if (!_isSupported) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('checkOverlayPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('PlatformChannel: checkOverlayPermission failed: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Monitoring Service
  // ---------------------------------------------------------------------------

  /// Starts the native background monitoring service.
  /// Returns true if the service was started successfully.
  Future<bool> startMonitoringService() async {
    if (!_isSupported) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('startMonitoringService');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('PlatformChannel: startMonitoringService failed: $e');
      return false;
    }
  }

  /// Stops the native background monitoring service.
  /// Returns true if the service was stopped successfully.
  Future<bool> stopMonitoringService() async {
    if (!_isSupported) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('stopMonitoringService');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('PlatformChannel: stopMonitoringService failed: $e');
      return false;
    }
  }

  /// Checks whether the background monitoring service is currently running.
  Future<bool> isServiceRunning() async {
    if (!_isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isServiceRunning');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('PlatformChannel: isServiceRunning failed: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Usage Data
  // ---------------------------------------------------------------------------

  /// Returns usage stats for the given time range.
  ///
  /// [startTime] and [endTime] are milliseconds since epoch.
  /// Returns a list of maps with keys: packageName, appName, usageTime,
  /// openCount, lastUsed.
  Future<List<Map<String, dynamic>>> getUsageStats({
    required int startTime,
    required int endTime,
  }) async {
    if (!_isSupported) return [];
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getUsageStats',
        {'startTime': startTime, 'endTime': endTime},
      );
      if (result == null) return [];
      return result
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on PlatformException catch (e) {
      debugPrint('PlatformChannel: getUsageStats failed: $e');
      return [];
    }
  }

  /// Returns a list of installed apps.
  ///
  /// Each map contains: packageName, appName, category.
  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    if (!_isSupported) return [];
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (result == null) return [];
      return result
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on PlatformException catch (e) {
      debugPrint('PlatformChannel: getInstalledApps failed: $e');
      return [];
    }
  }
}
