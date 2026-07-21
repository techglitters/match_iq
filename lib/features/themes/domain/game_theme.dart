import 'package:flutter/material.dart';

import '../../game/domain/models/game_level.dart';

class GameTheme {
  const GameTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.icon,
    required this.levels,
    required this.isAvailable,
  });

  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final IconData icon;
  final List<GameLevel> levels;
  final bool isAvailable;

  int get maxStars => levels.length * 3;
}
