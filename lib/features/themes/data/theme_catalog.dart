import 'package:flutter/material.dart';

import '../../game/data/animal_levels.dart';
import '../../game/data/nature_levels.dart';
import '../../game/data/themed_level_builder.dart';
import '../domain/game_theme.dart';

class ThemeCatalog {
  const ThemeCatalog._();

  static const natureThemeId = 'nature';
  static const animalThemeId = 'animals';

  static GameTheme get natureWorld => natureWorldFor();

  static GameTheme get animalWorld => animalWorldFor();

  static GameTheme natureWorldFor({
    ThemeBoardProfile profile = ThemeBoardProfile.large,
  }) {
    return GameTheme(
      id: natureThemeId,
      name: 'Nature World',
      description: 'Connect things that belong together in nature.',
      primaryColor: const Color(0xFF2E7D32),
      secondaryColor: const Color(0xFF81C784),
      accentColor: const Color(0xFFFFC107),
      icon: Icons.local_florist,
      levels: createNatureLevels(profile: profile),
      isAvailable: true,
    );
  }

  static GameTheme animalWorldFor({
    ThemeBoardProfile profile = ThemeBoardProfile.large,
  }) {
    return GameTheme(
      id: animalThemeId,
      name: 'Animal World',
      description: 'Match animals with growth, homes, food, and habitats.',
      primaryColor: const Color(0xFF8D5A2B),
      secondaryColor: const Color(0xFFD8A86D),
      accentColor: const Color(0xFF4DB6AC),
      icon: Icons.pets,
      levels: createAnimalLevels(profile: profile),
      isAvailable: true,
    );
  }

  static const lockedThemes = [
    GameTheme(
      id: 'food',
      name: 'Food World',
      description: 'Food, farms, kitchens, and meals.',
      primaryColor: Color(0xFFE65100),
      secondaryColor: Color(0xFFFFB74D),
      accentColor: Color(0xFF66BB6A),
      icon: Icons.restaurant,
      levels: [],
      isAvailable: false,
    ),
    GameTheme(
      id: 'home',
      name: 'Home World',
      description: 'Objects and places around home.',
      primaryColor: Color(0xFF5C6BC0),
      secondaryColor: Color(0xFF9FA8DA),
      accentColor: Color(0xFFF06292),
      icon: Icons.home_rounded,
      levels: [],
      isAvailable: false,
    ),
  ];

  static List<GameTheme> get all {
    return List<GameTheme>.unmodifiable([
      natureWorld,
      animalWorld,
      ...lockedThemes,
    ]);
  }

  static GameTheme? themeById(
    String themeId, {
    ThemeBoardProfile profile = ThemeBoardProfile.large,
  }) {
    return switch (themeId) {
      natureThemeId => natureWorldFor(profile: profile),
      animalThemeId => animalWorldFor(profile: profile),
      'food' => lockedThemes[0],
      'home' => lockedThemes[1],
      _ => null,
    };
  }
}
