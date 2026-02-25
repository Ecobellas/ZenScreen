import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Per-app detail screen (route: /statistics/app/:id).
///
/// Shows app usage chart, intention breakdown, friction stats.
class AppDetailScreen extends ConsumerWidget {
  final String appPackage;

  const AppDetailScreen({super.key, required this.appPackage});

  String _friendlyAppName(String packageName) {
    final parts = packageName.split('.');
    if (parts.length > 1) {
      final name = parts.last;
      return name[0].toUpperCase() + name.substring(1);
    }
    return packageName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final appName = _friendlyAppName(Uri.decodeComponent(appPackage));
    final decodedPackage = Uri.decodeComponent(appPackage);

    return Scaffold(
      appBar: AppBar(
        title: Text(appName, style: AppTextStyles.headingMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<_AppDetailData>(
        future: _loadAppData(db, decodedPackage),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? _AppDetailData.empty();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Usage chart (7-day bar chart).
                _buildUsageChart(data.dailyUsage),

                const SizedBox(height: AppSpacing.xxl),

                // Stats row.
                Row(
                  children: [
                    _StatCard(
                      label: 'Opens',
                      value: '${data.totalOpens}',
                      icon: Icons.touch_app_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _StatCard(
                      label: 'Friction',
                      value: '${data.frictionCount}',
                      icon: Icons.shield_outlined,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _StatCard(
                      label: 'Bypassed',
                      value: '${data.bypassCount}',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.error,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Intention breakdown for this app.
                _buildIntentionSection(data.intentionCounts),

                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsageChart(List<_DailyUsage> usage) {
    final maxMinutes = usage.isEmpty
        ? 60
        : usage.map((u) => u.minutes).reduce((a, b) => a > b ? a : b);
    final maxY = ((maxMinutes / 60) + 1).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Usage (Last 7 Days)', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 180,
            child: usage.isEmpty
                ? Center(
                    child: Text('No usage data',
                        style: AppTextStyles.bodyMedium),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surface,
                          getTooltipItem:
                              (group, groupIndex, rod, rodIndex) {
                            final m = (rod.toY * 60).round();
                            final h = m ~/ 60;
                            final min = m % 60;
                            return BarTooltipItem(
                              h > 0 ? '${h}h ${min}m' : '${min}m',
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
                              if (value == 0) {
                                return const SizedBox.shrink();
                              }
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
                              if (idx < 0 || idx >= usage.length) {
                                return const SizedBox.shrink();
                              }
                              const days = [
                                'Mon', 'Tue', 'Wed', 'Thu',
                                'Fri', 'Sat', 'Sun',
                              ];
                              return Text(
                                days[usage[idx].date.weekday - 1],
                                style: AppTextStyles.bodySmall,
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
                      barGroups: usage.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.minutes / 60,
                              width: 16,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.primary
                                      .withValues(alpha: 0.6),
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

  Widget _buildIntentionSection(Map<IntentionType, int> counts) {
    final total = counts.values.fold(0, (a, b) => a + b);

    const intentionColors = {
      IntentionType.work: Color(0xFF4A9DFF),
      IntentionType.social: Color(0xFF00D9A3),
      IntentionType.boredom: Color(0xFFFFAA33),
      IntentionType.justChecking: Color(0xFF9B59FF),
    };

    const intentionLabels = {
      IntentionType.work: 'Work',
      IntentionType.social: 'Social',
      IntentionType.boredom: 'Boredom',
      IntentionType.justChecking: 'Just Checking',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Intentions', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.lg),
          if (total == 0)
            Center(
              child: Text(
                'No intentions logged for this app',
                style: AppTextStyles.bodyMedium,
              ),
            )
          else
            ...IntentionType.values.map((type) {
              final count = counts[type] ?? 0;
              final pct = total > 0 ? (count / total) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: intentionColors[type],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                intentionLabels[type]!,
                                style: AppTextStyles.bodyMedium,
                              ),
                              Text(
                                '$count (${(pct * 100).round()}%)',
                                style: AppTextStyles.metricSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: AppColors.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                intentionColors[type]!,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<_AppDetailData> _loadAppData(
      DatabaseHelper db, String packageName) async {
    final database = await db.database;
    final now = DateTime.now();

    // 7-day usage data.
    final dailyUsage = <_DailyUsage>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final dateStr = date.toIso8601String().substring(0, 10);
      final rows = await database.rawQuery(
        'SELECT SUM(duration_seconds) as total FROM friction_events '
        'WHERE app_package = ? AND timestamp LIKE ?',
        [packageName, '$dateStr%'],
      );
      final totalSeconds = rows.isNotEmpty
          ? (rows.first['total'] as int? ?? 0)
          : 0;
      dailyUsage.add(_DailyUsage(
        date: date,
        minutes: totalSeconds ~/ 60,
      ));
    }

    // Total opens.
    final openRows = await database.rawQuery(
      'SELECT COUNT(*) as count FROM friction_events '
      'WHERE app_package = ?',
      [packageName],
    );
    final totalOpens =
        openRows.isNotEmpty ? (openRows.first['count'] as int? ?? 0) : 0;

    // Friction and bypass counts.
    // user_action 0 = gaveUp (dismissed), 1 = proceededAnyway (bypass).
    final frictionRows = await database.rawQuery(
      'SELECT user_action, COUNT(*) as count FROM friction_events '
      'WHERE app_package = ? GROUP BY user_action',
      [packageName],
    );
    int frictionCount = 0;
    int bypassCount = 0;
    for (final row in frictionRows) {
      final action = row['user_action'] as int? ?? 0;
      final count = row['count'] as int? ?? 0;
      if (action == 0) {
        frictionCount += count;
      } else {
        bypassCount += count;
      }
    }

    // Intention counts.
    final intentionRows = await database.rawQuery(
      'SELECT intention_type, COUNT(*) as count FROM intention_logs '
      'WHERE app_package = ? GROUP BY intention_type',
      [packageName],
    );
    final intentionCounts = <IntentionType, int>{
      for (final type in IntentionType.values) type: 0,
    };
    for (final row in intentionRows) {
      final typeIdx = row['intention_type'] as int? ?? 0;
      if (typeIdx < IntentionType.values.length) {
        intentionCounts[IntentionType.values[typeIdx]] =
            row['count'] as int? ?? 0;
      }
    }

    return _AppDetailData(
      dailyUsage: dailyUsage,
      totalOpens: totalOpens,
      frictionCount: frictionCount,
      bypassCount: bypassCount,
      intentionCounts: intentionCounts,
    );
  }
}

class _AppDetailData {
  final List<_DailyUsage> dailyUsage;
  final int totalOpens;
  final int frictionCount;
  final int bypassCount;
  final Map<IntentionType, int> intentionCounts;

  const _AppDetailData({
    required this.dailyUsage,
    required this.totalOpens,
    required this.frictionCount,
    required this.bypassCount,
    required this.intentionCounts,
  });

  factory _AppDetailData.empty() => _AppDetailData(
        dailyUsage: [],
        totalOpens: 0,
        frictionCount: 0,
        bypassCount: 0,
        intentionCounts: {
          for (final type in IntentionType.values) type: 0,
        },
      );
}

class _DailyUsage {
  final DateTime date;
  final int minutes;
  const _DailyUsage({required this.date, required this.minutes});
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: AppTextStyles.metricMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
