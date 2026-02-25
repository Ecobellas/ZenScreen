import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../friction/providers/friction_settings_provider.dart';
import '../../monetization/providers/premium_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final frictionSettings = ref.watch(frictionSettingsProvider);
    final premiumState = ref.watch(premiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.headingMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ---------------------------------------------------------------
          // General Section (STNG-01)
          // ---------------------------------------------------------------
          SettingsSection(
            title: 'General',
            children: [
              SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: settings.themeMode == ThemeMode.dark
                    ? 'Currently dark'
                    : 'Currently light',
                trailing: Switch(
                  value: settings.themeMode == ThemeMode.dark,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    ref.read(settingsProvider.notifier).setThemeMode(
                          v ? ThemeMode.dark : ThemeMode.light,
                        );
                  },
                ),
              ),
              SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: settings.notificationsEnabled
                    ? 'Enabled'
                    : 'Disabled',
                trailing: Switch(
                  value: settings.notificationsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    ref
                        .read(settingsProvider.notifier)
                        .setNotificationsEnabled(v);
                  },
                ),
              ),
              SettingsTile(
                icon: Icons.timer_outlined,
                title: 'Daily Screen Time Goal',
                subtitle: _formatGoal(settings.dailyGoalMinutes),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textHint),
                onTap: () => _showGoalPicker(context, ref, settings),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ---------------------------------------------------------------
          // Friction Section (STNG-02)
          // ---------------------------------------------------------------
          SettingsSection(
            title: 'Friction',
            children: [
              SettingsTile(
                icon: Icons.touch_app_outlined,
                title: 'Default Friction Type',
                subtitle: _frictionLabel(frictionSettings.defaultFrictionType),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textHint),
                onTap: () =>
                    _showFrictionTypePicker(context, ref, frictionSettings),
              ),
              SettingsTile(
                icon: Icons.replay_outlined,
                title: 'Grace Period',
                subtitle: '${frictionSettings.gracePeriodCount} free opens/day',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppColors.textSecondary, size: 20),
                      onPressed: frictionSettings.gracePeriodCount > 0
                          ? () {
                              ref
                                  .read(frictionSettingsProvider.notifier)
                                  .setGracePeriodCount(
                                      frictionSettings.gracePeriodCount - 1);
                            }
                          : null,
                    ),
                    Text(
                      '${frictionSettings.gracePeriodCount}',
                      style: AppTextStyles.metricSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: AppColors.textSecondary, size: 20),
                      onPressed: frictionSettings.gracePeriodCount < 10
                          ? () {
                              ref
                                  .read(frictionSettingsProvider.notifier)
                                  .setGracePeriodCount(
                                      frictionSettings.gracePeriodCount + 1);
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              SettingsTile(
                icon: Icons.trending_up_outlined,
                title: 'Escalation',
                subtitle: 'Increase timer on consecutive opens',
                trailing: Switch(
                  value: frictionSettings.escalationEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    ref
                        .read(frictionSettingsProvider.notifier)
                        .setEscalationEnabled(v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ---------------------------------------------------------------
          // Blocking Section (STNG-03)
          // ---------------------------------------------------------------
          SettingsSection(
            title: 'Blocking',
            children: [
              SettingsTile(
                icon: Icons.apps_outlined,
                title: 'Manage App Groups',
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textHint),
                onTap: () => context.go('/settings/blocking'),
              ),
              SettingsTile(
                icon: Icons.schedule_outlined,
                title: 'Time Profiles',
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textHint),
                onTap: () => context.go('/settings/profiles'),
              ),
              SettingsTile(
                icon: Icons.lock_outlined,
                title: 'Strict Mode',
                subtitle: 'Irreversible blocking',
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textHint),
                onTap: () => context.go('/settings/strict-mode'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ---------------------------------------------------------------
          // Data Section (STNG-05)
          // ---------------------------------------------------------------
          SettingsSection(
            title: 'Data',
            children: [
              SettingsTile(
                icon: Icons.file_download_outlined,
                title: 'Export Data (CSV)',
                subtitle: premiumState.isPremium ? null : 'Premium feature',
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textHint),
                onTap: () => _handleExport(context, ref),
              ),
              SettingsTile(
                icon: Icons.delete_outline,
                title: 'Reset All Data',
                subtitle: 'Clear all tracked data',
                isDestructive: true,
                onTap: () => _showResetDialog(context, ref),
              ),
              SettingsTile(
                icon: Icons.info_outline,
                title: 'About ZenScreen',
                subtitle: 'v1.0.0',
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textHint),
                onTap: () => _showAboutSheet(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ---------------------------------------------------------------
          // Account Section
          // ---------------------------------------------------------------
          SettingsSection(
            title: 'Account',
            children: [
              SettingsTile(
                icon: Icons.star_outlined,
                title: 'Premium',
                subtitle: premiumState.isPremium ? 'Active' : 'Free plan',
                iconColor:
                    premiumState.isPremium ? AppColors.secondary : null,
                trailing: premiumState.isPremium
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text('PRO',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.secondary)),
                      )
                    : const Icon(Icons.chevron_right,
                        color: AppColors.textHint),
                onTap: () => context.go('/settings/paywall'),
              ),
              SettingsTile(
                icon: Icons.restore_outlined,
                title: 'Restore Purchases',
                onTap: () => _handleRestore(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs and actions
  // ---------------------------------------------------------------------------

  void _showGoalPicker(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    double currentValue = settings.dailyGoalMinutes.toDouble();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              title: Text('Daily Screen Time Goal',
                  style: AppTextStyles.headingSmall),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatGoal(currentValue.round()),
                    style: AppTextStyles.metricMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Slider(
                    value: currentValue,
                    min: 30,
                    max: 360,
                    divisions: 22,
                    activeColor: AppColors.primary,
                    label: _formatGoal(currentValue.round()),
                    onChanged: (v) {
                      setDialogState(() => currentValue = v);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('30m', style: AppTextStyles.bodySmall),
                      Text('6h', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(settingsProvider.notifier)
                        .setDailyGoalMinutes(currentValue.round());
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFrictionTypePicker(
      BuildContext context, WidgetRef ref, FrictionSettings settings) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text('Default Friction Type',
              style: AppTextStyles.headingSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _frictionOption(
                ctx,
                ref,
                icon: Icons.hourglass_empty,
                label: 'Wait Timer',
                subtitle: 'Count down before proceeding',
                isSelected:
                    settings.defaultFrictionType == FrictionType.wait,
                onTap: () => _selectFriction(ctx, ref, FrictionType.wait),
              ),
              const SizedBox(height: AppSpacing.sm),
              _frictionOption(
                ctx,
                ref,
                icon: Icons.air,
                label: 'Breathing Exercise',
                subtitle: 'Guided breathing before proceeding',
                isSelected:
                    settings.defaultFrictionType == FrictionType.breath,
                isPremium: true,
                onTap: () =>
                    _selectFriction(ctx, ref, FrictionType.breath),
              ),
              const SizedBox(height: AppSpacing.sm),
              _frictionOption(
                ctx,
                ref,
                icon: Icons.edit_note,
                label: 'Intention Setting',
                subtitle: 'State your purpose before proceeding',
                isSelected:
                    settings.defaultFrictionType == FrictionType.intention,
                isPremium: true,
                onTap: () =>
                    _selectFriction(ctx, ref, FrictionType.intention),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _frictionOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    bool isPremium = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label, style: AppTextStyles.bodyLarge),
                      if (isPremium) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm / 2),
                          ),
                          child: Text('PRO',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.secondary,
                                  fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  void _selectFriction(
      BuildContext context, WidgetRef ref, FrictionType type) {
    Navigator.pop(context);
    // Premium gate for breath and intention (MNTZ-04).
    if (type != FrictionType.wait) {
      final premium = ref.read(premiumProvider);
      if (!premium.isPremium) {
        if (context.mounted) {
          GoRouter.of(context).go('/settings/paywall');
        }
        return;
      }
    }
    ref.read(frictionSettingsProvider.notifier).setDefaultFrictionType(type);
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text('Reset All Data',
              style: AppTextStyles.headingSmall
                  .copyWith(color: AppColors.error)),
          content: Text(
            'This will permanently delete all your tracked data, app groups, '
            'and settings. Your premium status will be preserved.\n\n'
            'This action cannot be undone.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(settingsProvider.notifier).resetAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data has been reset')),
                  );
                }
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    // Premium gate for CSV export (MNTZ-04).
    final premium = ref.read(premiumProvider);
    if (!premium.isPremium) {
      context.go('/settings/paywall');
      return;
    }

    try {
      final path =
          await ref.read(settingsProvider.notifier).exportDataAsCsv();
      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(path)],
          subject: 'ZenScreen Data Export',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(premiumProvider.notifier).restorePurchases();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  void _showAboutSheet(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text('About ZenScreen', style: AppTextStyles.headingSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version 1.0.0', style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'ZenScreen helps you build a healthier relationship with '
                'your phone through mindful friction and awareness.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Privacy Policy',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.primary)),
              const SizedBox(height: AppSpacing.sm),
              Text('Support: support@zenscreen.app',
                  style: AppTextStyles.bodyMedium),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatGoal(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String _frictionLabel(FrictionType type) {
    return switch (type) {
      FrictionType.wait => 'Wait Timer',
      FrictionType.breath => 'Breathing Exercise',
      FrictionType.intention => 'Intention Setting',
    };
  }
}
