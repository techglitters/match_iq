import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/game_constants.dart';
import '../../themes/presentation/controllers/app_progress_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_goHome());
  }

  Future<void> _goHome() async {
    final appProgress = context.read<AppProgressController>();
    await Future.wait<void>([
      appProgress.load(),
      Future<void>.delayed(GameConstants.splashDuration),
    ]);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.28),
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.local_florist,
                size: 72,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Link & Learn',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
