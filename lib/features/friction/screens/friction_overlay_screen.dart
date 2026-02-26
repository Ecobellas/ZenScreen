import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/friction_provider.dart';
import '../widgets/breathing_overlay.dart';
import '../widgets/intention_overlay.dart';
import '../widgets/wait_timer_overlay.dart';

/// Full-screen friction overlay with glassmorphism background.
///
/// Routes to the appropriate friction widget (WaitTimerOverlay,
/// BreathingOverlay, or IntentionOverlay) based on the current friction type.
/// Contains "Give Up" and "Open Anyway" action buttons at the bottom.
class FrictionOverlayScreen extends ConsumerWidget {
  const FrictionOverlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friction = ref.watch(frictionProvider);

    return PopScope(
      // Prevent hardware back from dismissing without logging.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(frictionProvider.notifier).dismissFriction();
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.75),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.huge),

                    // Friction content area.
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: _buildFrictionContent(friction),
                        ),
                      ),
                    ),

                    // Action buttons.
                    _ActionButtons(
                      isCompleted: friction.isCompleted,
                      onGiveUp: () {
                        ref
                            .read(frictionProvider.notifier)
                            .dismissFriction();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      onOpenAnyway: () {
                        ref
                            .read(frictionProvider.notifier)
                            .proceedAnyway();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrictionContent(FrictionState friction) {
    switch (friction.currentFrictionType) {
      case FrictionType.wait:
        return const WaitTimerOverlay();
      case FrictionType.breath:
        return const BreathingOverlay();
      case FrictionType.intention:
        return const IntentionOverlay();
    }
  }
}

/// Bottom action buttons: "Give Up" (outlined) and "Open Anyway" (filled).
class _ActionButtons extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onGiveUp;
  final VoidCallback onOpenAnyway;

  const _ActionButtons({
    required this.isCompleted,
    required this.onGiveUp,
    required this.onOpenAnyway,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // "Give Up" -- always enabled.
        Expanded(
          child: OutlinedButton(
            onPressed: onGiveUp,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Give Up', style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            )),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),

        // "Open Anyway" -- only enabled after friction completes.
        Expanded(
          child: ElevatedButton(
            onPressed: isCompleted ? onOpenAnyway : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isCompleted ? AppColors.textPrimary : AppColors.card,
              foregroundColor: isCompleted
                  ? AppColors.background
                  : AppColors.textHint,
              disabledBackgroundColor: AppColors.card,
              disabledForegroundColor: AppColors.textHint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Open Anyway', style: AppTextStyles.labelLarge.copyWith(
              color: isCompleted
                  ? AppColors.background
                  : AppColors.textHint,
            )),
          ),
        ),
      ],
    );
  }
}
