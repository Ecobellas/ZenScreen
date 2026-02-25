import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';

class ShockStatStep extends StatefulWidget {
  const ShockStatStep({super.key});

  @override
  State<ShockStatStep> createState() => _ShockStatStepState();
}

class _ShockStatStepState extends State<ShockStatStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _countAnimation = IntTween(begin: 0, end: 96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    // Start the count animation after a brief delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Animated big number
          AnimatedBuilder(
            animation: _countAnimation,
            builder: (context, child) {
              return Text(
                '${_countAnimation.value}',
                style: AppTextStyles.metricLarge.copyWith(
                  fontSize: 80,
                  color: AppColors.primary,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'times per day',
            style: AppTextStyles.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'the average person checks their phone',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.huge),
          // Secondary stat
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: AppColors.divider,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '2,617',
                  style: AppTextStyles.metricMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'hours per year lost to mindless scrolling',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            'It doesn\'t have to be this way.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
