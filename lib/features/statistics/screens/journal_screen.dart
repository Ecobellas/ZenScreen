import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/intention_log.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../analytics/providers/intention_journal_provider.dart';
import '../widgets/intention_pie_chart.dart';
import '../widgets/intention_trend_chart.dart';

/// Intention journal detail screen (route: /statistics/journal).
///
/// Shows pie chart, trend chart, insight text, and a filterable list of logs.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  IntentionType? _filterType;

  static const _intentionLabels = {
    IntentionType.work: 'Work',
    IntentionType.social: 'Social',
    IntentionType.boredom: 'Boredom',
    IntentionType.justChecking: 'Just Checking',
  };

  static const _intentionColors = {
    IntentionType.work: Color(0xFF4A9DFF),
    IntentionType.social: Color(0xFF00D9A3),
    IntentionType.boredom: Color(0xFFFFAA33),
    IntentionType.justChecking: Color(0xFF9B59FF),
  };

  @override
  Widget build(BuildContext context) {
    final breakdown = ref.watch(todayIntentionBreakdownProvider);
    final trends = ref.watch(weeklyIntentionTrendsProvider);
    final insight = ref.watch(intentionInsightProvider);
    final logs = ref.watch(recentIntentionLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Intention Journal', style: AppTextStyles.headingMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),

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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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

            const SizedBox(height: AppSpacing.xxl),

            // Filter chips.
            Text('Recent Logs', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _filterType == null,
                    onTap: () => setState(() => _filterType = null),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ...IntentionType.values.map((type) => Padding(
                        padding:
                            const EdgeInsets.only(right: AppSpacing.sm),
                        child: _FilterChip(
                          label: _intentionLabels[type]!,
                          color: _intentionColors[type],
                          isSelected: _filterType == type,
                          onTap: () =>
                              setState(() => _filterType = type),
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Logs list.
            logs.when(
              data: (allLogs) {
                final filtered = _filterType == null
                    ? allLogs
                    : allLogs
                        .where((l) => l.intention == _filterType)
                        .toList();

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Center(
                      child: Text(
                        'No intention logs found',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _LogEntry(log: filtered[index]),
                );
              },
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.primary)
              : AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: isSelected
              ? null
              : Border.all(color: AppColors.divider),
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
  }
}

class _LogEntry extends StatelessWidget {
  final IntentionLog log;

  const _LogEntry({required this.log});

  static const _intentionLabels = {
    IntentionType.work: 'Work',
    IntentionType.social: 'Social',
    IntentionType.boredom: 'Boredom',
    IntentionType.justChecking: 'Just Checking',
  };

  static const _intentionColors = {
    IntentionType.work: Color(0xFF4A9DFF),
    IntentionType.social: Color(0xFF00D9A3),
    IntentionType.boredom: Color(0xFFFFAA33),
    IntentionType.justChecking: Color(0xFF9B59FF),
  };

  String _friendlyAppName(String packageName) {
    final parts = packageName.split('.');
    if (parts.length > 1) {
      final name = parts.last;
      return name[0].toUpperCase() + name.substring(1);
    }
    return packageName;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          // Intention color dot.
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _intentionColors[log.intention],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Details.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _friendlyAppName(log.appPackage),
                      style: AppTextStyles.bodyLarge,
                    ),
                    Text(
                      '${_formatDate(log.timestamp)} ${_formatTime(log.timestamp)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      _intentionLabels[log.intention] ?? '',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _intentionColors[log.intention],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      log.didProceed ? 'Proceeded' : 'Dismissed',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: log.didProceed
                            ? AppColors.error
                            : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
