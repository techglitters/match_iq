import '../../daily/domain/daily_puzzle_result.dart';
import 'theme_progress.dart';

class AppProgressData {
  const AppProgressData({
    required this.activeThemeId,
    required this.lastPlayedThemeId,
    required this.lastPlayedLevelNumber,
    required this.hasSeenHome,
    required this.themes,
    this.dailyPuzzles = const {},
    this.showSolutionPaths = false,
    this.freePlayMode = false,
  });

  const AppProgressData.initial()
    : activeThemeId = 'nature',
      lastPlayedThemeId = null,
      lastPlayedLevelNumber = null,
      hasSeenHome = false,
      themes = const {
        'nature': ThemeProgress.initial(),
        'animals': ThemeProgress.initial(),
      },
      dailyPuzzles = const {},
      showSolutionPaths = false,
      freePlayMode = false;

  final String activeThemeId;
  final String? lastPlayedThemeId;
  final int? lastPlayedLevelNumber;
  final bool hasSeenHome;
  final Map<String, ThemeProgress> themes;
  final Map<String, DailyPuzzleResult> dailyPuzzles;
  final bool showSolutionPaths;
  final bool freePlayMode;

  ThemeProgress themeProgress(String themeId) {
    return themes[themeId] ?? const ThemeProgress.initial();
  }

  AppProgressData copyWith({
    String? activeThemeId,
    String? lastPlayedThemeId,
    int? lastPlayedLevelNumber,
    bool clearLastPlayedLevel = false,
    bool? hasSeenHome,
    Map<String, ThemeProgress>? themes,
    Map<String, DailyPuzzleResult>? dailyPuzzles,
    bool? showSolutionPaths,
    bool? freePlayMode,
  }) {
    return AppProgressData(
      activeThemeId: activeThemeId ?? this.activeThemeId,
      lastPlayedThemeId: clearLastPlayedLevel
          ? null
          : lastPlayedThemeId ?? this.lastPlayedThemeId,
      lastPlayedLevelNumber: clearLastPlayedLevel
          ? null
          : lastPlayedLevelNumber ?? this.lastPlayedLevelNumber,
      hasSeenHome: hasSeenHome ?? this.hasSeenHome,
      themes: themes ?? this.themes,
      dailyPuzzles: dailyPuzzles ?? this.dailyPuzzles,
      showSolutionPaths: showSolutionPaths ?? this.showSolutionPaths,
      freePlayMode: freePlayMode ?? this.freePlayMode,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'activeThemeId': activeThemeId,
      'lastPlayedThemeId': lastPlayedThemeId,
      'lastPlayedLevelNumber': lastPlayedLevelNumber,
      'hasSeenHome': hasSeenHome,
      'showSolutionPaths': showSolutionPaths,
      'freePlayMode': freePlayMode,
      'themes': {
        for (final entry in themes.entries) entry.key: entry.value.toJson(),
      },
      'dailyPuzzles': {
        for (final entry in dailyPuzzles.entries)
          entry.key: entry.value.toJson(),
      },
    };
  }

  static AppProgressData fromJson(Map<String, Object?> json) {
    final rawThemes = json['themes'];
    final rawDailyPuzzles = json['dailyPuzzles'];
    final themes = <String, ThemeProgress>{};
    final dailyPuzzles = <String, DailyPuzzleResult>{};

    if (rawThemes is Map) {
      for (final entry in rawThemes.entries) {
        final value = entry.value;
        if (value is Map) {
          themes['${entry.key}'] = ThemeProgress.fromJson(
            Map<String, Object?>.from(value),
          );
        }
      }
    }

    if (rawDailyPuzzles is Map) {
      for (final entry in rawDailyPuzzles.entries) {
        final value = entry.value;
        if (value is Map) {
          dailyPuzzles['${entry.key}'] = DailyPuzzleResult.fromJson(
            Map<String, Object?>.from(value),
          );
        }
      }
    }

    return AppProgressData(
      activeThemeId: json['activeThemeId'] as String? ?? 'nature',
      lastPlayedThemeId: json['lastPlayedThemeId'] as String?,
      lastPlayedLevelNumber: json['lastPlayedLevelNumber'] as int?,
      hasSeenHome: json['hasSeenHome'] as bool? ?? false,
      showSolutionPaths: json['showSolutionPaths'] as bool? ?? false,
      freePlayMode: json['freePlayMode'] as bool? ?? false,
      themes: Map<String, ThemeProgress>.unmodifiable({
        'nature': const ThemeProgress.initial(),
        'animals': const ThemeProgress.initial(),
        ...themes,
      }),
      dailyPuzzles: Map<String, DailyPuzzleResult>.unmodifiable(dailyPuzzles),
    );
  }
}
