import 'dart:math';
import 'package:flutter/material.dart';
import 'package:drive_tracker/widgets/animated_number.dart';

class SpeedGauge extends StatelessWidget {
  final double speed;
  final double maxSpeed;
  final String unit;

  const SpeedGauge({
    super.key,
    required this.speed,
    this.maxSpeed = 160.0,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Custom Painted Gauge
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: speed),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, animVal, child) {
              return CustomPaint(
                size: const Size(250, 250),
                painter: _GaugePainter(
                  speed: animVal,
                  maxSpeed: maxSpeed,
                  primaryColor: primaryColor,
                  accentColor: secondaryColor,
                  brightness: theme.brightness,
                ),
              );
            },
          ),
          // Inner speed value
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedNumber(
                value: speed,
                precision: 0,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 56,
                  letterSpacing: -2,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                unit.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final Color primaryColor;
  final Color accentColor;
  final Brightness brightness;

  _GaugePainter({
    required this.speed,
    required this.maxSpeed,
    required this.primaryColor,
    required this.accentColor,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 15;

    // Standard start and sweep angles for gauges (270 degrees total)
    const double startAngle = 135 * pi / 180;
    const double sweepAngle = 270 * pi / 180;

    // 1. Background Arc Track
    final bgPaint = Paint()
      ..color = brightness == Brightness.light
          ? Colors.grey[200]!
          : const Color(0xFF1E293B) // slate 800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, bgPaint);

    // 2. Active Speed Indicator Arc (with Gradient)
    final double activeSweepAngle = (speed / maxSpeed).clamp(0.0, 1.0) * sweepAngle;
    
    if (activeSweepAngle > 0) {
      final activePaint = Paint()
        ..shader = SweepGradient(
          colors: [primaryColor, accentColor, primaryColor],
          stops: const [0.0, 0.5, 1.0],
          transform: const GradientRotation(135 * pi / 180),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      // Glow effect for dark mode
      if (brightness == Brightness.dark) {
        final shadowPaint = Paint()
          ..color = primaryColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          activeSweepAngle,
          false,
          shadowPaint,
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweepAngle,
        false,
        activePaint,
      );
    }

    // 3. Tick Marks
    final tickPaint = Paint()
      ..color = brightness == Brightness.light
          ? Colors.grey[400]!
          : const Color(0xFF475569) // slate 600
      ..strokeWidth = 2;

    const tickCount = 25;
    for (int i = 0; i <= tickCount; i++) {
      final double angle = startAngle + (i / tickCount) * sweepAngle;
      final double innerOffset = i % 5 == 0 ? 15.0 : 8.0;

      final startOffset = Offset(
        center.dx + (radius - 12) * cos(angle),
        center.dy + (radius - 12) * sin(angle),
      );
      final endOffset = Offset(
        center.dx + (radius - 12 - innerOffset) * cos(angle),
        center.dy + (radius - 12 - innerOffset) * sin(angle),
      );

      canvas.drawLine(startOffset, endOffset, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.speed != speed ||
        oldDelegate.maxSpeed != maxSpeed ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.brightness != brightness;
  }
}
