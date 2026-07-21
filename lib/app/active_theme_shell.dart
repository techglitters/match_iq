import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/themes/presentation/controllers/app_progress_controller.dart';
import '../shared/backgrounds/theme_background.dart';

class ActiveThemeShell extends StatelessWidget {
  const ActiveThemeShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appProgress = context.watch<AppProgressController>();

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ThemeBackground(theme: appProgress.activeTheme),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
