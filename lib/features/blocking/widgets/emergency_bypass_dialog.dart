import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/strict_mode_provider.dart';

/// Emergency bypass dialog for Strict Mode (STRK-03).
///
/// Shows a 60-second countdown timer. After the countdown completes,
/// asks "Is this truly urgent?" with confirm/cancel options.
/// If confirmed, grants a 5-minute temporary bypass for one app.
class EmergencyBypassDialog extends ConsumerWidget {
  final String packageName;
  final VoidCallback onBypassed;

  const EmergencyBypassDialog({
    super.key,
    required this.packageName,
    required this.onBypassed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strictState = ref.watch(strictModeProvider);
    final notifier = ref.read(strictModeProvider.notifier);
    final countdown = strictState.emergencyCountdownSeconds;
    final isCountingDown = strictState.isEmergencyCountdownActive;

    // Start countdown when dialog first opens (if not already).
    if (!isCountingDown && countdown == 0 && !strictState.isBypassActive) {
      // Use addPostFrameCallback to avoid modifying state during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.startEmergencyBypass(packageName);
      });
    }

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header.
            Row(
              children: [
                Icon(Icons.warning, color: AppColors.error, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Emergency Bypass',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            if (countdown > 0 || isCountingDown) ...[
              // Countdown phase.
              Text(
                'Please wait before proceeding...',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Countdown ring.
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _CountdownPainter(
                    progress: countdown / 60.0,
                  ),
                  child: Center(
                    child: Text(
                      '$countdown',
                      style: AppTextStyles.metricLarge.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Cancel button.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side:
                        const BorderSide(color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                  ),
                  onPressed: () {
                    notifier.cancelEmergencyBypass();
                    Navigator.of(context).pop();
                  },
                  child: Text('No, I can wait',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ),
            ] else ...[
              // Countdown complete -- confirmation phase.
              Icon(Icons.help_outline,
                  color: AppColors.error, size: 48),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Is this truly urgent?',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'You will get 5 minutes of access.\n'
                'This is your only bypass this session.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Confirm button.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                  ),
                  onPressed: () {
                    notifier.confirmEmergencyBypass();
                    Navigator.of(context).pop();
                    onBypassed();
                  },
                  child: Text('Yes, this is urgent',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.textPrimary)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Cancel button.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side:
                        const BorderSide(color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                  ),
                  onPressed: () {
                    notifier.cancelEmergencyBypass();
                    Navigator.of(context).pop();
                  },
                  child: Text('No, I can wait',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Circular countdown painter for the emergency bypass timer.
class _CountdownPainter extends CustomPainter {
  final double progress; // 1.0 = full, 0.0 = empty

  _CountdownPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    // Background ring.
    final bgPaint = Paint()
      ..color = AppColors.card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring.
    final fgPaint = Paint()
      ..color = AppColors.error
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CountdownPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
