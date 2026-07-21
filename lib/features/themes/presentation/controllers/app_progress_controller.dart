import 'package:flutter/foundation.dart';

import '../../../../core/persistence/progress_store.dart';
import '../../data/theme_catalog.dart';
import '../../domain/app_progress_data.dart';
import '../../domain/game_theme.dart';
import '../../domain/level_completion_result.dart';
import '../../domain/theme_progress.dart';

class AppProgressController extends ChangeNotifier {
  AppProgressController({
    required ProgressStore store,
    required List<GameTheme> themes,
  }) : _store = store,
       themes = List<GameTheme>.unmodifiable(themes);

  final ProgressStore _store;
  final List<GameTheme> themes;

  AppProgressData _data = const AppProgressData.initial();
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  AppProgressData get data => _data;

  GameTheme get activeTheme {
    return themeById(_data.activeThemeId) ?? ThemeCatalog.natureWorld;
  }

  GameTheme? themeById(String themeId) {
    for (final theme in themes) {
      if (theme.id == themeId) {
        return theme;
      }
    }
    return null;
  }

  ThemeProgress progressForTheme(String themeId) {
    return _data.themeProgress(themeId);
  }

  bool get hasPlayedLevel {
    return _data.lastPlayedThemeId != null &&
        _data.lastPlayedLevelNumber != null;
  }

  int highestUnlockedLevel(String themeId) {
    return progressForTheme(themeId).highestUnlockedLevel;
  }

  int totalStars(String themeId) {
    return progressForTheme(themeId).totalStars;
  }

  int completedLevelCount(String themeId) {
    return progressForTheme(themeId).completedLevelCount;
  }

  int continueLevelNumber() {
    final themeId = _data.lastPlayedThemeId ?? ThemeCatalog.natureThemeId;
    final theme = themeById(themeId) ?? ThemeCatalog.natureWorld;
    final progress = progressForTheme(theme.id);
    final lastPlayed = _data.lastPlayedLevelNumber;

    if (lastPlayed != null && progress.isUnlocked(lastPlayed)) {
      return lastPlayed.clamp(1, theme.levels.length).toInt();
    }

    return progress.highestUnlockedLevel.clamp(1, theme.levels.length).toInt();
  }

  int playLevelNumber(String themeId) {
    final theme = themeById(themeId) ?? ThemeCatalog.natureWorld;
    final progress = progressForTheme(theme.id);

    for (final level in theme.levels) {
      if (!progress.levelProgress(level.levelNumber).completed) {
        return level.levelNumber
            .clamp(1, progress.highestUnlockedLevel)
            .toInt();
      }
    }

    return theme.levels.length;
  }

  bool isLevelUnlocked(String themeId, int levelNumber) {
    return progressForTheme(themeId).isUnlocked(levelNumber);
  }

  Future<void> load() async {
    _data = await _store.load();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> markHomeSeen() async {
    if (_data.hasSeenHome) {
      return;
    }
    _data = _data.copyWith(hasSeenHome: true);
    await _saveAndNotify();
  }

  Future<void> selectTheme(String themeId) async {
    final theme = themeById(themeId);
    if (theme == null || !theme.isAvailable) {
      return;
    }

    _data = _data.copyWith(activeThemeId: themeId);
    await _saveAndNotify();
  }

  Future<void> recordLevelOpened({
    required String themeId,
    required int levelNumber,
  }) async {
    final theme = themeById(themeId);
    if (theme == null || !theme.isAvailable) {
      return;
    }

    if (!isLevelUnlocked(themeId, levelNumber)) {
      return;
    }

    _data = _data.copyWith(
      activeThemeId: themeId,
      lastPlayedThemeId: themeId,
      lastPlayedLevelNumber: levelNumber.clamp(1, theme.levels.length).toInt(),
    );
    await _saveAndNotify();
  }

  Future<LevelCompletionResult> completeLevel({
    required String themeId,
    required int levelNumber,
    required int moves,
  }) async {
    final theme = themeById(themeId) ?? ThemeCatalog.natureWorld;
    final level = theme.levels[levelNumber - 1];
    final earnedStars = level.starsForMoves(moves);
    final currentProgress = progressForTheme(themeId);
    final nextProgress = currentProgress.completeLevel(
      levelNumber: levelNumber,
      earnedStars: earnedStars,
      moves: moves,
      maxLevel: theme.levels.length,
    );
    final nextThemes = Map<String, ThemeProgress>.of(_data.themes)
      ..[themeId] = nextProgress;

    _data = _data.copyWith(
      activeThemeId: themeId,
      lastPlayedThemeId: themeId,
      lastPlayedLevelNumber: levelNumber,
      themes: Map<String, ThemeProgress>.unmodifiable(nextThemes),
    );

    await _saveAndNotify();

    final savedLevelProgress = nextProgress.levelProgress(levelNumber);
    return LevelCompletionResult(
      levelNumber: levelNumber,
      earnedStars: earnedStars,
      savedStars: savedLevelProgress.stars,
      moves: moves,
      bestMoves: savedLevelProgress.bestMoves ?? moves,
      unlockedLevel: nextProgress.highestUnlockedLevel,
      isThemeComplete: levelNumber >= theme.levels.length,
    );
  }

  Future<void> _saveAndNotify() async {
    await _store.save(_data);
    notifyListeners();
  }
}
