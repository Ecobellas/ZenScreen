import 'platform_channel.dart';

/// Status of a single permission.
enum PermissionStatus {
  /// Permission has been granted by the user.
  granted,

  /// Permission was denied (user can still be asked again).
  denied,

  /// Permission was permanently denied (user must go to settings).
  permanentlyDenied,

  /// Permission is restricted by the OS (e.g., parental controls on iOS).
  restricted,
}

/// Higher-level permission abstraction that wraps [PlatformChannelService].
///
/// Converts raw boolean results from the platform channel into
/// [PermissionStatus] values and provides batch operations.
class PermissionService {
  final PlatformChannelService _platform;

  PermissionService(this._platform);

  // ---------------------------------------------------------------------------
  // Individual permission requests
  // ---------------------------------------------------------------------------

  /// Requests usage stats permission and returns the resulting status.
  Future<PermissionStatus> requestUsagePermission() async {
    final granted = await _platform.requestUsagePermission();
    return granted ? PermissionStatus.granted : PermissionStatus.denied;
  }

  /// Requests notification permission and returns the resulting status.
  Future<PermissionStatus> requestNotificationPermission() async {
    final granted = await _platform.requestNotificationPermission();
    return granted ? PermissionStatus.granted : PermissionStatus.denied;
  }

  /// Requests overlay / draw-over-apps permission and returns the status.
  Future<PermissionStatus> requestOverlayPermission() async {
    final granted = await _platform.requestOverlayPermission();
    return granted ? PermissionStatus.granted : PermissionStatus.denied;
  }

  // ---------------------------------------------------------------------------
  // Permission checks
  // ---------------------------------------------------------------------------

  /// Checks the current status of usage stats permission.
  Future<PermissionStatus> checkUsagePermission() async {
    final granted = await _platform.checkUsagePermission();
    return granted ? PermissionStatus.granted : PermissionStatus.denied;
  }

  /// Checks the current status of notification permission.
  Future<PermissionStatus> checkNotificationPermission() async {
    final granted = await _platform.checkNotificationPermission();
    return granted ? PermissionStatus.granted : PermissionStatus.denied;
  }

  /// Checks the current status of overlay permission.
  Future<PermissionStatus> checkOverlayPermission() async {
    final granted = await _platform.checkOverlayPermission();
    return granted ? PermissionStatus.granted : PermissionStatus.denied;
  }

  // ---------------------------------------------------------------------------
  // Batch operations
  // ---------------------------------------------------------------------------

  /// Requests all required permissions in sequence.
  ///
  /// Returns a map of permission name to resulting status.
  Future<Map<String, PermissionStatus>> requestAllPermissions() async {
    final usage = await requestUsagePermission();
    final notification = await requestNotificationPermission();
    final overlay = await requestOverlayPermission();

    return {
      'usage': usage,
      'notification': notification,
      'overlay': overlay,
    };
  }

  /// Returns the current status of all permissions.
  Future<Map<String, PermissionStatus>> getPermissionStatuses() async {
    final usage = await checkUsagePermission();
    final notification = await checkNotificationPermission();
    final overlay = await checkOverlayPermission();

    return {
      'usage': usage,
      'notification': notification,
      'overlay': overlay,
    };
  }

  /// Returns true if all required permissions are granted.
  Future<bool> areAllPermissionsGranted() async {
    final statuses = await getPermissionStatuses();
    return statuses.values.every((s) => s == PermissionStatus.granted);
  }
}
