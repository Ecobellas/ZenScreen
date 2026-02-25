import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../providers/onboarding_provider.dart';

class GoalStep extends ConsumerWidget {
  const GoalStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGoal = ref.watch(onboardingProvider).selectedGoal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.huge),
          Text(
            'What\'s your goal?',
            style: AppTextStyles.headingLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'We\'ll personalize your experience',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          _GoalCard(
            icon: Icons.timer_outlined,
            title: 'Reduce Screen Time',
            subtitle: 'Spend less time on your phone overall',
            isSelected: selectedGoal == GoalType.reduceTime,
            onTap: () => ref
                .read(onboardingProvider.notifier)
                .setGoal(GoalType.reduceTime),
          ),
          const SizedBox(height: AppSpacing.md),
          _GoalCard(
            icon: Icons.psychology_outlined,
            title: 'Mindful Usage',
            subtitle: 'Be intentional about when and why you use apps',
            isSelected: selectedGoal == GoalType.mindfulUsage,
            onTap: () => ref
                .read(onboardingProvider.notifier)
                .setGoal(GoalType.mindfulUsage),
          ),
          const SizedBox(height: AppSpacing.md),
          _GoalCard(
            icon: Icons.nights_stay_outlined,
            title: 'Better Sleep',
            subtitle: 'Reduce screen time before bed for better rest',
            isSelected: selectedGoal == GoalType.betterSleep,
            onTap: () => ref
                .read(onboardingProvider.notifier)
                .setGoal(GoalType.betterSleep),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
