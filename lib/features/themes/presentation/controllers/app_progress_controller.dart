import 'package:flutter/foundation.dart';

import '../../../../core/persistence/progress_store.dart';
import '../../../daily/data/daily_puzzle_catalog.dart';
import '../../../daily/domain/daily_puzzle_challenge.dart';
import '../../../daily/domain/daily_puzzle_history_entry.dart';
import '../../../daily/domain/daily_puzzle_result.dart';
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

  bool get showSolutionPaths => _data.showSolutionPaths;

  bool get freePlayMode => _data.freePlayMode;

  bool get bypassFullBoardCoverage => _data.bypassFullBoardCoverage;

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

  String dailyPuzzleDateKey([DateTime? date]) {
    return DailyPuzzleCatalog.dateKey(date);
  }

  DailyPuzzleChallenge dailyPuzzleChallenge({DateTime? date}) {
    return DailyPuzzleCatalog.challengeForDate(themes: themes, date: date);
  }

  int dailyPuzzleLevelNumber({DateTime? date, String? themeId}) {
    if (themeId == null) {
      return dailyPuzzleChallenge(date: date).levelNumber;
    }

    final theme = themeById(themeId) ?? ThemeCatalog.natureWorld;
    return DailyPuzzleCatalog.levelNumberForDate(
      date ?? DateTime.now(),
      theme.levels.length,
    );
  }

  DailyPuzzleResult dailyPuzzleResult({DateTime? date, String? themeId}) {
    final dateKey = dailyPuzzleDateKey(date);
    final challenge = themeId == null ? dailyPuzzleChallenge(date: date) : null;
    final resolvedThemeId = themeId ?? challenge!.theme.id;
    final levelNumber =
        challenge?.levelNumber ??
        dailyPuzzleLevelNumber(date: date, themeId: resolvedThemeId);
    return _data.dailyPuzzles[dateKey] ??
        DailyPuzzleResult.empty(
          dateKey: dateKey,
          themeId: resolvedThemeId,
          levelNumber: levelNumber,
        );
  }

  List<DailyPuzzleHistoryEntry> dailyPuzzleHistory({
    int days = 7,
    DateTime? today,
  }) {
    final anchor = _localDate(today ?? DateTime.now());
    return List<DailyPuzzleHistoryEntry>.unmodifiable([
      for (var index = 0; index < days; index += 1)
        _dailyPuzzleHistoryEntry(
          date: anchor.subtract(Duration(days: index)),
          isToday: index == 0,
        ),
    ]);
  }

  int dailyStreak({DateTime? today}) {
    var cursor = _localDate(today ?? DateTime.now());
    if (!_isDailyCompleted(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var count = 0;
    while (_isDailyCompleted(cursor)) {
      count += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  int bestDailyStreak() {
    final completedDates = [
      for (final result in _data.dailyPuzzles.values)
        if (result.completed) DailyPuzzleCatalog.parseDateKey(result.dateKey),
    ].whereType<DateTime>().toList()..sort();

    var best = 0;
    var current = 0;
    DateTime? previous;

    for (final date in completedDates) {
      if (previous == null || date.difference(previous).inDays == 1) {
        current += 1;
      } else if (date.difference(previous).inDays == 0) {
        continue;
      } else {
        current = 1;
      }
      if (current > best) {
        best = current;
      }
      previous = date;
    }

    return best;
  }

  int continueLevelNumber() {
    final themeId = _data.lastPlayedThemeId ?? ThemeCatalog.natureThemeId;
    final theme = themeById(themeId) ?? ThemeCatalog.natureWorld;
    final progress = progressForTheme(theme.id);
    final lastPlayed = _data.lastPlayedLevelNumber;

    if (lastPlayed != null && isLevelUnlocked(theme.id, lastPlayed)) {
      return lastPlayed.clamp(1, theme.levels.length).toInt();
    }

    return progress.highestUnlockedLevel.clamp(1, theme.levels.length).toInt();
  }

  int playLevelNumber(String themeId) {
    final theme = themeById(themeId) ?? ThemeCatalog.natureWorld;
    if (_data.freePlayMode) {
      final lastPlayed = _data.lastPlayedLevelNumber;
      if (_data.lastPlayedThemeId == theme.id && lastPlayed != null) {
        return lastPlayed.clamp(1, theme.levels.length).toInt();
      }
    }

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
    if (_data.freePlayMode) {
      final theme = themeById(themeId);
      return theme != null &&
          theme.isAvailable &&
          levelNumber >= 1 &&
          levelNumber <= theme.levels.length;
    }
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

  Future<void> setShowSolutionPaths(bool value) async {
    if (_data.showSolutionPaths == value) {
      return;
    }
    _data = _data.copyWith(showSolutionPaths: value);
    await _saveAndNotify();
  }

  Future<void> setFreePlayMode(bool value) async {
    if (_data.freePlayMode == value) {
      return;
    }
    _data = _data.copyWith(freePlayMode: value);
    await _saveAndNotify();
  }

  Future<void> setBypassFullBoardCoverage(bool value) async {
    if (_data.bypassFullBoardCoverage == value) {
      return;
    }
    _data = _data.copyWith(bypassFullBoardCoverage: value);
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

  Future<LevelCompletionResult> completeDailyPuzzle({
    required String dateKey,
    required String themeId,
    required int levelNumber,
    required int earnedStars,
    required int moves,
  }) async {
    final currentResult =
        _data.dailyPuzzles[dateKey] ??
        DailyPuzzleResult.empty(
          dateKey: dateKey,
          themeId: themeId,
          levelNumber: levelNumber,
        );
    final savedResult = currentResult.complete(
      earnedStars: earnedStars,
      moves: moves,
    );
    final dailyPuzzles = Map<String, DailyPuzzleResult>.of(_data.dailyPuzzles)
      ..[dateKey] = savedResult;

    _data = _data.copyWith(
      activeThemeId: themeId,
      dailyPuzzles: Map<String, DailyPuzzleResult>.unmodifiable(dailyPuzzles),
    );

    await _saveAndNotify();

    return LevelCompletionResult(
      levelNumber: levelNumber,
      earnedStars: earnedStars,
      savedStars: savedResult.stars,
      moves: moves,
      bestMoves: savedResult.bestMoves ?? moves,
      unlockedLevel: levelNumber,
      isThemeComplete: false,
    );
  }

  Future<void> _saveAndNotify() async {
    await _store.save(_data);
    notifyListeners();
  }

  DailyPuzzleHistoryEntry _dailyPuzzleHistoryEntry({
    required DateTime date,
    required bool isToday,
  }) {
    final challenge = dailyPuzzleChallenge(date: date);
    final result =
        _data.dailyPuzzles[challenge.dateKey] ??
        DailyPuzzleResult.empty(
          dateKey: challenge.dateKey,
          themeId: challenge.theme.id,
          levelNumber: challenge.levelNumber,
        );

    return DailyPuzzleHistoryEntry(
      date: date,
      challenge: challenge,
      result: result,
      isToday: isToday,
    );
  }

  bool _isDailyCompleted(DateTime date) {
    return _data.dailyPuzzles[dailyPuzzleDateKey(date)]?.completed ?? false;
  }

  DateTime _localDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
