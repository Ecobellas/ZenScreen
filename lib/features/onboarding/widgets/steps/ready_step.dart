import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../providers/onboarding_provider.dart';

class ReadyStep extends ConsumerWidget {
  const ReadyStep({super.key});

  String _goalLabel(GoalType? goal) {
    switch (goal) {
      case GoalType.reduceTime:
        return 'Reduce Screen Time';
      case GoalType.mindfulUsage:
        return 'Mindful Usage';
      case GoalType.betterSleep:
        return 'Better Sleep';
      case null:
        return 'Not set';
    }
  }

  String _frictionLabel(FrictionType? friction) {
    switch (friction) {
      case FrictionType.wait:
        return 'Wait Timer';
      case FrictionType.breath:
        return 'Breathing Exercise';
      case FrictionType.intention:
        return 'Intention Prompt';
      case null:
        return 'Not set';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Success checkmark
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 48,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            'You\'re all set!',
            style: AppTextStyles.headingLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Here\'s a summary of your choices',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          // Summary cards
          _SummaryRow(
            icon: Icons.flag_outlined,
            label: 'Goal',
            value: _goalLabel(state.selectedGoal),
          ),
          const SizedBox(height: AppSpacing.md),
          _SummaryRow(
            icon: Icons.apps_outlined,
            label: 'Tracked apps',
            value: '${state.totalSelectedApps} app${state.totalSelectedApps == 1 ? '' : 's'} selected',
          ),
          const SizedBox(height: AppSpacing.md),
          _SummaryRow(
            icon: Icons.pause_circle_outline,
            label: 'Pause type',
            value: _frictionLabel(state.selectedFriction),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: AppTextStyles.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
