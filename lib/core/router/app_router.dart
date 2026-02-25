import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/blocking/screens/blocking_overlay_screen.dart';
import '../../features/blocking/screens/blocking_screen.dart';
import '../../features/blocking/screens/group_edit_screen.dart';
import '../../features/blocking/screens/strict_mode_screen.dart';
import '../../features/blocking/screens/time_profiles_screen.dart';
import '../../features/friction/screens/friction_overlay_screen.dart';
import '../../features/monetization/screens/paywall_screen.dart';
import '../../features/reports/screens/report_screen.dart';
import '../../features/shell/shell_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/statistics/screens/statistics_screen.dart';
import '../../features/statistics/screens/journal_screen.dart';
import '../../features/statistics/screens/app_detail_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../providers/providers.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _dashboardNavKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _statisticsNavKey = GlobalKey<NavigatorState>(debugLabel: 'statistics');
final _settingsNavKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final onboardingComplete = prefs.isOnboardingComplete;
      final isOnboarding = state.matchedLocation == '/onboarding';
      if (!onboardingComplete && !isOnboarding) return '/onboarding';
      if (onboardingComplete && isOnboarding) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/report',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: '/friction',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          opaque: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: const FrictionOverlayScreen(),
        ),
      ),
      GoRoute(
        path: '/blocking-overlay',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final packageName =
              state.uri.queryParameters['package'] ?? '';
          return CustomTransitionPage<void>(
            opaque: false,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: BlockingOverlayScreen(packageName: packageName),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _dashboardNavKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _statisticsNavKey,
            routes: [
              GoRoute(
                path: '/statistics',
                builder: (context, state) => const StatisticsScreen(),
                routes: [
                  GoRoute(
                    path: 'journal',
                    builder: (context, state) => const JournalScreen(),
                  ),
                  GoRoute(
                    path: 'app/:id',
                    builder: (context, state) => AppDetailScreen(
                      appPackage: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'blocking',
                    builder: (context, state) => const BlockingScreen(),
                    routes: [
                      GoRoute(
                        path: 'group/:id',
                        builder: (context, state) => GroupEditScreen(
                          groupId: state.pathParameters['id'] ?? '0',
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'profiles',
                    builder: (context, state) =>
                        const TimeProfilesScreen(),
                  ),
                  GoRoute(
                    path: 'strict-mode',
                    builder: (context, state) =>
                        const StrictModeScreen(),
                  ),
                  GoRoute(
                    path: 'paywall',
                    builder: (context, state) => const PaywallScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
