import 'package:flutter/material.dart';

class LevelPathPainter extends CustomPainter {
  const LevelPathPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final shadowPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pathPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index += 1) {
      final previous = points[index - 1];
      final current = points[index];
      final control = Offset(
        (previous.dx + current.dx) / 2,
        (previous.dy + current.dy) / 2,
      );
      path.quadraticBezierTo(previous.dx, control.dy, current.dx, current.dy);
    }

    canvas
      ..drawPath(path, shadowPaint)
      ..drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant LevelPathPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
