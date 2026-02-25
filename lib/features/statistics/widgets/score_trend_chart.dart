import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../analytics/providers/health_score_provider.dart';

/// fl_chart LineChart for health score trends (HLTH-03).
///
/// Toggles between 7-day and 30-day view.
/// Line color varies by score zones, with area fill below.
class ScoreTrendChart extends StatefulWidget {
  final List<DatedScore> weeklyScores;
  final List<DatedScore> monthlyScores;

  const ScoreTrendChart({
    super.key,
    required this.weeklyScores,
    required this.monthlyScores,
  });

  @override
  State<ScoreTrendChart> createState() => _ScoreTrendChartState();
}

class _ScoreTrendChartState extends State<ScoreTrendChart> {
  bool _showMonthly = false;

  List<DatedScore> get _data =>
      _showMonthly ? widget.monthlyScores : widget.weeklyScores;

  /// Returns color based on score zones.
  Color _colorForScore(int score) {
    if (score >= 80) return AppColors.secondary;
    if (score >= 50) return AppColors.primary;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Text('Health Score Trend', style: AppTextStyles.headingSmall),
              _buildToggle(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: _data.isEmpty
                ? Center(
                    child: Text(
                      'No score data available',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surface,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${spot.y.toInt()}',
                                AppTextStyles.metricSmall.copyWith(
                                  color: _colorForScore(spot.y.toInt()),
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25,
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
                            reservedSize: 30,
                            interval: 25,
                            getTitlesWidget: (value, meta) {
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
                              if (idx < 0 || idx >= _data.length) {
                                return const SizedBox.shrink();
                              }
                              if (_showMonthly) {
                                // Show every 7th day.
                                if (idx % 7 != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  '${_data[idx].date.day}',
                                  style: AppTextStyles.bodySmall,
                                );
                              } else {
                                const days = [
                                  'M', 'T', 'W', 'T', 'F', 'S', 'S',
                                ];
                                return Text(
                                  days[_data[idx].date.weekday - 1],
                                  style: AppTextStyles.bodySmall,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _data.asMap().entries.map((e) {
                            return FlSpot(
                              e.key.toDouble(),
                              e.value.score.toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: AppColors.primary,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, ___) {
                              final color =
                                  _colorForScore(spot.y.toInt());
                              return FlDotCirclePainter(
                                radius: 4,
                                color: color,
                                strokeWidth: 1.5,
                                strokeColor:
                                    AppColors.card,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.25),
                                AppColors.primary.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleChip(
          label: '7D',
          isSelected: !_showMonthly,
          onTap: () => setState(() => _showMonthly = false),
        ),
        const SizedBox(width: AppSpacing.xs),
        _ToggleChip(
          label: '30D',
          isSelected: _showMonthly,
          onTap: () => setState(() => _showMonthly = true),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
