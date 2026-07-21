import 'theme_progress.dart';

class AppProgressData {
  const AppProgressData({
    required this.activeThemeId,
    required this.lastPlayedThemeId,
    required this.lastPlayedLevelNumber,
    required this.hasSeenHome,
    required this.themes,
  });

  const AppProgressData.initial()
    : activeThemeId = 'nature',
      lastPlayedThemeId = null,
      lastPlayedLevelNumber = null,
      hasSeenHome = false,
      themes = const {'nature': ThemeProgress.initial()};

  final String activeThemeId;
  final String? lastPlayedThemeId;
  final int? lastPlayedLevelNumber;
  final bool hasSeenHome;
  final Map<String, ThemeProgress> themes;

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
    );
  }

  Map<String, Object?> toJson() {
    return {
      'activeThemeId': activeThemeId,
      'lastPlayedThemeId': lastPlayedThemeId,
      'lastPlayedLevelNumber': lastPlayedLevelNumber,
      'hasSeenHome': hasSeenHome,
      'themes': {
        for (final entry in themes.entries) entry.key: entry.value.toJson(),
      },
    };
  }

  static AppProgressData fromJson(Map<String, Object?> json) {
    final rawThemes = json['themes'];
    final themes = <String, ThemeProgress>{};

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

    return AppProgressData(
      activeThemeId: json['activeThemeId'] as String? ?? 'nature',
      lastPlayedThemeId: json['lastPlayedThemeId'] as String?,
      lastPlayedLevelNumber: json['lastPlayedLevelNumber'] as int?,
      hasSeenHome: json['hasSeenHome'] as bool? ?? false,
      themes: Map<String, ThemeProgress>.unmodifiable({
        'nature': const ThemeProgress.initial(),
        ...themes,
      }),
    );
  }
}
