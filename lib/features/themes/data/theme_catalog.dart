import 'package:flutter/material.dart';

import '../../game/data/nature_levels.dart';
import '../domain/game_theme.dart';

class ThemeCatalog {
  const ThemeCatalog._();

  static const natureThemeId = 'nature';

  static final GameTheme natureWorld = GameTheme(
    id: natureThemeId,
    name: 'Nature World',
    description: 'Connect things that belong together in nature.',
    primaryColor: const Color(0xFF2E7D32),
    secondaryColor: const Color(0xFF81C784),
    accentColor: const Color(0xFFFFC107),
    icon: Icons.local_florist,
    levels: createNatureLevels(),
    isAvailable: true,
  );

  static const lockedThemes = [
    GameTheme(
      id: 'animals',
      name: 'Animals World',
      description: 'Animal friends and their homes.',
      primaryColor: Color(0xFF6D4C41),
      secondaryColor: Color(0xFFA1887F),
      accentColor: Color(0xFFFFB74D),
      icon: Icons.pets,
      levels: [],
      isAvailable: false,
    ),
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
    return List<GameTheme>.unmodifiable([natureWorld, ...lockedThemes]);
  }
}
