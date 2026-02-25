import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../analytics/providers/statistics_provider.dart';

/// Per-app usage breakdown with horizontal bars (STAT-02).
///
/// Tapping an app navigates to /statistics/app/:id.
class AppUsageBars extends StatelessWidget {
  final List<AppUsageEntry> apps;

  const AppUsageBars({super.key, required this.apps});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            'No app usage data available',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    final maxMinutes = apps
        .map((a) => a.duration.inMinutes)
        .reduce((a, b) => a > b ? a : b);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: apps.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final app = apps[index];
        final progress =
            maxMinutes > 0 ? app.duration.inMinutes / maxMinutes : 0.0;

        return GestureDetector(
          onTap: () {
            final encodedId = Uri.encodeComponent(app.appPackage);
            context.go('/statistics/app/$encodedId');
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDuration(app.duration),
                          style: AppTextStyles.metricSmall,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textHint,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${app.openCount} opens',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
