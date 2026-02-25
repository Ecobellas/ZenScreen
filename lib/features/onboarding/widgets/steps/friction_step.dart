import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../providers/onboarding_provider.dart';

class FrictionStep extends ConsumerWidget {
  const FrictionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).selectedFriction;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.huge),
          Text(
            'Choose your pause type',
            style: AppTextStyles.headingLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This appears when you open a restricted app',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          _FrictionCard(
            icon: Icons.hourglass_top_rounded,
            title: 'Wait Timer',
            description: 'A countdown that makes you pause before opening',
            isSelected: selected == FrictionType.wait,
            onTap: () => ref
                .read(onboardingProvider.notifier)
                .setFriction(FrictionType.wait),
          ),
          const SizedBox(height: AppSpacing.md),
          _FrictionCard(
            icon: Icons.air_rounded,
            title: 'Breathing Exercise',
            description: 'A calming breath exercise to reset your mind',
            isSelected: selected == FrictionType.breath,
            onTap: () => ref
                .read(onboardingProvider.notifier)
                .setFriction(FrictionType.breath),
          ),
          const SizedBox(height: AppSpacing.md),
          _FrictionCard(
            icon: Icons.psychology_outlined,
            title: 'Intention Prompt',
            description: 'Ask yourself why you\'re opening this app',
            isSelected: selected == FrictionType.intention,
            onTap: () => ref
                .read(onboardingProvider.notifier)
                .setFriction(FrictionType.intention),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _FrictionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrictionCard({
    required this.icon,
    required this.title,
    required this.description,
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
                  Text(description, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.secondary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
