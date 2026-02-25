import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/blocking_schedule.dart';
import '../providers/app_group_provider.dart';
import '../providers/blocking_provider.dart';
import '../providers/schedule_provider.dart';

/// Edit screen for an app group (BLCK-01, BLCK-02, BLCK-05).
///
/// Allows editing group name, managing apps, setting friction type,
/// configuring blocking schedules, and daily limits.
class GroupEditScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupEditScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends ConsumerState<GroupEditScreen> {
  late TextEditingController _nameController;
  FrictionType _selectedFriction = FrictionType.wait;
  double _dailyLimitSlider = 60;
  bool _hasLimit = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadGroupData();
  }

  void _loadGroupData() {
    final groupState = ref.read(appGroupProvider);
    final id = int.tryParse(widget.groupId);
    if (id == null) return;

    final group = groupState.groups
        .where((g) => g.id == id)
        .firstOrNull;

    if (group != null) {
      _nameController.text = group.name;
      _selectedFriction = group.frictionType;
      _dailyLimitSlider = group.dailyLimitMinutes.toDouble();
    }

    final limit = ref.read(blockingProvider.notifier).getDailyLimit(id);
    if (limit != null) {
      _hasLimit = limit.isActive;
      _dailyLimitSlider = limit.limitMinutes.toDouble();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(appGroupProvider);
    final scheduleState = ref.watch(scheduleProvider);
    final id = int.tryParse(widget.groupId);

    final group =
        id != null ? groupState.groups.where((g) => g.id == id).firstOrNull : null;
    final apps = id != null ? (groupState.groupApps[id] ?? []) : <BlockedAppEntry>[];
    final schedules = id != null
        ? scheduleState.schedules.where((s) => s.groupId == id).toList()
        : <BlockingSchedule>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          group?.name ?? 'Edit Group',
          style: AppTextStyles.headingMedium,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => _saveChanges(id),
            child: Text('Save',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        children: [
          // Group name field.
          _SectionHeader(title: 'Group Name'),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _nameController,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              hintText: 'Enter group name',
              hintStyle: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Apps in group.
          _SectionHeader(
            title: 'Apps (${apps.length})',
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.primary),
              onPressed: () => _showAddAppDialog(context, id),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (apps.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Text(
                  'No apps added yet.\nTap + to add apps.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            )
          else
            ...apps.map((app) => _AppTile(
                  appName: app.appName,
                  packageName: app.packageName,
                  onRemove: () {
                    if (id != null) {
                      ref.read(appGroupProvider.notifier).removeAppFromGroup(
                            groupId: id,
                            packageName: app.packageName,
                          );
                    }
                  },
                )),
          const SizedBox(height: AppSpacing.xxl),

          // Friction type selector.
          _SectionHeader(title: 'Friction Type'),
          const SizedBox(height: AppSpacing.sm),
          _FrictionTypeSelector(
            selected: _selectedFriction,
            onChanged: (type) => setState(() => _selectedFriction = type),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Blocking schedules.
          _SectionHeader(
            title: 'Blocking Schedules',
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.primary),
              onPressed: () => _showAddScheduleDialog(context, id),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (schedules.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Text(
                  'No schedules set',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            )
          else
            ...schedules.map((s) => _ScheduleTile(
                  schedule: s,
                  onToggle: () {
                    if (s.id != null) {
                      ref
                          .read(scheduleProvider.notifier)
                          .toggleSchedule(s.id!);
                    }
                  },
                  onDelete: () {
                    if (s.id != null) {
                      ref
                          .read(scheduleProvider.notifier)
                          .deleteSchedule(s.id!);
                    }
                  },
                )),
          const SizedBox(height: AppSpacing.xxl),

          // Daily limit.
          _SectionHeader(title: 'Daily Limit'),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Enable daily limit', style: AppTextStyles.bodyLarge),
                    Switch(
                      value: _hasLimit,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _hasLimit = v),
                    ),
                  ],
                ),
                if (_hasLimit) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Limit', style: AppTextStyles.bodyMedium),
                      Text(
                        '${_dailyLimitSlider.round()} min/day',
                        style: AppTextStyles.metricSmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  Slider(
                    value: _dailyLimitSlider,
                    min: 5,
                    max: 480,
                    divisions: 95,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.divider,
                    onChanged: (v) =>
                        setState(() => _dailyLimitSlider = v),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges(int? groupId) async {
    if (groupId == null) return;

    await ref.read(appGroupProvider.notifier).updateGroup(
          groupId,
          name: _nameController.text.trim(),
          frictionType: _selectedFriction,
          dailyLimitMinutes: _dailyLimitSlider.round(),
        );

    if (_hasLimit) {
      await ref.read(blockingProvider.notifier).setDailyLimit(
            groupId: groupId,
            limitMinutes: _dailyLimitSlider.round(),
          );
    } else {
      await ref.read(blockingProvider.notifier).removeDailyLimit(groupId);
    }

    if (mounted) context.pop();
  }

  void _showAddAppDialog(BuildContext context, int? groupId) {
    if (groupId == null) return;
    final packageController = TextEditingController();
    final appNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Add App', style: AppTextStyles.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: appNameController,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'App name (e.g., Instagram)',
                hintStyle: AppTextStyles.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: packageController,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Package (e.g., com.instagram.android)',
                hintStyle: AppTextStyles.bodyMedium,
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
          TextButton(
            onPressed: () {
              final pkg = packageController.text.trim();
              final name = appNameController.text.trim();
              if (pkg.isNotEmpty && name.isNotEmpty) {
                ref.read(appGroupProvider.notifier).addAppToGroup(
                      groupId: groupId,
                      packageName: pkg,
                      appName: name,
                    );
                Navigator.pop(ctx);
              }
            },
            child: Text('Add',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context, int? groupId) {
    if (groupId == null) return;

    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
    List<int> selectedDays = [1, 2, 3, 4, 5];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Add Schedule', style: AppTextStyles.headingSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start time.
              _TimePickerRow(
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
              // End time.
              _TimePickerRow(
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
              // Day selector.
              Text('Days', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              _DaySelector(
                selectedDays: selectedDays,
                onChanged: (days) =>
                    setDialogState(() => selectedDays = days),
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
            TextButton(
              onPressed: () {
                ref.read(scheduleProvider.notifier).createSchedule(
                      groupId: groupId,
                      startTime: startTime,
                      endTime: endTime,
                      daysOfWeek: selectedDays,
                    );
                Navigator.pop(ctx);
              },
              child: Text('Add',
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.labelLarge),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _AppTile extends StatelessWidget {
  final String appName;
  final String packageName;
  final VoidCallback onRemove;

  const _AppTile({
    required this.appName,
    required this.packageName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.apps, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appName, style: AppTextStyles.bodyLarge),
                Text(packageName, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: AppColors.error, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _FrictionTypeSelector extends StatelessWidget {
  final FrictionType selected;
  final ValueChanged<FrictionType> onChanged;

  const _FrictionTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: FrictionType.values.map((type) {
        final isSelected = type == selected;
        final label = switch (type) {
          FrictionType.wait => 'Wait',
          FrictionType.breath => 'Breathe',
          FrictionType.intention => 'Intention',
        };
        final color = switch (type) {
          FrictionType.wait => AppColors.primary,
          FrictionType.breath => AppColors.secondary,
          FrictionType.intention => const Color(0xFFFFB84D),
        };

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: Container(
              margin: EdgeInsets.only(
                right: type != FrictionType.intention ? AppSpacing.sm : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: isSelected
                    ? Border.all(color: color.withValues(alpha: 0.5))
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final BlockingSchedule schedule;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ScheduleTile({
    required this.schedule,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schedule.timeRangeString,
                    style: AppTextStyles.metricSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(schedule.daysString, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Switch(
            value: schedule.isActive,
            activeColor: AppColors.primary,
            onChanged: (_) => onToggle(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.textHint, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerRow({
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

class _DaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  const _DaySelector({
    required this.selectedDays,
    required this.onChanged,
  });

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final day = index + 1;
        final isSelected = selectedDays.contains(day);
        return GestureDetector(
          onTap: () {
            final updated = List<int>.from(selectedDays);
            if (isSelected) {
              updated.remove(day);
            } else {
              updated.add(day);
              updated.sort();
            }
            onChanged(updated);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primary : AppColors.card,
            ),
            child: Center(
              child: Text(
                _dayLabels[index],
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
