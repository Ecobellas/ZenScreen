import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/friction_provider.dart';

/// FRIC-03: Intention Prompt overlay.
///
/// Asks the user "Why are you opening [App Name]?" with 4 tappable option
/// cards. Selecting an intention enables the "Open Anyway" button.
class IntentionOverlay extends ConsumerWidget {
  const IntentionOverlay({super.key});

  static const _options = [
    _IntentionOption(
      intention: IntentionType.work,
      label: 'Work / Communication',
      icon: Icons.work_outline,
    ),
    _IntentionOption(
      intention: IntentionType.social,
      label: 'Socializing',
      icon: Icons.people_outline,
    ),
    _IntentionOption(
      intention: IntentionType.boredom,
      label: 'Boredom',
      icon: Icons.sentiment_dissatisfied_outlined,
    ),
    _IntentionOption(
      intention: IntentionType.justChecking,
      label: 'Just Checking',
      icon: Icons.visibility_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friction = ref.watch(frictionProvider);
    final selected = friction.selectedIntention;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Why are you opening',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          friction.currentAppName.isNotEmpty
              ? friction.currentAppName
              : 'this app',
          style: AppTextStyles.headingMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxxl),

        // Intention option cards.
        ...List.generate(_options.length, (index) {
          final option = _options[index];
          final isSelected = selected == option.intention;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _IntentionCard(
              option: option,
              isSelected: isSelected,
              onTap: () {
                ref
                    .read(frictionProvider.notifier)
                    .selectIntention(option.intention);
              },
            ),
          );
        }),
      ],
    );
  }
}

/// Data class for an intention option.
class _IntentionOption {
  final IntentionType intention;
  final String label;
  final IconData icon;

  const _IntentionOption({
    required this.intention,
    required this.label,
    required this.icon,
  });
}

/// A single tappable intention card.
class _IntentionCard extends StatelessWidget {
  final _IntentionOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _IntentionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                option.label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
