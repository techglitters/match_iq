import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/widgets/primary_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _CloudLayer(color: colorScheme.tertiary)),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: null,
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 144,
                        height: 144,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.16,
                              ),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.local_florist,
                          color: colorScheme.primary,
                          size: 82,
                        ),
                      ),
                      const SizedBox(height: 34),
                      Text(
                        'Connect & Grow',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Match things that belong together',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 42),
                      PrimaryButton(
                        label: 'Play',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.game);
                        },
                      ),
                      const SizedBox(height: 26),
                      _PlayButtonAccents(color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudLayer extends StatelessWidget {
  const _CloudLayer({required this.color});

  final Color color;

  static const _clouds = [
    _CloudSpec(verticalPosition: 0.07, size: 54, horizontalPosition: 0.02),
    _CloudSpec(verticalPosition: 0.18, size: 82, horizontalPosition: 0.31),
    _CloudSpec(verticalPosition: 0.36, size: 46, horizontalPosition: 0.64),
    _CloudSpec(verticalPosition: 0.57, size: 68, horizontalPosition: 0.17),
    _CloudSpec(verticalPosition: 0.76, size: 58, horizontalPosition: 0.82),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              children: [
                for (final cloud in _clouds)
                  Positioned(
                    left: width * cloud.horizontalPosition,
                    top: height * cloud.verticalPosition,
                    child: _CloudIcon(size: cloud.size, color: color),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CloudIcon extends StatelessWidget {
  const _CloudIcon({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.cloud, size: size, color: color.withValues(alpha: 0.15));
  }
}

class _PlayButtonAccents extends StatelessWidget {
  const _PlayButtonAccents({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      hidden: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DecorativeIcon(icon: Icons.water_drop, color: color),
          const SizedBox(width: 18),
          _DecorativeIcon(icon: Icons.grass, color: color),
        ],
      ),
    );
  }
}

class _DecorativeIcon extends StatelessWidget {
  const _DecorativeIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 58, color: color.withValues(alpha: 0.22));
  }
}

class _CloudSpec {
  const _CloudSpec({
    required this.verticalPosition,
    required this.size,
    required this.horizontalPosition,
  });

  final double verticalPosition;
  final double size;
  final double horizontalPosition;
}
