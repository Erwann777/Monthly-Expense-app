import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedProgressRing extends StatefulWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;
  final Widget? child;
  final Duration duration;
  final Gradient? gradient;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    this.size = 140,
    this.strokeWidth = 12,
    this.progressColor = const Color(0xFF7C3AED),
    this.backgroundColor = const Color(0xFFE2E8F0),
    this.child,
    this.duration = const Duration(milliseconds: 1200),
    this.gradient,
  });

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _ProgressRingPainter(
              progress: _animation.value.clamp(0.0, 1.0),
              strokeWidth: widget.strokeWidth,
              progressColor: widget.progressColor,
              backgroundColor: widget.backgroundColor,
              gradient: widget.gradient,
            ),
            child: Center(child: widget.child),
          ),
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;
  final Gradient? gradient;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (gradient != null) {
        progressPaint.shader = gradient!.createShader(rect);
      } else {
        progressPaint.color = progressColor;
      }

      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        rect,
        -pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );

      // Glow effect
      final glowPaint = Paint()
        ..color = progressColor.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawArc(rect, -pi / 2, sweepAngle, false, glowPaint);

      // End dot
      if (progress > 0.01 && progress < 1.0) {
        final angle = -pi / 2 + sweepAngle;
        final dotCenter = Offset(
          center.dx + radius * cos(angle),
          center.dy + radius * sin(angle),
        );
        final dotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(dotCenter, strokeWidth / 2 - 1, dotPaint);
        
        final dotBorderPaint = Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(dotCenter, strokeWidth / 2 - 1, dotBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
