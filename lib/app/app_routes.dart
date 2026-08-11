import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/daily/data/daily_puzzle_catalog.dart';
import '../features/daily/presentation/daily_history_screen.dart';
import '../features/game/data/themed_level_builder.dart';
import '../features/game/presentation/controllers/game_controller.dart';
import '../features/game/presentation/screens/game_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/level_map/presentation/level_map_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/themes/data/theme_catalog.dart';
import '../features/themes/domain/game_theme.dart';
import '../features/themes/presentation/theme_detail_screen.dart';
import '../features/themes/presentation/theme_selection_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const home = '/home';
  static const themes = '/themes';
  static const settings = '/settings';
  static const dailyPuzzle = '/daily';
  static const dailyHistory = '/daily/history';
  static const natureTheme = '/theme/nature';
  static const natureLevels = '/theme/nature/levels';
  static const _dailyPrefix = '/daily/';
  static const _themePrefix = '/theme/';

  static String themeDetail(String themeId) {
    return '$_themePrefix$themeId';
  }

  static String themeLevels(String themeId) {
    return '$_themePrefix$themeId/levels';
  }

  static String themeLevel(String themeId, int levelNumber) {
    return '$_themePrefix$themeId/level/$levelNumber';
  }

  static String natureLevel(int levelNumber) {
    return themeLevel(ThemeCatalog.natureThemeId, levelNumber);
  }

  static String dailyReplay(String dateKey) {
    return '$_dailyPrefix$dateKey/replay';
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final dailyReplayDateKey = _parseDailyReplay(settings.name);
    if (dailyReplayDateKey != null) {
      return _route(
        _DailyPuzzleScope(dateKey: dailyReplayDateKey, isReplay: true),
        settings,
      );
    }

    final levelRoute = _parseThemeLevel(settings.name);
    if (levelRoute != null) {
      return _route(
        _createGameScreen(levelRoute.themeId, levelRoute.levelNumber),
        settings,
      );
    }

    final levelMapThemeId = _parseThemeLevelMap(settings.name);
    if (levelMapThemeId != null) {
      return _route(LevelMapScreen(themeId: levelMapThemeId), settings);
    }

    final themeId = _parseThemeDetail(settings.name);
    if (themeId != null) {
      return _route(ThemeDetailScreen(themeId: themeId), settings);
    }

    return switch (settings.name) {
      splash => _route(const SplashScreen(), settings),
      home => _route(const HomeScreen(), settings),
      themes => _route(const ThemeSelectionScreen(), settings),
      AppRoutes.settings => _route(const SettingsScreen(), settings),
      dailyPuzzle => _route(const _DailyPuzzleScope(), settings),
      dailyHistory => _route(const DailyHistoryScreen(), settings),
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

  static Widget _createGameScreen(String themeId, int levelNumber) {
    return _ThemeGameScope(themeId: themeId, levelNumber: levelNumber);
  }

  static _ThemeLevelRoute? _parseThemeLevel(String? routeName) {
    if (routeName == null || !routeName.startsWith(_themePrefix)) {
      return null;
    }

    final parts = routeName.substring(_themePrefix.length).split('/');
    if (parts.length != 3 || parts[1] != 'level') {
      return null;
    }

    final theme = ThemeCatalog.themeById(parts[0]);
    if (theme == null || !theme.isAvailable) {
      return null;
    }

    final parsed = int.tryParse(parts[2]);
    if (parsed == null) {
      return null;
    }

    return _ThemeLevelRoute(
      themeId: theme.id,
      levelNumber: parsed.clamp(1, theme.levels.length).toInt(),
    );
  }

  static String? _parseThemeLevelMap(String? routeName) {
    if (routeName == null || !routeName.startsWith(_themePrefix)) {
      return null;
    }

    final parts = routeName.substring(_themePrefix.length).split('/');
    if (parts.length != 2 || parts[1] != 'levels') {
      return null;
    }

    final theme = ThemeCatalog.themeById(parts[0]);
    if (theme == null || !theme.isAvailable) {
      return null;
    }
    return theme.id;
  }

  static String? _parseThemeDetail(String? routeName) {
    if (routeName == null || !routeName.startsWith(_themePrefix)) {
      return null;
    }

    final themeId = routeName.substring(_themePrefix.length);
    if (themeId.isEmpty || themeId.contains('/')) {
      return null;
    }

    final theme = ThemeCatalog.themeById(themeId);
    return theme?.id;
  }

  static String? _parseDailyReplay(String? routeName) {
    if (routeName == null ||
        !routeName.startsWith(_dailyPrefix) ||
        !routeName.endsWith('/replay')) {
      return null;
    }

    final dateKey = routeName
        .substring(_dailyPrefix.length, routeName.length - '/replay'.length)
        .trim();
    if (DailyPuzzleCatalog.parseDateKey(dateKey) == null) {
      return null;
    }
    return dateKey;
  }
}

class _DailyPuzzleScope extends StatelessWidget {
  const _DailyPuzzleScope({this.dateKey, this.isReplay = false});

  final String? dateKey;
  final bool isReplay;

  @override
  Widget build(BuildContext context) {
    final profile = ThemeBoardProfile.forSize(MediaQuery.sizeOf(context));
    final date =
        DailyPuzzleCatalog.parseDateKey(dateKey ?? '') ?? DateTime.now();
    final challenge = DailyPuzzleCatalog.challengeForDate(
      themes: _dailyThemesForProfile(profile),
      date: date,
    );

    return ChangeNotifierProvider(
      create: (_) => GameController(initialLevel: challenge.level),
      child: GameScreen(
        themeId: challenge.theme.id,
        levelNumber: challenge.levelNumber,
        isDailyPuzzle: true,
        isDailyReplay: isReplay,
        dailyPuzzleId: challenge.dateKey,
        dailySubtitle: challenge.subtitle,
      ),
    );
  }

  List<GameTheme> _dailyThemesForProfile(ThemeBoardProfile profile) {
    return [
      ThemeCatalog.natureWorldFor(profile: profile),
      ThemeCatalog.animalWorldFor(profile: profile),
    ];
  }
}

class _ThemeLevelRoute {
  const _ThemeLevelRoute({required this.themeId, required this.levelNumber});

  final String themeId;
  final int levelNumber;
}

class _ThemeGameScope extends StatelessWidget {
  const _ThemeGameScope({required this.themeId, required this.levelNumber});

  final String themeId;
  final int levelNumber;

  @override
  Widget build(BuildContext context) {
    final profile = ThemeBoardProfile.forSize(MediaQuery.sizeOf(context));
    final theme =
        ThemeCatalog.themeById(themeId, profile: profile) ??
        ThemeCatalog.natureWorldFor(profile: profile);
    final clampedLevelNumber = levelNumber
        .clamp(1, theme.levels.length)
        .toInt();
    final initialLevel = theme.levels[clampedLevelNumber - 1];

    return ChangeNotifierProvider(
      create: (_) =>
          GameController(initialLevel: initialLevel, levels: theme.levels),
      child: GameScreen(
        themeId: theme.id,
        levelNumber: initialLevel.levelNumber,
      ),
    );
  }
}
