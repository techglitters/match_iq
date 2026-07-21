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
    'seed_to_flower': Color(0xFF43A047),
    'tree_to_fruit': Color(0xFFF57C00),
    'cloud_to_rain': Color(0xFF1E88E5),
    'sun_to_plant': Color(0xFFFFB300),
    'flower_to_bee': Color(0xFFFFC107),
    'flower_to_butterfly': Color(0xFFAB47BC),
    'leaf_to_tree': Color(0xFF66BB6A),
    'water_to_plant': Color(0xFF29B6F6),
    'rain_to_plant': Color(0xFF26A69A),
    'sun_to_flower': Color(0xFFFFA000),
    'nest_to_bird': Color(0xFF8BC34A),
    'moon_to_night': Color(0xFF5C6BC0),
    'mountain_to_snow': Color(0xFF90CAF9),
    'garden_to_flower': Color(0xFFEC407A),
    'mountain_to_river': Color(0xFF26A69A),
    'leaf_to_soil': Color(0xFF8D6E63),
    'bird_to_nest': Color(0xFF7CB342),
    'snow_to_mountain': Color(0xFF90CAF9),
    'wind_to_leaf': Color(0xFF4DD0E1),
    'fire_to_smoke': Color(0xFFE53935),
    'car_to_road': Color(0xFF5C6BC0),
    'family_to_home': Color(0xFFEC407A),
    'puppy_to_dog': Color(0xFF8D6E63),
    'kitten_to_cat': Color(0xFFFF8A65),
    'caterpillar_to_butterfly': Color(0xFFAB47BC),
    'tadpole_to_frog': Color(0xFF26A69A),
    'fish_to_water': Color(0xFF039BE5),
    'duck_to_water': Color(0xFFFFB300),
    'bee_to_flower': Color(0xFFFFC107),
    'sheep_to_wool': Color(0xFF78909C),
    'cow_to_grass': Color(0xFF7CB342),
    'horse_to_stable': Color(0xFFA1887F),
    'bear_to_cave': Color(0xFF6D4C41),
    'rabbit_to_carrot': Color(0xFFFF7043),
    'butterfly_to_flower': Color(0xFFEC407A),
    'frog_to_water': Color(0xFF43A047),
  };

  static const List<Color> fallbackRelationshipPalette = [
    Color(0xFF43A047),
    Color(0xFFF57C00),
    Color(0xFF1E88E5),
    Color(0xFFAB47BC),
    Color(0xFF26A69A),
    Color(0xFFE53935),
    Color(0xFF5C6BC0),
    Color(0xFFEC407A),
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
