import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/strict_mode_provider.dart';

/// Strict Mode configuration screen (STRK-01 to STRK-04).
///
/// Shows current status, activation toggle with irreversible warning,
/// recurring schedule setup, and emergency bypass explanation.
class StrictModeScreen extends ConsumerWidget {
  const StrictModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strictState = ref.watch(strictModeProvider);
    final config = strictState.config;
    final isActive = config.isCurrentlyActive();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Strict Mode', style: AppTextStyles.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: strictState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              children: [
                // Status card.
                _StatusCard(isActive: isActive),
                const SizedBox(height: AppSpacing.xxl),

                // Activation section.
                Text('Activation', style: AppTextStyles.headingSmall),
                const SizedBox(height: AppSpacing.md),
                if (!isActive)
                  _ActivateButton(
                    onActivate: () =>
                        _showActivationDialog(context, ref),
                  )
                else
                  _ActiveInfo(config: config),
                const SizedBox(height: AppSpacing.xxl),

                // Recurring schedule section.
                Text('Recurring Schedule', style: AppTextStyles.headingSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Set Strict Mode to activate automatically on specific '
                  'days and times (STRK-04).',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                _RecurringScheduleCard(
                  config: config,
                  onSetup: () => _showRecurringDialog(context, ref),
                  onRemove: () {
                    ref.read(strictModeProvider.notifier).removeSchedule();
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Emergency bypass info.
                Text('Emergency Bypass', style: AppTextStyles.headingSmall),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text('How it works',
                              style: AppTextStyles.labelLarge),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '1. When blocked, tap "Emergency Bypass"\n'
                        '2. Wait 60 seconds (no skipping)\n'
                        '3. Confirm: "Is this truly urgent?"\n'
                        '4. If confirmed, 5 minutes of access\n'
                        '5. Only 1 bypass per session',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showActivationDialog(BuildContext context, WidgetRef ref) {
    TimeOfDay endTime = const TimeOfDay(hour: 7, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Icon(Icons.warning, color: AppColors.error, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Activate Strict Mode',
                    style: AppTextStyles.headingSmall
                        .copyWith(color: AppColors.error)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'WARNING: This cannot be undone!\n\n'
                  'Blocked apps will be completely inaccessible '
                  'until the end time. Only an emergency bypass '
                  '(60s wait) can temporarily override it.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.error),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('End Time', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: endTime,
                  );
                  if (picked != null) {
                    setDialogState(() => endTime = picked);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      '${endTime.hour.toString().padLeft(2, '0')}:'
                      '${endTime.minute.toString().padLeft(2, '0')}',
                      style: AppTextStyles.metricMedium
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: () {
                ref.read(strictModeProvider.notifier).activateStrictMode(
                      endTime: endTime,
                    );
                Navigator.pop(ctx);
              },
              child: Text('Activate',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecurringDialog(BuildContext context, WidgetRef ref) {
    TimeOfDay startTime = const TimeOfDay(hour: 22, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 7, minute: 0);
    List<int> selectedDays = [1, 2, 3, 4, 5]; // Weeknights default.

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Recurring Schedule',
              style: AppTextStyles.headingSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strict Mode will activate automatically during these times.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                _DialogTimeRow(
                  label: 'Start',
                  time: startTime,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: startTime,
                    );
                    if (picked != null) {
                      setDialogState(() => startTime = picked);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _DialogTimeRow(
                  label: 'End',
                  time: endTime,
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: endTime,
                    );
                    if (picked != null) {
                      setDialogState(() => endTime = picked);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Days', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                _DayChips(
                  selectedDays: selectedDays,
                  onChanged: (days) =>
                      setDialogState(() => selectedDays = days),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                ref.read(strictModeProvider.notifier).scheduleRecurring(
                      days: selectedDays,
                      startTime: startTime,
                      endTime: endTime,
                    );
                Navigator.pop(ctx);
              },
              child: Text('Save',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _StatusCard extends StatelessWidget {
  final bool isActive;

  const _StatusCard({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.error.withValues(alpha: 0.15)
            : AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isActive
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.lock : Icons.lock_open,
            color: isActive ? AppColors.error : AppColors.secondary,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'ACTIVE' : 'INACTIVE',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: isActive ? AppColors.error : AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isActive
                      ? 'Blocked apps are completely locked'
                      : 'Apps are accessible with friction only',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivateButton extends StatelessWidget {
  final VoidCallback onActivate;

  const _ActivateButton({required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        icon: const Icon(Icons.shield, color: AppColors.textPrimary),
        label: Text('Activate Strict Mode',
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.textPrimary)),
        onPressed: onActivate,
      ),
    );
  }
}

class _ActiveInfo extends StatelessWidget {
  final dynamic config;

  const _ActiveInfo({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: AppColors.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Strict Mode is active and cannot be deactivated '
              'until the scheduled period ends.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringScheduleCard extends StatelessWidget {
  final dynamic config;
  final VoidCallback onSetup;
  final VoidCallback onRemove;

  const _RecurringScheduleCard({
    required this.config,
    required this.onSetup,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isScheduled = config.isScheduled == true;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isScheduled) ...[
            Row(
              children: [
                Icon(Icons.repeat, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text('Schedule active', style: AppTextStyles.labelLarge),
                const Spacer(),
                TextButton(
                  onPressed: onRemove,
                  child: Text('Remove',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${config.startTime.hour.toString().padLeft(2, '0')}:'
              '${config.startTime.minute.toString().padLeft(2, '0')} - '
              '${config.endTime.hour.toString().padLeft(2, '0')}:'
              '${config.endTime.minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.metricSmall,
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Icon(Icons.repeat,
                      color: AppColors.textHint, size: 32),
                  const SizedBox(height: AppSpacing.sm),
                  Text('No recurring schedule set',
                      style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: onSetup,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: const Text('Set Up Schedule'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DialogTimeRow extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _DialogTimeRow({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyLarge),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text('$h:$m',
                style: AppTextStyles.metricSmall
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _DayChips extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  const _DayChips({
    required this.selectedDays,
    required this.onChanged,
  });

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final day = i + 1;
        final selected = selectedDays.contains(day);
        return GestureDetector(
          onTap: () {
            final updated = List<int>.from(selectedDays);
            if (selected) {
              updated.remove(day);
            } else {
              updated.add(day);
              updated.sort();
            }
            onChanged(updated);
          },
          child: CircleAvatar(
            radius: 16,
            backgroundColor:
                selected ? AppColors.primary : AppColors.card,
            child: Text(
              _labels[i],
              style: AppTextStyles.bodySmall.copyWith(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textHint,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
