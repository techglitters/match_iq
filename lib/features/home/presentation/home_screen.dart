import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _cloudController;
  late final AnimationController _accentController;

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
    _accentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _accentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _AnimatedCloudLayer(
                animation: _cloudController,
                color: colorScheme.tertiary,
                disableAnimations: disableAnimations,
              ),
            ),
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
                      _PlayButtonAccents(
                        animation: _accentController,
                        color: colorScheme.primary,
                        disableAnimations: disableAnimations,
                      ),
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

class _AnimatedCloudLayer extends StatelessWidget {
  const _AnimatedCloudLayer({
    required this.animation,
    required this.color,
    required this.disableAnimations,
  });

  final Animation<double> animation;
  final Color color;
  final bool disableAnimations;

  static const _clouds = [
    _CloudSpec(
      verticalPosition: 0.07,
      size: 54,
      phase: 0.02,
      speed: 0.58,
      bob: 6,
    ),
    _CloudSpec(
      verticalPosition: 0.18,
      size: 82,
      phase: 0.31,
      speed: 0.42,
      bob: 10,
    ),
    _CloudSpec(
      verticalPosition: 0.36,
      size: 46,
      phase: 0.64,
      speed: 0.72,
      bob: 5,
    ),
    _CloudSpec(
      verticalPosition: 0.57,
      size: 68,
      phase: 0.17,
      speed: 0.50,
      bob: 9,
    ),
    _CloudSpec(
      verticalPosition: 0.76,
      size: 58,
      phase: 0.82,
      speed: 0.62,
      bob: 7,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            if (disableAnimations) {
              return Stack(
                children: [
                  for (final cloud in _clouds)
                    Positioned(
                      left: width * cloud.phase,
                      top: height * cloud.verticalPosition,
                      child: _CloudIcon(size: cloud.size, color: color),
                    ),
                ],
              );
            }

            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Stack(
                  children: [
                    for (final cloud in _clouds)
                      _MovingCloud(
                        spec: cloud,
                        progress: animation.value,
                        width: width,
                        height: height,
                        color: color,
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MovingCloud extends StatelessWidget {
  const _MovingCloud({
    required this.spec,
    required this.progress,
    required this.width,
    required this.height,
    required this.color,
  });

  final _CloudSpec spec;
  final double progress;
  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cloudProgress = (spec.phase + progress * spec.speed) % 1;
    final horizontalTravel = width + spec.size * 2;
    final left = -spec.size + horizontalTravel * cloudProgress;
    final top =
        height * spec.verticalPosition +
        math.sin((cloudProgress + spec.phase) * math.pi * 2) * spec.bob;

    return Positioned(
      left: left,
      top: top,
      child: _CloudIcon(size: spec.size, color: color),
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

class _AnimatedAccentIcon extends StatelessWidget {
  const _AnimatedAccentIcon({
    required this.animation,
    required this.icon,
    required this.color,
    required this.travel,
    required this.rotation,
    required this.disableAnimations,
    this.phase = 0,
  });

  final Animation<double> animation;
  final IconData icon;
  final Color color;
  final Offset travel;
  final double rotation;
  final bool disableAnimations;
  final double phase;

  @override
  Widget build(BuildContext context) {
    if (disableAnimations) {
      return _DecorativeIcon(icon: icon, color: color);
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final eased = Curves.easeInOut.transform((animation.value + phase) % 1);
        final wave = math.sin(eased * math.pi);
        return Transform.translate(
          offset: Offset(travel.dx * wave, travel.dy * wave),
          child: Transform.rotate(
            angle: rotation * wave,
            child: Transform.scale(scale: 1 + wave * 0.05, child: child),
          ),
        );
      },
      child: _DecorativeIcon(icon: icon, color: color),
    );
  }
}

class _PlayButtonAccents extends StatelessWidget {
  const _PlayButtonAccents({
    required this.animation,
    required this.color,
    required this.disableAnimations,
  });

  final Animation<double> animation;
  final Color color;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      hidden: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedAccentIcon(
            animation: animation,
            icon: Icons.water_drop,
            color: color,
            travel: const Offset(0, 8),
            rotation: -0.08,
            phase: 0.32,
            disableAnimations: disableAnimations,
          ),
          const SizedBox(width: 18),
          _AnimatedAccentIcon(
            animation: animation,
            icon: Icons.grass,
            color: color,
            travel: const Offset(0, -6),
            rotation: 0.06,
            disableAnimations: disableAnimations,
          ),
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
    required this.phase,
    required this.speed,
    required this.bob,
  });

  final double verticalPosition;
  final double size;
  final double phase;
  final double speed;
  final double bob;
}
