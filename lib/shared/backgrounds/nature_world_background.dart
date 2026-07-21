import 'package:flutter/material.dart';

class NatureWorldBackground extends StatelessWidget {
  const NatureWorldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE5F7FF),
                  Color(0xFFF2FCE8),
                  Color(0xFFDDF3C5),
                ],
              ),
            ),
          ),
          CustomPaint(painter: _NatureWorldPainter()),
          _NatureDecorations(),
        ],
      ),
    );
  }
}

class _NatureWorldPainter extends CustomPainter {
  const _NatureWorldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _paintCloud(canvas, size, const Offset(0.12, 0.08), 1.0);
    _paintCloud(canvas, size, const Offset(0.72, 0.13), 0.78);
    _paintCloud(canvas, size, const Offset(0.42, 0.21), 0.56);
    _paintHills(canvas, size);
  }

  void _paintCloud(Canvas canvas, Size size, Offset anchor, double scale) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.50)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final base = Offset(size.width * anchor.dx, size.height * anchor.dy);
    final radius = size.shortestSide * 0.05 * scale;

    canvas
      ..drawCircle(base, radius, paint)
      ..drawCircle(
        base + Offset(radius * 0.9, -radius * 0.25),
        radius * 1.22,
        paint,
      )
      ..drawCircle(base + Offset(radius * 2.0, 0), radius * 0.92, paint)
      ..drawOval(
        Rect.fromCenter(
          center: base + Offset(radius * 1.0, radius * 0.45),
          width: radius * 4.0,
          height: radius * 1.35,
        ),
        paint,
      );
  }

  void _paintHills(Canvas canvas, Size size) {
    final farPaint = Paint()
      ..color = const Color(0xFFBDE7A8).withValues(alpha: 0.72)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final nearPaint = Paint()
      ..color = const Color(0xFF8BD27A).withValues(alpha: 0.40)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final farPath = Path()
      ..moveTo(0, size.height * 0.70)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.55,
        size.width * 0.46,
        size.height * 0.78,
        size.width,
        size.height * 0.60,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final nearPath = Path()
      ..moveTo(0, size.height * 0.82)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.70,
        size.width * 0.58,
        size.height * 0.96,
        size.width,
        size.height * 0.76,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas
      ..drawPath(farPath, farPaint)
      ..drawPath(nearPath, nearPaint);
  }

  @override
  bool shouldRepaint(covariant _NatureWorldPainter oldDelegate) {
    return false;
  }
}

class _NatureDecorations extends StatelessWidget {
  const _NatureDecorations();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          Positioned(
            left: 24,
            bottom: 54,
            child: _DecorIcon(icon: Icons.grass, size: 58, opacity: 0.18),
          ),
          Positioned(
            right: 30,
            bottom: 128,
            child: _DecorIcon(
              icon: Icons.local_florist,
              size: 46,
              opacity: 0.14,
            ),
          ),
          Positioned(
            left: 34,
            top: 260,
            child: _DecorIcon(icon: Icons.eco, size: 42, opacity: 0.12),
          ),
          Positioned(
            right: 28,
            top: 330,
            child: _DecorIcon(icon: Icons.water_drop, size: 46, opacity: 0.12),
          ),
        ],
      ),
    );
  }
}

class _DecorIcon extends StatelessWidget {
  const _DecorIcon({
    required this.icon,
    required this.size,
    required this.opacity,
  });

  final IconData icon;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: const Color(0xFF2E7D32).withValues(alpha: opacity),
    );
  }
}
