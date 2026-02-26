import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/providers.dart';
import '../../analytics/providers/health_score_provider.dart';
import '../../analytics/providers/statistics_provider.dart';
import '../../blocking/providers/strict_mode_provider.dart';
import '../widgets/health_score_circle.dart';
import '../widgets/summary_card.dart';
import '../widgets/top_apps_list.dart';

/// Full dashboard screen with health score, summary, quick actions, and top apps.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _formatScreenTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(healthScoreProvider);
    final todayStats = ref.watch(todayStatsProvider);
    final topApps = ref.watch(topAppsProvider);
    final prefs = ref.watch(preferencesServiceProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(Icons.spa, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ZenScreen',
                        style: AppTextStyles.headingMedium.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.settings, color: AppColors.textSecondary),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.md),

            // --- Health Score Circle (DASH-01, HLTH-02) ---
            scoreAsync.when(
              data: (score) => Column(
                children: [
                  HealthScoreCircle(score: score),
                  const SizedBox(height: 24),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Text(
                      'You\'re in the top 15% of mindful users today. Keep it up.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const HealthScoreCircle(score: 100),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // --- Today's Summary Cards (DASH-02) ---
            todayStats.when(
              data: (stats) {
                final screenTime =
                    stats?.totalScreenTimeMinutes ?? 0;
                final appOpens = stats?.appOpenCount ?? 0;
                final frictionDismissals =
                    stats?.frictionDismissedCount ?? 0;

                return Row(
                  children: [
                    SummaryCard(
                      icon: Icons.timer,
                      value: _formatScreenTime(screenTime),
                      label: 'Screen Time',
                      iconColor: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      icon: Icons.lock_open,
                      value: '$appOpens',
                      label: 'Pickups',
                      iconColor: Colors.purple[400],
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      icon: Icons.check_circle,
                      value: '$frictionDismissals',
                      label: 'Dismissals',
                      iconColor: Colors.tealAccent[400],
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Row(
                children: [
                  SummaryCard(
                    icon: Icons.access_time_rounded,
                    value: '0m',
                    label: 'Screen Time',
                    iconColor: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SummaryCard(
                    icon: Icons.touch_app_rounded,
                    value: '0',
                    label: 'App Opens',
                    iconColor: AppColors.secondary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SummaryCard(
                    icon: Icons.shield_outlined,
                    value: '0',
                    label: 'Dismissed',
                    iconColor: AppColors.error,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // --- Quick Actions (DASH-03) ---
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final notifier =
                          ref.read(strictModeProvider.notifier);
                      if (!notifier.isStrictModeActive()) {
                        notifier.activateStrictMode(
                          endTime: TimeOfDay(
                            hour: (TimeOfDay.now().hour + 2) % 24,
                            minute: TimeOfDay.now().minute,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.bolt, size: 20),
                    label: const Text('Strict Mode'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentWhite,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/statistics'),
                    icon: const Icon(Icons.bar_chart_rounded, size: 20),
                    label: const Text('View Report'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentWhite,
                      side: const BorderSide(color: Color(0xFF334155)), // slate-700
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                      backgroundColor: AppColors.card,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),

            // --- Top 3 Apps Today (DASH-04) ---
            topApps.when(
              data: (apps) => TopAppsList(
                apps: apps,
                dailyGoalMinutes: prefs.dailyGoalMinutes,
              ),
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => TopAppsList(
                apps: const [],
                dailyGoalMinutes: prefs.dailyGoalMinutes,
              ),
            ),

            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }
}
