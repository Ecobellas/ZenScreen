import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // App icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: const Icon(
              Icons.spa_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          // Title
          Text(
            'Reclaim Your Time',
            style: AppTextStyles.headingLarge.copyWith(fontSize: 36),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Master your digital habits with conscious design.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.huge),
          // Value propositions
          _ValueProp(
            icon: Icons.timer_outlined,
            text: 'Track and understand your habits',
          ),
          const SizedBox(height: AppSpacing.lg),
          _ValueProp(
            icon: Icons.shield_outlined,
            text: 'Gentle friction to break the cycle',
          ),
          const SizedBox(height: AppSpacing.lg),
          _ValueProp(
            icon: Icons.insights_outlined,
            text: 'Build healthier digital habits',
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _ValueProp extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ValueProp({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 20),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(text, style: AppTextStyles.bodyLarge),
        ),
      ],
    );
  }
}
