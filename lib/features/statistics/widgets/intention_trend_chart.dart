import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../analytics/providers/intention_journal_provider.dart';

/// fl_chart LineChart for weekly intention trends (INTJ-03).
///
/// 4 colored lines, one per intention type.
class IntentionTrendChart extends StatelessWidget {
  final List<IntentionBreakdown> trends;

  const IntentionTrendChart({super.key, required this.trends});

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

  double get _maxY {
    double max = 5;
    for (final breakdown in trends) {
      for (final count in breakdown.counts.values) {
        if (count > max) max = count.toDouble();
      }
    }
    return max + 1;
  }

  @override
  Widget build(BuildContext context) {
    final hasData = trends.any((b) => b.total > 0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Trends', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: !hasData
                ? Center(
                    child: Text(
                      'No trend data available',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: _maxY,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surface,
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _maxY > 5 ? (_maxY / 5) : 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.divider,
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 25,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                '${value.toInt()}',
                                style: AppTextStyles.bodySmall,
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= trends.length) {
                                return const SizedBox.shrink();
                              }
                              const days = [
                                'Mon', 'Tue', 'Wed', 'Thu',
                                'Fri', 'Sat', 'Sun',
                              ];
                              final weekday =
                                  trends[idx].date.weekday;
                              return Text(
                                days[weekday - 1],
                                style: AppTextStyles.bodySmall,
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: IntentionType.values.map((type) {
                        return LineChartBarData(
                          spots: trends.asMap().entries.map((e) {
                            final count =
                                e.value.counts[type]?.toDouble() ?? 0;
                            return FlSpot(e.key.toDouble(), count);
                          }).toList(),
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: _intentionColors[type],
                          barWidth: 2,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (_, __, ___, ____) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: _intentionColors[type]!,
                                strokeWidth: 0,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(show: false),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Legend.
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: IntentionType.values.map((type) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 3,
                    color: _intentionColors[type],
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _intentionLabels[type]!,
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
