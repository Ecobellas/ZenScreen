import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';

class PermissionStep extends StatelessWidget {
  const PermissionStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.huge),
          Text(
            'ZenScreen needs your help',
            style: AppTextStyles.headingLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'We\'ll ask for these permissions next',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          const _PermissionCard(
            icon: Icons.bar_chart_rounded,
            title: 'Usage Access',
            description: 'To track which apps you use and for how long',
          ),
          const SizedBox(height: AppSpacing.md),
          const _PermissionCard(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            description:
                'To remind you about limits and send weekly reports',
          ),
          const SizedBox(height: AppSpacing.md),
          const _PermissionCard(
            icon: Icons.layers_outlined,
            title: 'Overlay',
            description:
                'To show mindful pauses when you open restricted apps',
          ),
          const Spacer(),
          Text(
            'Your data stays on your device. We never collect or share it.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
