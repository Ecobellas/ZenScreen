import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Large animated circular progress indicator for the health score (HLTH-02).
///
/// Ring color varies by score zone:
/// - >= 80: secondary (#00D9A3) with happy emoji
/// - 50-79: primary (#6C63FF) with neutral emoji
/// - < 50: error (#FF6B6B) with sad emoji
class HealthScoreCircle extends StatefulWidget {
  final int score;
  final double size;

  const HealthScoreCircle({
    super.key,
    required this.score,
    this.size = 200,
  });

  @override
  State<HealthScoreCircle> createState() => _HealthScoreCircleState();
}

class _HealthScoreCircleState extends State<HealthScoreCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.score / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(HealthScoreCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.score / 100,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _scoreColor {
    if (widget.score >= 80) return AppColors.secondary;
    if (widget.score >= 50) return AppColors.primary;
    return AppColors.error;
  }

  String get _emoji {
    if (widget.score >= 80) return '\u{1F60A}'; // happy
    if (widget.score >= 50) return '\u{1F610}'; // neutral
    return '\u{1F61E}'; // sad
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect behind the ring.
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _scoreColor.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              // Arc painter.
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ScoreArcPainter(
                  progress: _animation.value,
                  color: _scoreColor,
                  trackColor: AppColors.card,
                ),
              ),
              // Score text and emoji.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.score}',
                    style: AppTextStyles.metricLarge.copyWith(
                      color: _scoreColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter that draws a circular arc from 0 to [progress].
class _ScoreArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _ScoreArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 10.0;

    // Track (background ring).
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc.
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2; // Start from top.
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
