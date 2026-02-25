import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../analytics/providers/intention_journal_provider.dart';

/// fl_chart PieChart for daily intention breakdown (INTJ-02).
///
/// 4 sections: Work (blue), Social (green), Boredom (orange), Just Checking (purple).
class IntentionPieChart extends StatelessWidget {
  final IntentionBreakdown breakdown;

  const IntentionPieChart({super.key, required this.breakdown});

  static const _intentionColors = {
    IntentionType.work: Color(0xFF4A9DFF),
    IntentionType.social: Color(0xFF00D9A3),
    IntentionType.boredom: Color(0xFFFFAA33),
    IntentionType.justChecking: Color(0xFF9B59FF),
  };

  static const _intentionLabels = {
    IntentionType.work: 'Work',
    IntentionType.social: 'Social',
    IntentionType.boredom: 'Boredom',
    IntentionType.justChecking: 'Just Checking',
  };

  @override
  Widget build(BuildContext context) {
    final total = breakdown.total;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Intention Breakdown', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.lg),
          if (total == 0)
            SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'No intentions logged today',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  sections: IntentionType.values.map((type) {
                    final count = breakdown.counts[type] ?? 0;
                    final percentage =
                        total > 0 ? (count / total) * 100 : 0.0;
                    return PieChartSectionData(
                      color: _intentionColors[type],
                      value: count.toDouble(),
                      title:
                          percentage >= 10 ? '${percentage.round()}%' : '',
                      titleStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      radius: 40,
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          // Center text showing total count.
          if (total > 0)
            Center(
              child: Text(
                '$total total',
                style: AppTextStyles.metricSmall,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          // Legend.
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: IntentionType.values.map((type) {
              final count = breakdown.counts[type] ?? 0;
              final pct = total > 0 ? ((count / total) * 100).round() : 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _intentionColors[type],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${_intentionLabels[type]} ($pct%)',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
