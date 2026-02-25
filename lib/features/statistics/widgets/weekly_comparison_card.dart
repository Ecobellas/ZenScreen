import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../analytics/providers/statistics_provider.dart';

/// Shows this week vs last week comparison (STAT-04).
///
/// Displays two side-by-side values with percentage change indicator.
class WeeklyComparisonCard extends StatelessWidget {
  final WeeklyComparison comparison;

  const WeeklyComparisonCard({super.key, required this.comparison});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final isImproved = comparison.percentChange <= 0;
    final changeColor = isImproved ? AppColors.secondary : AppColors.error;
    final changeIcon = isImproved ? Icons.arrow_downward : Icons.arrow_upward;
    final changeText =
        '${comparison.percentChange.abs().toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Comparison', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              // This week.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'This Week',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formatDuration(comparison.thisWeekTotal),
                      style: AppTextStyles.metricMedium,
                    ),
                  ],
                ),
              ),
              // Change indicator.
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
                    Icon(changeIcon, color: changeColor, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      changeText,
                      style: AppTextStyles.metricSmall.copyWith(
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Last week.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Last Week',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formatDuration(comparison.lastWeekTotal),
                      style: AppTextStyles.metricMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
