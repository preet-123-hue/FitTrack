import 'package:flutter/material.dart';
import 'dart:math' as math;

class ActivityRing extends StatelessWidget {
  final double stepsProgress;
  final double heartPointsProgress;
  final double size;

  const ActivityRing({
    super.key,
    required this.stepsProgress,
    required this.heartPointsProgress,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ActivityRingPainter(
          stepsProgress: stepsProgress,
          heartPointsProgress: heartPointsProgress,
        ),
      ),
    );
  }
}

class ActivityRingPainter extends CustomPainter {
  final double stepsProgress;
  final double heartPointsProgress;

  ActivityRingPainter({
    required this.stepsProgress,
    required this.heartPointsProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Background rings
    final backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Outer ring (steps) - background
    canvas.drawCircle(center, radius - 3, backgroundPaint);
    
    // Inner ring (heart points) - background
    canvas.drawCircle(center, radius - 15, backgroundPaint);

    // Steps ring (outer)
    final stepsPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final stepsAngle = 2 * math.pi * stepsProgress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 3),
      -math.pi / 2,
      stepsAngle,
      false,
      stepsPaint,
    );

    // Heart points ring (inner)
    final heartPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final heartAngle = 2 * math.pi * heartPointsProgress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 15),
      -math.pi / 2,
      heartAngle,
      false,
      heartPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}