import 'dart:math';
import 'package:flutter/material.dart';

class SparklineChart extends StatefulWidget {
  final List<double> data;
  final double height;
  final double width;
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;
  final bool showDots;
  final bool animate;

  const SparklineChart({
    super.key,
    required this.data,
    this.height = 60,
    this.width = double.infinity,
    this.lineColor = const Color(0xFF7C3AED),
    this.fillColor = const Color(0x207C3AED),
    this.strokeWidth = 2.5,
    this.showDots = true,
    this.animate = true,
  });

  @override
  State<SparklineChart> createState() => _SparklineChartState();
}

class _SparklineChartState extends State<SparklineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty || widget.data.every((d) => d == 0)) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No data yet',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return SizedBox(
          height: widget.height,
          width: widget.width,
          child: CustomPaint(
            painter: _SparklinePainter(
              data: widget.data,
              lineColor: widget.lineColor,
              fillColor: widget.fillColor,
              strokeWidth: widget.strokeWidth,
              showDots: widget.showDots,
              progress: _animation.value,
            ),
          ),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;
  final bool showDots;
  final double progress;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.strokeWidth,
    required this.showDots,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce(max);
    final minVal = data.reduce(min);
    final range = maxVal - minVal;
    final padding = 8.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * drawWidth;
      final normalizedY = range > 0
          ? (data[i] - minVal) / range
          : 0.5;
      final y = padding + drawHeight - (normalizedY * drawHeight);
      points.add(Offset(x, y));
    }

    // Limit to progress
    final visibleCount = (points.length * progress).ceil().clamp(1, points.length);
    final visiblePoints = points.sublist(0, visibleCount);

    // Fill area
    if (visiblePoints.length >= 2) {
      final fillPath = Path();
      fillPath.moveTo(visiblePoints.first.dx, size.height - padding);
      for (final p in visiblePoints) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(visiblePoints.last.dx, size.height - padding);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fillColor.withValues(alpha: 0.4),
            fillColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    // Line
    if (visiblePoints.length >= 2) {
      final linePath = Path();
      linePath.moveTo(visiblePoints.first.dx, visiblePoints.first.dy);
      for (int i = 1; i < visiblePoints.length; i++) {
        // Smooth curve using cubic bezier
        final prev = visiblePoints[i - 1];
        final curr = visiblePoints[i];
        final cpX = (prev.dx + curr.dx) / 2;
        linePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
      }

      final linePaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(linePath, linePaint);
    }

    // Dots
    if (showDots && progress >= 1.0) {
      for (int i = 0; i < visiblePoints.length; i++) {
        final isLast = i == visiblePoints.length - 1;
        final dotPaint = Paint()
          ..color = isLast ? lineColor : lineColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(visiblePoints[i], isLast ? 4 : 2.5, dotPaint);

        if (isLast) {
          final glowPaint = Paint()
            ..color = lineColor.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(visiblePoints[i], 8, glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.data != data;
  }
}
