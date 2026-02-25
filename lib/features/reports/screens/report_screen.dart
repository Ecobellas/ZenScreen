import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/weekly_report.dart';
import '../providers/report_provider.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Weekly Report', style: AppTextStyles.headingMedium),
      ),
      body: reportState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportState.currentReport == null
              ? _buildEmptyState()
              : _buildReport(context, ref, reportState),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assessment_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No reports yet',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your first weekly report will be generated after a full week of usage.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReport(
      BuildContext context, WidgetRef ref, ReportState reportState) {
    final report = reportState.currentReport!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildNavigationHeader(context, ref, report, reportState),
        const SizedBox(height: AppSpacing.lg),
        _buildScreenTimeCard(report),
        const SizedBox(height: AppSpacing.lg),
        _buildTopAppsCard(report),
        const SizedBox(height: AppSpacing.lg),
        _buildHealthScoreCard(report),
        const SizedBox(height: AppSpacing.lg),
        _buildIntentionCard(report),
        const SizedBox(height: AppSpacing.lg),
        _buildMotivationalCard(report),
        const SizedBox(height: AppSpacing.lg),
        _buildTipCard(report),
        const SizedBox(height: AppSpacing.huge),
      ],
    );
  }

  Widget _buildNavigationHeader(BuildContext context, WidgetRef ref,
      WeeklyReport report, ReportState reportState) {
    final startStr = _formatDate(report.weekStartDate);
    final endStr = _formatDate(report.weekEndDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: reportState.hasPrevious
              ? () => ref.read(reportProvider.notifier).showPreviousReport()
              : null,
          icon: const Icon(Icons.chevron_left),
          color: AppColors.textPrimary,
          disabledColor: AppColors.textHint,
        ),
        Column(
          children: [
            Text('$startStr - $endStr', style: AppTextStyles.bodyLarge),
            const SizedBox(height: AppSpacing.xs),
            Text('Weekly Summary', style: AppTextStyles.bodySmall),
          ],
        ),
        IconButton(
          onPressed: reportState.hasNext
              ? () => ref.read(reportProvider.notifier).showNextReport()
              : null,
          icon: const Icon(Icons.chevron_right),
          color: AppColors.textPrimary,
          disabledColor: AppColors.textHint,
        ),
      ],
    );
  }

  Widget _buildScreenTimeCard(WeeklyReport report) {
    final isImproved = report.screenTimeChangePercent <= 0;
    final changeColor = isImproved ? AppColors.secondary : AppColors.error;
    final changeIcon = isImproved ? Icons.trending_down : Icons.trending_up;
    final changeText = report.screenTimeChangePercent.abs().toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Screen Time', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('This Week',
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatDuration(report.totalScreenTimeMinutes),
                        style: AppTextStyles.metricMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last Week',
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatDuration(report.lastWeekScreenTimeMinutes),
                        style: AppTextStyles.metricMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: changeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(changeIcon, color: changeColor, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${isImproved ? "" : "+"}$changeText%',
                    style: AppTextStyles.metricSmall
                        .copyWith(color: changeColor),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isImproved ? 'Less than last week' : 'More than last week',
                    style: AppTextStyles.bodySmall.copyWith(color: changeColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppsCard(WeeklyReport report) {
    if (report.topApps.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Top Apps', style: AppTextStyles.headingSmall),
              const SizedBox(height: AppSpacing.lg),
              Text('No app usage data this week.',
                  style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      );
    }

    final maxDuration = report.topApps.first.durationMinutes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top 5 Apps', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.lg),
            ...report.topApps.asMap().entries.map((entry) {
              final index = entry.key;
              final app = entry.value;
              final barWidth =
                  maxDuration > 0 ? app.durationMinutes / maxDuration : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${index + 1}. ${app.appName}',
                            style: AppTextStyles.bodyLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDuration(app.durationMinutes),
                          style: AppTextStyles.metricSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm / 2),
                      child: LinearProgressIndicator(
                        value: barWidth,
                        backgroundColor: AppColors.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _appBarColor(index),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard(WeeklyReport report) {
    final trendIcon = switch (report.healthScoreTrend) {
      ScoreTrend.up => Icons.trending_up,
      ScoreTrend.down => Icons.trending_down,
      ScoreTrend.stable => Icons.trending_flat,
    };
    final trendColor = switch (report.healthScoreTrend) {
      ScoreTrend.up => AppColors.secondary,
      ScoreTrend.down => AppColors.error,
      ScoreTrend.stable => AppColors.textSecondary,
    };
    final trendLabel = switch (report.healthScoreTrend) {
      ScoreTrend.up => 'Improving',
      ScoreTrend.down => 'Declining',
      ScoreTrend.stable => 'Stable',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Health Score', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(
                  '${report.healthScoreAverage}',
                  style: AppTextStyles.metricLarge.copyWith(
                    color: _scoreColor(report.healthScoreAverage),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text('/100',
                    style: AppTextStyles.metricSmall
                        .copyWith(color: AppColors.textHint)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, color: trendColor, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text(trendLabel,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: trendColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Average score this week',
                style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildIntentionCard(WeeklyReport report) {
    final total = report.intentionBreakdown.values.fold(0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Intentions', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.lg),
            if (total == 0)
              Text('No intention data this week.',
                  style: AppTextStyles.bodyMedium)
            else
              ...report.intentionBreakdown.entries.map((entry) {
                final label = _intentionLabel(entry.key);
                final count = entry.value;
                final percent = total > 0 ? (count / total * 100) : 0.0;
                final color = _intentionColor(entry.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(label, style: AppTextStyles.bodyLarge),
                      ),
                      Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: AppTextStyles.metricSmall,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '($count)',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalCard(WeeklyReport report) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: const BorderSide(color: AppColors.secondary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome,
                color: AppColors.secondary, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                report.motivationalMessage,
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(WeeklyReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text('Tip for This Week',
                    style: AppTextStyles.headingSmall
                        .copyWith(fontSize: 18)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(report.weeklyTip, style: AppTextStyles.bodyLarge),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  Color _appBarColor(int index) {
    const colors = [
      AppColors.primary,
      AppColors.secondary,
      Color(0xFFFF8C42),
      Color(0xFFE040FB),
      Color(0xFF40C4FF),
    ];
    return colors[index % colors.length];
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.secondary;
    if (score >= 50) return const Color(0xFFFFB74D);
    return AppColors.error;
  }

  String _intentionLabel(IntentionType type) {
    return switch (type) {
      IntentionType.work => 'Work',
      IntentionType.social => 'Social',
      IntentionType.boredom => 'Boredom',
      IntentionType.justChecking => 'Just Checking',
    };
  }

  Color _intentionColor(IntentionType type) {
    return switch (type) {
      IntentionType.work => AppColors.primary,
      IntentionType.social => AppColors.secondary,
      IntentionType.boredom => AppColors.error,
      IntentionType.justChecking => const Color(0xFFFFB74D),
    };
  }
}
