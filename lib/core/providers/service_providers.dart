import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/monitoring_service.dart';
import '../services/permission_service.dart';
import '../services/platform_channel.dart';
import '../services/usage_service.dart';

/// Provides the singleton [PlatformChannelService] instance.
final platformChannelProvider = Provider<PlatformChannelService>((ref) {
  return PlatformChannelService();
});

/// Provides the [PermissionService], wrapping the platform channel.
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService(ref.watch(platformChannelProvider));
});

/// Provides the [UsageService], wrapping the platform channel.
final usageServiceProvider = Provider<UsageService>((ref) {
  return UsageService(ref.watch(platformChannelProvider));
});

/// Provides the [MonitoringService], wrapping the platform channel.
final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  return MonitoringService(ref.watch(platformChannelProvider));
});
