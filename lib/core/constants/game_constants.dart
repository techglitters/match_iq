import 'package:flutter/material.dart';

class GameConstants {
  const GameConstants._();

  static const int boardRows = 5;
  static const int boardColumns = 5;
  static const int startingPairsPerLevel = 3;
  static const int minimumLineSegmentsPerPath = 2;
  static int get minimumCellsPerPath => minimumLineSegmentsPerPath + 1;
  static const int minimumCellsToCompletePath = 2;
  static int get maxPairsPerLevel =>
      boardRows * boardColumns ~/ minimumCellsPerPath;
  static const Duration splashDuration = Duration(milliseconds: 1200);
  static const Duration pathRollbackDuration = Duration(milliseconds: 260);
  static const Duration wrongPathRollbackDuration = Duration(milliseconds: 420);
  static const double endpointIconScale = 0.72;

  static const Map<String, Color> relationshipColors = {
    'seed_to_flower': Color(0xFF43A047),
    'tree_to_fruit': Color(0xFFF57C00),
    'cloud_to_rain': Color(0xFF1E88E5),
    'sun_to_plant': Color(0xFFFFB300),
    'mountain_to_river': Color(0xFF26A69A),
    'leaf_to_soil': Color(0xFF8D6E63),
    'bird_to_nest': Color(0xFF7CB342),
    'snow_to_mountain': Color(0xFF90CAF9),
    'wind_to_leaf': Color(0xFF4DD0E1),
    'fire_to_smoke': Color(0xFFE53935),
    'car_to_road': Color(0xFF5C6BC0),
    'family_to_home': Color(0xFFEC407A),
  };

  static Color colorForRelationship(String relationshipId) {
    return relationshipColors[relationshipId] ?? const Color(0xFF7E57C2);
  }
}
