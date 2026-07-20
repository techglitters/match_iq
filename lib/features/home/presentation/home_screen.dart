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
            Positioned(
              top: 46,
              left: 24,
              child: _DecorativeIcon(
                icon: Icons.cloud,
                color: colorScheme.tertiary,
              ),
            ),
            Positioned(
              top: 108,
              right: 30,
              child: _DecorativeIcon(
                icon: Icons.water_drop,
                color: colorScheme.primary,
              ),
            ),
            Positioned(
              bottom: 82,
              left: 30,
              child: _DecorativeIcon(
                icon: Icons.grass,
                color: colorScheme.primary,
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

class _DecorativeIcon extends StatelessWidget {
  const _DecorativeIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 58, color: color.withValues(alpha: 0.22));
  }
}
