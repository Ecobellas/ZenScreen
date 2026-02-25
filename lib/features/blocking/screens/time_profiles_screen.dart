import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/time_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/app_group_provider.dart';
import '../providers/time_profile_provider.dart';

/// Time profiles management screen (BLCK-06).
///
/// Shows preset profiles (Work, Night, Weekend) with toggles
/// and allows creating custom profiles.
class TimeProfilesScreen extends ConsumerWidget {
  const TimeProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(timeProfileProvider);
    final groupState = ref.watch(appGroupProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Time Profiles', style: AppTextStyles.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              children: [
                Text(
                  'Activate a profile to automatically block app groups '
                  'during scheduled times.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Profile cards.
                ...profileState.profiles.map((profile) {
                  final isActive =
                      profileState.activeProfileId == profile.id;
                  final blockedGroupIds =
                      profileState.profileBlockedGroups[profile.id] ?? [];
                  final blockedGroupNames = blockedGroupIds
                      .map((gid) {
                        final group = groupState.groups
                            .where((g) => g.id == gid)
                            .firstOrNull;
                        return group?.name ?? 'Unknown';
                      })
                      .toList();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ProfileCard(
                      profile: profile,
                      isActive: isActive,
                      blockedGroupNames: blockedGroupNames,
                      onToggle: () {
                        if (isActive) {
                          ref
                              .read(timeProfileProvider.notifier)
                              .deactivateProfile();
                        } else if (profile.id != null) {
                          ref
                              .read(timeProfileProvider.notifier)
                              .activateProfile(profile.id!);
                        }
                      },
                      onEdit: () =>
                          _showEditProfileDialog(context, ref, profile),
                      onDelete: profile.name == 'Work' ||
                              profile.name == 'Night' ||
                              profile.name == 'Weekend'
                          ? null // Can't delete presets.
                          : () {
                              if (profile.id != null) {
                                ref
                                    .read(timeProfileProvider.notifier)
                                    .deleteProfile(profile.id!);
                              }
                            },
                    ),
                  );
                }),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showCreateProfileDialog(context, ref),
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
    );
  }

  void _showCreateProfileDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
    List<int> selectedDays = [1, 2, 3, 4, 5, 6, 7];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('New Profile', style: AppTextStyles.headingSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Profile name',
                    hintStyle: AppTextStyles.bodyMedium,
                  ),
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
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  ref.read(timeProfileProvider.notifier).createProfile(
                        name: name,
                        startTime: startTime,
                        endTime: endTime,
                        activeDays: selectedDays,
                      );
                  Navigator.pop(ctx);
                }
              },
              child: Text('Create',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, WidgetRef ref, TimeProfile profile) {
    final groupState = ref.read(appGroupProvider);
    final currentBlockedIds =
        ref.read(timeProfileProvider).profileBlockedGroups[profile.id] ?? [];
    List<int> selectedGroupIds = List<int>.from(currentBlockedIds);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Edit "${profile.name}"',
              style: AppTextStyles.headingSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Blocked Groups', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                ...groupState.groups.map((group) {
                  final isSelected =
                      group.id != null && selectedGroupIds.contains(group.id);
                  return CheckboxListTile(
                    title: Text(group.name, style: AppTextStyles.bodyLarge),
                    value: isSelected,
                    activeColor: AppColors.primary,
                    checkColor: AppColors.textPrimary,
                    onChanged: (v) {
                      setDialogState(() {
                        if (v == true && group.id != null) {
                          selectedGroupIds.add(group.id!);
                        } else if (group.id != null) {
                          selectedGroupIds.remove(group.id!);
                        }
                      });
                    },
                  );
                }),
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
                if (profile.id != null) {
                  ref.read(timeProfileProvider.notifier).updateProfile(
                        profile.id!,
                        blockedGroupIds: selectedGroupIds,
                      );
                }
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

class _ProfileCard extends StatelessWidget {
  final TimeProfile profile;
  final bool isActive;
  final List<String> blockedGroupNames;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.blockedGroupNames,
    required this.onToggle,
    required this.onEdit,
    this.onDelete,
  });

  IconData get _profileIcon {
    switch (profile.name) {
      case 'Work':
        return Icons.work;
      case 'Night':
        return Icons.nightlight_round;
      case 'Weekend':
        return Icons.weekend;
      default:
        return Icons.schedule;
    }
  }

  Color get _profileColor {
    switch (profile.name) {
      case 'Work':
        return AppColors.primary;
      case 'Night':
        return const Color(0xFF9C27B0);
      case 'Weekend':
        return AppColors.secondary;
      default:
        return const Color(0xFFFFB84D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startH = profile.startTime.hour.toString().padLeft(2, '0');
    final startM = profile.startTime.minute.toString().padLeft(2, '0');
    final endH = profile.endTime.hour.toString().padLeft(2, '0');
    final endM = profile.endTime.minute.toString().padLeft(2, '0');
    final timeStr = '$startH:$startM - $endH:$endM';

    final daysStr = profile.activeDays.length == 7
        ? 'Every day'
        : profile.activeDays
            .map((d) =>
                const ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d])
            .join(', ');

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isActive
              ? _profileColor.withValues(alpha: 0.1)
              : AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: isActive
              ? Border.all(color: _profileColor.withValues(alpha: 0.4))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_profileIcon, color: _profileColor, size: 24),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(profile.name, style: AppTextStyles.labelLarge),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.textHint, size: 20),
                    onPressed: onDelete,
                  ),
                Switch(
                  value: isActive,
                  activeColor: _profileColor,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.access_time,
                    color: AppColors.textHint, size: 14),
                const SizedBox(width: AppSpacing.xs),
                Text(timeStr, style: AppTextStyles.bodySmall),
                const SizedBox(width: AppSpacing.lg),
                Icon(Icons.calendar_today,
                    color: AppColors.textHint, size: 14),
                const SizedBox(width: AppSpacing.xs),
                Text(daysStr, style: AppTextStyles.bodySmall),
              ],
            ),
            if (blockedGroupNames.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                children: blockedGroupNames
                    .map((name) => Chip(
                          label: Text(name,
                              style: AppTextStyles.bodySmall
                                  .copyWith(fontSize: 10)),
                          backgroundColor: AppColors.surface,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
            if (profile.isStrictMode) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.shield, color: AppColors.error, size: 14),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Strict Mode',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error)),
                ],
              ),
            ],
          ],
        ),
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
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
