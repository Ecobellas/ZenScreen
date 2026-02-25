import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../providers/onboarding_provider.dart';

/// The categorized app data for the selection step.
const _appCategories = <String, List<String>>{
  'Social Media': [
    'Instagram',
    'TikTok',
    'Twitter/X',
    'Facebook',
    'Snapchat',
    'Reddit',
  ],
  'Video': ['YouTube', 'Netflix', 'Twitch'],
  'Games': ['Games'],
  'News': ['News'],
};

class AppSelectionStep extends ConsumerWidget {
  const AppSelectionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedApps = ref.watch(onboardingProvider).selectedApps;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.huge),
          Text(
            'Which apps distract you?',
            style: AppTextStyles.headingLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Select the apps you want to be more mindful about',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: _appCategories.entries.map((entry) {
                return _CategorySection(
                  category: entry.key,
                  apps: entry.value,
                  selectedApps: selectedApps[entry.key] ?? [],
                  onToggle: (app) => ref
                      .read(onboardingProvider.notifier)
                      .toggleApp(entry.key, app),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<String> apps;
  final List<String> selectedApps;
  final ValueChanged<String> onToggle;

  const _CategorySection({
    required this.category,
    required this.apps,
    required this.selectedApps,
    required this.onToggle,
  });

  IconData get _categoryIcon {
    switch (category) {
      case 'Social Media':
        return Icons.people_outline;
      case 'Video':
        return Icons.play_circle_outline;
      case 'Games':
        return Icons.sports_esports_outlined;
      case 'News':
        return Icons.article_outlined;
      default:
        return Icons.apps;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_categoryIcon, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(category, style: AppTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: apps.map((app) {
              final isSelected = selectedApps.contains(app);
              return GestureDetector(
                onTap: () => onToggle(app),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    app,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
