import 'package:flutter/material.dart';

import '../../features/themes/data/theme_catalog.dart';
import '../../features/themes/domain/game_theme.dart';
import 'nature_world_background.dart';

class ThemeBackground extends StatelessWidget {
  const ThemeBackground({required this.theme, super.key});

  final GameTheme theme;

  @override
  Widget build(BuildContext context) {
    return switch (theme.id) {
      ThemeCatalog.natureThemeId => const NatureWorldBackground(),
      _ => const NatureWorldBackground(),
    };
  }
}
