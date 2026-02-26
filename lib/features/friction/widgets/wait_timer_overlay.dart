import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/friction_provider.dart';

/// FRIC-01: Wait Timer overlay.
///
/// Displays a large circular countdown timer that starts at 5s and escalates
/// by +5s per consecutive open (max 30s). When the timer reaches 0 the
/// "Open Anyway" button in the parent overlay becomes enabled.
class WaitTimerOverlay extends ConsumerWidget {
  const WaitTimerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friction = ref.watch(frictionProvider);
    final remaining = friction.remainingSeconds;
    final total = friction.totalSeconds;
    final progress = total > 0 ? remaining / total : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The 'Take a moment' text was removed in the new design.
        const SizedBox(height: AppSpacing.huge),

        // Circular countdown timer.
        SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: _CountdownRingPainter(progress: progress),
            child: Center(
              child: Text(
                '${remaining}s',
                style: AppTextStyles.metricLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        Text(
          'Is this app truly necessary right now?',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Custom painter that draws the circular countdown ring.
class _CountdownRingPainter extends CustomPainter {
  final double progress; // 1.0 = full, 0.0 = empty

  _CountdownRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    // Background ring (track).
    final bgPaint = Paint()
      ..color = AppColors.card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring.
    final fgPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top.
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
