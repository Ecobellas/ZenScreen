import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/monitoring_service.dart';
import '../../../core/providers/service_providers.dart';
import '../providers/friction_provider.dart';
import '../providers/friction_settings_provider.dart';
import '../screens/friction_overlay_screen.dart';

/// Connects [MonitoringService] app-open events to the friction system.
///
/// When a monitored app opens, the interceptor checks whether the app is in
/// a blocked group, respects the grace period, and shows the appropriate
/// friction overlay if needed.
class FrictionInterceptor {
  final Ref _ref;
  StreamSubscription<AppOpenEvent>? _subscription;

  /// The navigator key used to push the friction overlay.
  final GlobalKey<NavigatorState> navigatorKey;

  FrictionInterceptor(this._ref, {required this.navigatorKey});

  /// Starts listening to app-open events from the monitoring service.
  void start() {
    _subscription?.cancel();

    final monitoringService = _ref.read(monitoringServiceProvider);
    _subscription = monitoringService.appOpenEvents.listen(_onAppOpen);
  }

  /// Stops listening to app-open events.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Handles an incoming app-open event.
  Future<void> _onAppOpen(AppOpenEvent event) async {
    // Check if the app is in a blocked group.
    final settings = _ref.read(frictionSettingsProvider.notifier);
    final isBlocked = await settings.isAppBlocked(event.packageName);

    if (!isBlocked) return;

    // Attempt to start friction (provider handles grace period internally).
    final notifier = _ref.read(frictionProvider.notifier);
    final frictionStarted = await notifier.handleAppOpen(
      event.packageName,
      event.appName,
    );

    if (!frictionStarted) return;

    // Show the friction overlay.
    _showFrictionOverlay();
  }

  /// Pushes the friction overlay screen onto the navigator.
  void _showFrictionOverlay() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: const FrictionOverlayScreen(),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  /// Disposes the interceptor and cleans up the subscription.
  void dispose() {
    stop();
  }
}

/// Provider for the [FrictionInterceptor].
///
/// Requires the root navigator key to be set via [frictionNavigatorKeyProvider].
final frictionInterceptorProvider = Provider<FrictionInterceptor>((ref) {
  final navigatorKey = ref.watch(frictionNavigatorKeyProvider);
  final interceptor = FrictionInterceptor(ref, navigatorKey: navigatorKey);

  ref.onDispose(() => interceptor.dispose());

  return interceptor;
});

/// The root navigator key used by [FrictionInterceptor] to push overlays.
///
/// Must be overridden in the app to provide the actual navigator key.
final frictionNavigatorKeyProvider =
    Provider<GlobalKey<NavigatorState>>((ref) {
  throw UnimplementedError(
    'frictionNavigatorKeyProvider must be overridden with the root navigator key',
  );
});
