import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../analytics/providers/statistics_provider.dart';

/// Displays the top 3 most-used apps today with usage bars (DASH-04).
class TopAppsList extends StatelessWidget {
  final List<AppUsageEntry> apps;
  final int dailyGoalMinutes;

  const TopAppsList({
    super.key,
    required this.apps,
    required this.dailyGoalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Center(
          child: Text(
            'No app usage data today',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    // Find max duration for proportional bars.
    final maxDuration = apps
        .map((a) => a.duration.inMinutes)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Apps Today', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.lg),
          ...apps.map((app) => _AppUsageRow(
                app: app,
                maxMinutes: maxDuration > 0 ? maxDuration : 1,
                dailyGoalMinutes: dailyGoalMinutes,
              )),
        ],
      ),
    );
  }
}

class _AppUsageRow extends StatelessWidget {
  final AppUsageEntry app;
  final int maxMinutes;
  final int dailyGoalMinutes;

  const _AppUsageRow({
    required this.app,
    required this.maxMinutes,
    required this.dailyGoalMinutes,
  });

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final progress = app.duration.inMinutes / maxMinutes;
    // Color: error if approaching per-app limit (> 80% of daily goal / 3).
    final perAppLimit = dailyGoalMinutes / 3;
    final isHigh = app.duration.inMinutes > perAppLimit;

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
                  app.appName,
                  style: AppTextStyles.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDuration(app.duration),
                style: AppTextStyles.metricSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                isHigh ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
