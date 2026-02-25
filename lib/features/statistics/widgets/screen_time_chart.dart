import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../analytics/providers/statistics_provider.dart';

/// Time range for screen time chart display.
enum ScreenTimeRange { daily, weekly, monthly }

/// fl_chart BarChart for screen time (STAT-01).
///
/// Toggles between Daily (7 days), Weekly (4 weeks), and Monthly (30 days).
class ScreenTimeChart extends StatefulWidget {
  final List<ScreenTimeEntry> weeklyData;
  final List<ScreenTimeEntry> monthlyData;

  const ScreenTimeChart({
    super.key,
    required this.weeklyData,
    required this.monthlyData,
  });

  @override
  State<ScreenTimeChart> createState() => _ScreenTimeChartState();
}

class _ScreenTimeChartState extends State<ScreenTimeChart> {
  ScreenTimeRange _range = ScreenTimeRange.daily;

  List<ScreenTimeEntry> get _data {
    switch (_range) {
      case ScreenTimeRange.daily:
        return widget.weeklyData;
      case ScreenTimeRange.weekly:
        // Aggregate monthly data into 4 weeks.
        return _aggregateToWeeks(widget.monthlyData);
      case ScreenTimeRange.monthly:
        return widget.monthlyData;
    }
  }

  List<ScreenTimeEntry> _aggregateToWeeks(List<ScreenTimeEntry> data) {
    if (data.isEmpty) return [];
    final weeks = <ScreenTimeEntry>[];
    for (int i = 0; i < data.length; i += 7) {
      final chunk = data.skip(i).take(7).toList();
      final totalMinutes = chunk.fold<int>(
        0,
        (sum, e) => sum + e.duration.inMinutes,
      );
      weeks.add(ScreenTimeEntry(
        date: chunk.first.date,
        duration: Duration(minutes: totalMinutes),
      ));
    }
    return weeks;
  }

  double get _maxHours {
    if (_data.isEmpty) return 4;
    final maxMinutes = _data
        .map((e) => e.duration.inMinutes)
        .reduce((a, b) => a > b ? a : b);
    return ((maxMinutes / 60) + 1).ceilToDouble();
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
              Text('Screen Time', style: AppTextStyles.headingSmall),
              _buildToggle(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: _data.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _maxHours,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surface,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final minutes =
                                (rod.toY * 60).round();
                            final h = minutes ~/ 60;
                            final m = minutes % 60;
                            return BarTooltipItem(
                              h > 0 ? '${h}h ${m}m' : '${m}m',
                              AppTextStyles.metricSmall,
                            );
                          },
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
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                '${value.toInt()}h',
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
                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.xs),
                                child: Text(
                                  _getLabel(idx),
                                  style: AppTextStyles.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.divider,
                          strokeWidth: 0.5,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _data.asMap().entries.map((entry) {
                        final hours =
                            entry.value.duration.inMinutes / 60;
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: hours,
                              width: _range == ScreenTimeRange.monthly
                                  ? 6
                                  : 16,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.6),
                                  AppColors.primary,
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _getLabel(int index) {
    if (index >= _data.length) return '';
    final date = _data[index].date;
    switch (_range) {
      case ScreenTimeRange.daily:
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      case ScreenTimeRange.weekly:
        return 'W${index + 1}';
      case ScreenTimeRange.monthly:
        // Show every 5th day label.
        if (index % 5 == 0) {
          return '${date.day}';
        }
        return '';
    }
  }

  Widget _buildToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ScreenTimeRange.values.map((range) {
        final isSelected = _range == range;
        final label = switch (range) {
          ScreenTimeRange.daily => '7D',
          ScreenTimeRange.weekly => '4W',
          ScreenTimeRange.monthly => '30D',
        };
        return GestureDetector(
          onTap: () => setState(() => _range = range),
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
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
