import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/game/data/nature_levels.dart';
import '../features/game/presentation/controllers/game_controller.dart';
import '../features/game/presentation/screens/game_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/level_map/presentation/level_map_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/themes/data/theme_catalog.dart';
import '../features/themes/presentation/theme_detail_screen.dart';
import '../features/themes/presentation/theme_selection_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const home = '/home';
  static const themes = '/themes';
  static const natureTheme = '/theme/nature';
  static const natureLevels = '/theme/nature/levels';
  static const _natureLevelPrefix = '/theme/nature/level/';

  static String natureLevel(int levelNumber) {
    return '$_natureLevelPrefix$levelNumber';
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final levelNumber = _parseNatureLevel(settings.name);
    if (levelNumber != null) {
      return _route(_createGameScreen(levelNumber), settings);
    }

    return switch (settings.name) {
      splash => _route(const SplashScreen(), settings),
      home => _route(const HomeScreen(), settings),
      themes => _route(const ThemeSelectionScreen(), settings),
      natureTheme => _route(const ThemeDetailScreen(), settings),
      natureLevels => _route(const LevelMapScreen(), settings),
      _ => _route(const HomeScreen(), settings),
    };
  }

  static PageRouteBuilder<void> _route(Widget child, RouteSettings settings) {
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static Widget _createGameScreen(int levelNumber) {
    final levels = createNatureLevels();
    final initialLevel = createNatureLevel(levelNumber: levelNumber);

    return ChangeNotifierProvider(
      create: (_) => GameController(initialLevel: initialLevel, levels: levels),
      child: GameScreen(
        themeId: ThemeCatalog.natureThemeId,
        levelNumber: initialLevel.levelNumber,
      ),
    );
  }

  static int? _parseNatureLevel(String? routeName) {
    if (routeName == null || !routeName.startsWith(_natureLevelPrefix)) {
      return null;
    }

    final parsed = int.tryParse(routeName.substring(_natureLevelPrefix.length));
    if (parsed == null) {
      return null;
    }

    return parsed.clamp(1, natureLevelCount).toInt();
  }
}
