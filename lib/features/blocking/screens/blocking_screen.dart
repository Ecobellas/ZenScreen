import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/app_group.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/app_group_provider.dart';
import '../providers/blocking_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/strict_mode_provider.dart';

/// Main blocking management screen (BLCK-05).
///
/// Shows all app groups with their schedules and limits, plus a toggle
/// for Strict Mode and a FAB to add new groups.
class BlockingScreen extends ConsumerWidget {
  const BlockingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(appGroupProvider);
    final blockingState = ref.watch(blockingProvider);
    final strictState = ref.watch(strictModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Blocking', style: AppTextStyles.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: groupState.isLoading || blockingState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              children: [
                // Strict Mode toggle card.
                _StrictModeCard(
                  isActive: strictState.config.isCurrentlyActive(),
                  onTap: () => context.go('/settings/strict-mode'),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Quick links row.
                Row(
                  children: [
                    Expanded(
                      child: _QuickLinkCard(
                        icon: Icons.schedule,
                        label: 'Time Profiles',
                        onTap: () => context.go('/settings/profiles'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickLinkCard(
                        icon: Icons.shield,
                        label: 'Strict Mode',
                        onTap: () => context.go('/settings/strict-mode'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Section header.
                Text('App Groups', style: AppTextStyles.headingSmall),
                const SizedBox(height: AppSpacing.lg),

                // App group cards.
                ...groupState.groups.map((group) {
                  final appCount =
                      groupState.groupApps[group.id]?.length ?? 0;
                  final schedules = ref
                      .read(scheduleProvider.notifier)
                      .getSchedulesForGroup(group.id ?? -1);
                  final limit = ref
                      .read(blockingProvider.notifier)
                      .getDailyLimit(group.id ?? -1);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _AppGroupCard(
                      group: group,
                      appCount: appCount,
                      activeSchedules: schedules.length,
                      dailyLimit: limit?.limitMinutes,
                      onTap: () => context
                          .go('/settings/blocking/group/${group.id ?? 0}'),
                      onDelete: () => _confirmDelete(context, ref, group),
                    ),
                  );
                }),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showCreateGroupDialog(context, ref),
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AppGroup group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Group', style: AppTextStyles.headingSmall),
        content: Text(
          'Delete "${group.name}" and all its settings?',
          style: AppTextStyles.bodyLarge,
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
              if (group.id != null) {
                ref.read(appGroupProvider.notifier).deleteGroup(group.id!);
              }
              Navigator.pop(ctx);
            },
            child: Text('Delete',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('New App Group', style: AppTextStyles.headingSmall),
        content: TextField(
          controller: nameController,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Group name',
            hintStyle: AppTextStyles.bodyMedium,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
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
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await ref
                    .read(appGroupProvider.notifier)
                    .createGroup(name: name);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text('Create',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

/// Strict Mode status card at the top.
class _StrictModeCard extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _StrictModeCard({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.error.withValues(alpha: 0.15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: isActive
              ? Border.all(color: AppColors.error.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.shield : Icons.shield_outlined,
              color: isActive ? AppColors.error : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Strict Mode',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isActive
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isActive
                        ? 'Active - Apps are locked'
                        : 'Inactive - Tap to configure',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick-link card for navigating to profiles and strict mode.
class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// App group card showing group info and controls.
class _AppGroupCard extends StatelessWidget {
  final AppGroup group;
  final int appCount;
  final int activeSchedules;
  final int? dailyLimit;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AppGroupCard({
    required this.group,
    required this.appCount,
    required this.activeSchedules,
    this.dailyLimit,
    required this.onTap,
    required this.onDelete,
  });

  Color get _borderColor => switch (group.frictionType) {
        FrictionType.wait => AppColors.primary,
        FrictionType.breath => AppColors.secondary,
        FrictionType.intention => const Color(0xFFFFB84D),
      };

  IconData get _groupIcon {
    switch (group.icon) {
      case 'people':
        return Icons.people;
      case 'play_circle':
        return Icons.play_circle;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'newspaper':
        return Icons.newspaper;
      default:
        return Icons.apps;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border(
            left: BorderSide(color: _borderColor, width: 3),
          ),
        ),
        child: Row(
          children: [
            Icon(_groupIcon, color: _borderColor, size: 28),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$appCount apps  |  $activeSchedules schedules'
                    '${dailyLimit != null ? '  |  ${dailyLimit}min/day' : ''}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.textHint, size: 20),
              onPressed: onDelete,
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
