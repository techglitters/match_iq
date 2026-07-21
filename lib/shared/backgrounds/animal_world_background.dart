import 'package:flutter/material.dart';

class AnimalWorldBackground extends StatelessWidget {
  const AnimalWorldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF3D8), Color(0xFFFFE4B8), Color(0xFFD9E8C0)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _AnimalLandPainter()),
          ),
          Positioned(
            top: 64,
            left: 28,
            child: _DecorIcon(
              icon: Icons.pets,
              size: 54,
              color: const Color(0xFF8D5A2B),
            ),
          ),
          Positioned(
            top: 138,
            right: 30,
            child: _DecorIcon(
              icon: Icons.flutter_dash,
              size: 44,
              color: const Color(0xFF4DB6AC),
            ),
          ),
          Positioned(
            bottom: 116,
            left: 34,
            child: _DecorIcon(
              icon: Icons.grass,
              size: 48,
              color: const Color(0xFF558B2F),
            ),
          ),
          Positioned(
            bottom: 78,
            right: 34,
            child: _DecorIcon(
              icon: Icons.pets,
              size: 46,
              color: const Color(0xFF9C6A3A),
            ),
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
    required this.color,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: color.withValues(alpha: 0.16), size: size);
  }
}

class _AnimalLandPainter extends CustomPainter {
  const _AnimalLandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final hillPaint = Paint()
      ..color = const Color(0xFFB8D88D).withValues(alpha: 0.54);
    final hillPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.62,
        size.width * 0.58,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.82,
        size.width,
        size.height * 0.70,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hillPath, hillPaint);

    final trackPaint = Paint()
      ..color = const Color(0xFF8D5A2B).withValues(alpha: 0.08);
    final pawCenters = [
      Offset(size.width * 0.20, size.height * 0.36),
      Offset(size.width * 0.78, size.height * 0.44),
      Offset(size.width * 0.34, size.height * 0.82),
      Offset(size.width * 0.70, size.height * 0.76),
    ];

    for (final center in pawCenters) {
      canvas.drawCircle(center, 9, trackPaint);
      canvas.drawCircle(center.translate(-11, -10), 4, trackPaint);
      canvas.drawCircle(center.translate(0, -14), 4, trackPaint);
      canvas.drawCircle(center.translate(11, -10), 4, trackPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
