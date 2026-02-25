import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';

/// Base layout for every onboarding step.
///
/// Provides a consistent structure: top illustration/icon area,
/// title, subtitle, flexible content area, and a bottom slot.
class OnboardingPage extends StatelessWidget {
  final Widget? icon;
  final String title;
  final String subtitle;
  final Widget content;
  final Widget? bottom;

  const OnboardingPage({
    super.key,
    this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.huge),
          if (icon != null) ...[
            Center(child: icon!),
            const SizedBox(height: AppSpacing.xxxl),
          ],
          Text(
            title,
            style: AppTextStyles.headingLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            subtitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Expanded(child: content),
          if (bottom != null) ...[
            bottom!,
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}
