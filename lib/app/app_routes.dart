import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/game/data/nature_levels.dart';
import '../features/game/presentation/controllers/game_controller.dart';
import '../features/game/presentation/screens/game_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const home = '/home';
  static const game = '/game';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      splash => _route(const SplashScreen(), settings),
      home => _route(const HomeScreen(), settings),
      game => _route(_createGameScreen(), settings),
      _ => _route(const HomeScreen(), settings),
    };
  }

  static MaterialPageRoute<void> _route(Widget child, RouteSettings settings) {
    return MaterialPageRoute<void>(settings: settings, builder: (_) => child);
  }

  static Widget _createGameScreen() {
    final initialLevel = createNatureLevel(levelNumber: 1);

    return ChangeNotifierProvider(
      create: (_) => GameController(
        initialLevel: initialLevel,
        maxLevelCount: natureLevelCount,
        levelBuilder: (levelNumber) =>
            createNatureLevel(levelNumber: levelNumber),
      ),
      child: const GameScreen(),
    );
  }
}
