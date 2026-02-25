import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/friction_provider.dart';

/// FRIC-02: Breathing Exercise overlay.
///
/// An animated expanding/contracting circle guiding inhale (3.5s),
/// hold (3.5s), and exhale (3.5s) phases over a 15-second total duration.
/// After 15s the parent overlay enables the "Open Anyway" button.
class BreathingOverlay extends ConsumerStatefulWidget {
  const BreathingOverlay({super.key});

  @override
  ConsumerState<BreathingOverlay> createState() => _BreathingOverlayState();
}

class _BreathingOverlayState extends ConsumerState<BreathingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const _quotes = [
    'This moment is temporary',
    'You are in control',
    'Breathe and let go',
    'Be present, be mindful',
    'Every pause is a choice',
    'Stillness brings clarity',
  ];

  /// The current quote index, advances each full cycle.
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();
    // Each cycle is 10.5s (3.5 + 3.5 + 3.5). We run for 15s total.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10500), // one full cycle
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _quoteIndex = (_quoteIndex + 1) % _quotes.length;
          });
          _controller.forward(from: 0);
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Returns the breathing phase label based on animation progress.
  String _phaseLabel(double value) {
    // 0.0 - 0.333: Inhale (3.5s)
    // 0.333 - 0.667: Hold (3.5s)
    // 0.667 - 1.0: Exhale (3.5s)
    if (value < 0.333) return 'Inhale...';
    if (value < 0.667) return 'Hold...';
    return 'Exhale...';
  }

  /// Returns circle scale factor (100 -> 200 px diameter range).
  /// Inhale: expand 100->200, Hold: stay at 200, Exhale: contract 200->100.
  double _circleSize(double value) {
    const minSize = 100.0;
    const maxSize = 200.0;

    if (value < 0.333) {
      // Inhale: grow from min to max.
      final t = value / 0.333;
      return minSize + (maxSize - minSize) * t;
    } else if (value < 0.667) {
      // Hold: stay at max.
      return maxSize;
    } else {
      // Exhale: shrink from max to min.
      final t = (value - 0.667) / 0.333;
      return maxSize - (maxSize - minSize) * t;
    }
  }

  /// Opacity pulses gently with the breathing cycle.
  double _circleOpacity(double value) {
    if (value < 0.333) {
      return 0.4 + 0.4 * (value / 0.333);
    } else if (value < 0.667) {
      return 0.8;
    } else {
      return 0.8 - 0.4 * ((value - 0.667) / 0.333);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friction = ref.watch(frictionProvider);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final size = _circleSize(value);
        final opacity = _circleOpacity(value);
        final phase = _phaseLabel(value);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              phase,
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Animated breathing circle.
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: opacity),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: opacity * 0.4),
                    blurRadius: size * 0.3,
                    spreadRadius: size * 0.05,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Calming quote.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _quotes[_quoteIndex],
                key: ValueKey(_quoteIndex),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (friction.isCompleted)
              Text(
                'Exercise complete',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.secondary,
                ),
              )
            else
              Text(
                '${friction.remainingSeconds}s remaining',
                style: AppTextStyles.metricSmall,
              ),
          ],
        );
      },
    );
  }
}
