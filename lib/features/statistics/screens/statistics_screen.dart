import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../analytics/providers/health_score_provider.dart';
import '../../analytics/providers/intention_journal_provider.dart';
import '../../analytics/providers/statistics_provider.dart';
import '../widgets/app_usage_bars.dart';
import '../widgets/intention_pie_chart.dart';
import '../widgets/intention_trend_chart.dart';
import '../widgets/screen_time_chart.dart';
import '../widgets/score_trend_chart.dart';
import '../widgets/weekly_comparison_card.dart';

/// Full statistics screen with three tabs: Overview, Apps, Journal (STAT-01..04).
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Statistics', style: AppTextStyles.headingMedium),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTextStyles.labelMedium,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Apps'),
              Tab(text: 'Journal'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            _AppsTab(),
            _JournalTab(),
          ],
        ),
      ),
    );
  }
}

/// Overview tab: screen time chart, health score trend, weekly comparison.
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyScreenTime = ref.watch(weeklyScreenTimeProvider);
    final monthlyScreenTime = ref.watch(monthlyScreenTimeProvider);
    final weeklyScores = ref.watch(weeklyScoresProvider);
    final monthlyScores = ref.watch(monthlyScoresProvider);
    final comparison = ref.watch(weeklyComparisonProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen time chart (STAT-01).
          weeklyScreenTime.when(
            data: (weekly) => monthlyScreenTime.when(
              data: (monthly) => ScreenTimeChart(
                weeklyData: weekly,
                monthlyData: monthly,
              ),
              loading: () => ScreenTimeChart(
                weeklyData: weekly,
                monthlyData: const [],
              ),
              error: (_, __) => ScreenTimeChart(
                weeklyData: weekly,
                monthlyData: const [],
              ),
            ),
            loading: () => const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const ScreenTimeChart(
              weeklyData: [],
              monthlyData: [],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Health score trend (HLTH-03).
          weeklyScores.when(
            data: (weekly) => monthlyScores.when(
              data: (monthly) => ScoreTrendChart(
                weeklyScores: weekly,
                monthlyScores: monthly,
              ),
              loading: () => ScoreTrendChart(
                weeklyScores: weekly,
                monthlyScores: const [],
              ),
              error: (_, __) => ScoreTrendChart(
                weeklyScores: weekly,
                monthlyScores: const [],
              ),
            ),
            loading: () => const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const ScoreTrendChart(
              weeklyScores: [],
              monthlyScores: [],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Weekly comparison (STAT-04).
          comparison.when(
            data: (data) => WeeklyComparisonCard(comparison: data),
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const WeeklyComparisonCard(
              comparison: WeeklyComparison(
                thisWeekTotal: Duration.zero,
                lastWeekTotal: Duration.zero,
                percentChange: 0,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

/// Apps tab: per-app usage breakdown (STAT-02).
class _AppsTab extends ConsumerWidget {
  const _AppsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBreakdown = ref.watch(appBreakdownProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: appBreakdown.when(
        data: (apps) => AppUsageBars(apps: apps),
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const AppUsageBars(apps: []),
      ),
    );
  }
}

/// Journal tab: intention pie chart, trends, and insight.
class _JournalTab extends ConsumerWidget {
  const _JournalTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(todayIntentionBreakdownProvider);
    final trends = ref.watch(weeklyIntentionTrendsProvider);
    final insight = ref.watch(intentionInsightProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pie chart (INTJ-02).
          breakdown.when(
            data: (data) => IntentionPieChart(breakdown: data),
            loading: () => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Trend chart (INTJ-03).
          trends.when(
            data: (data) => IntentionTrendChart(trends: data),
            loading: () => const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Insight text (INTJ-04).
          insight.when(
            data: (text) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}
