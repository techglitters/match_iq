import 'package:flutter/material.dart';

class GameConstants {
  const GameConstants._();

  static const int boardRows = 5;
  static const int boardColumns = 5;
  static const int maxBoardRows = 14;
  static const int maxBoardColumns = 8;
  static const int startingPairsPerLevel = 3;
  static const int minimumLineSegmentsPerPath = 2;
  static int get minimumCellsPerPath => minimumLineSegmentsPerPath + 1;
  static const int minimumCellsToCompletePath = 2;
  static int get maxPairsPerLevel =>
      maxBoardRows * maxBoardColumns ~/ minimumCellsPerPath;
  static const Duration splashDuration = Duration(milliseconds: 1200);
  static const Duration pathRollbackDuration = Duration(milliseconds: 260);
  static const Duration wrongPathRollbackDuration = Duration(milliseconds: 420);
  static const double endpointIconScale = 0.72;

  static const Map<String, Color> relationshipColors = {
    'seed_to_flower': Color(0xFFE6194B),
    'tree_to_fruit': Color(0xFF00B8D4),
    'cloud_to_rain': Color(0xFFAEEA00),
    'sun_to_day': Color(0xFF6200EA),
    'flower_to_bee': Color(0xFF1B5E20),
    'nature_caterpillar_to_butterfly': Color(0xFFF032E6),
    'leaf_to_soil': Color(0xFF000075),
    'mountain_to_river': Color(0xFF800000),
    'nest_to_bird': Color(0xFF757575),
    'moon_to_night': Color(0xFF00C853),
    'mountain_to_snow': Color(0xFF808000),
    'wind_to_leaf': Color(0xFFFF6D00),
    'fire_to_smoke': Color(0xFF4363D8),
    'rain_to_rainbow': Color(0xFFFDD835),
    'river_to_ocean': Color(0xFF8E24AA),
    'bird_to_nest': Color(0xFF1B5E20),
    'snow_to_mountain': Color(0xFF4363D8),
    'flower_to_butterfly': Color(0xFFF032E6),
    'leaf_to_tree': Color(0xFF000075),
    'water_to_plant': Color(0xFF800000),
    'rain_to_plant': Color(0xFF757575),
    'sun_to_flower': Color(0xFF00C853),
    'garden_to_flower': Color(0xFF8E24AA),
    'car_to_road': Color(0xFF2962FF),
    'family_to_home': Color(0xFFC51162),
    'puppy_to_dog': Color(0xFFE6194B),
    'kitten_to_cat': Color(0xFF00B8D4),
    'caterpillar_to_butterfly': Color(0xFFAEEA00),
    'tadpole_to_frog': Color(0xFF6200EA),
    'fish_to_water': Color(0xFFF032E6),
    'duck_to_water': Color(0xFF000075),
    'bee_to_flower': Color(0xFF800000),
    'sheep_to_wool': Color(0xFF757575),
    'cow_to_grass': Color(0xFF00C853),
    'horse_to_stable': Color(0xFFFF6D00),
    'bear_to_cave': Color(0xFF808000),
    'rabbit_to_carrot': Color(0xFF4363D8),
    'butterfly_to_flower': Color(0xFFFDD835),
    'frog_to_water': Color(0xFF8E24AA),
  };

  static const List<Color> fallbackRelationshipPalette = [
    Color(0xFFE6194B),
    Color(0xFF00B8D4),
    Color(0xFFAEEA00),
    Color(0xFF6200EA),
    Color(0xFF1B5E20),
    Color(0xFFF032E6),
    Color(0xFF000075),
    Color(0xFF800000),
    Color(0xFF757575),
    Color(0xFF00C853),
    Color(0xFFFF6D00),
    Color(0xFF808000),
    Color(0xFF4363D8),
    Color(0xFFFDD835),
    Color(0xFF8E24AA),
  ];

  static Color colorForRelationship(String relationshipId) {
    final configuredColor = relationshipColors[relationshipId];
    if (configuredColor != null) {
      return configuredColor;
    }

    final paletteIndex =
        relationshipId.hashCode.abs() % fallbackRelationshipPalette.length;
    return fallbackRelationshipPalette[paletteIndex];
  }
}
