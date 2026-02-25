import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/blocking_provider.dart';
import '../providers/strict_mode_provider.dart';
import '../widgets/emergency_bypass_dialog.dart';

/// Rotating motivational messages shown on the blocking overlay.
const _motivationalMessages = [
  "You've reached your limit",
  'Time for something else',
  'Your future self will thank you',
  'Step away, take a breath',
  'Focus on what matters',
  'This app can wait',
  'Protect your time',
  'Be intentional with your attention',
];

/// Full-screen blocking overlay (BLCK-04).
///
/// Shown when an app is blocked (daily limit reached or schedule active).
/// Dark, forbidding design with no bypass option -- only "Go Back".
/// In Strict Mode, an "Emergency Bypass" button leads to the 60s countdown.
class BlockingOverlayScreen extends ConsumerWidget {
  /// The package name that triggered the block.
  final String packageName;

  const BlockingOverlayScreen({
    super.key,
    required this.packageName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockReason = ref
        .read(blockingProvider.notifier)
        .getBlockReasonMessage(packageName);
    final isStrictMode = ref.watch(strictModeProvider).config.isCurrentlyActive();
    final strictState = ref.watch(strictModeProvider);

    // Pick a random motivational message.
    final message =
        _motivationalMessages[Random().nextInt(_motivationalMessages.length)];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.85),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Lock icon.
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: AppColors.error,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Block reason.
                    Text(
                      blockReason.isNotEmpty
                          ? blockReason
                          : 'App Blocked',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Motivational message.
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(flex: 3),

                    // Emergency bypass button (only in Strict Mode).
                    if (isStrictMode &&
                        strictState.remainingEmergencyBypasses > 0) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                            horizontal: AppSpacing.xxl,
                          ),
                        ),
                        icon: const Icon(Icons.warning_amber, size: 18),
                        label: Text(
                          'Emergency Bypass',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => EmergencyBypassDialog(
                              packageName: packageName,
                              onBypassed: () {
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Go back button.
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.card,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                        ),
                        onPressed: () {
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text('Go Back',
                            style: AppTextStyles.labelLarge),
                      ),
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
}
