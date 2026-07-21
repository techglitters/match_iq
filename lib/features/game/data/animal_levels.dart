import 'dart:math' as math;

import '../domain/models/game_level.dart';
import 'animal_relationships.dart';
import 'themed_level_builder.dart';

typedef GeneratedAnimalLevel = GeneratedThemeLevel;
typedef AnimalBoardProfile = ThemeBoardProfile;

List<GameLevel> createAnimalLevels({
  math.Random? random,
  AnimalBoardProfile profile = AnimalBoardProfile.large,
}) {
  return AnimalLevels.levelsFor(profile);
}

int get animalLevelCount => AnimalLevels.totalLevelCount;

GameLevel createAnimalLevel({
  required int levelNumber,
  math.Random? random,
  AnimalBoardProfile profile = AnimalBoardProfile.large,
}) {
  return AnimalLevels.levelFor(levelNumber, profile: profile);
}

List<GeneratedAnimalLevel> createGeneratedAnimalLevels({
  math.Random? random,
  AnimalBoardProfile profile = AnimalBoardProfile.large,
}) {
  return generatedThemedLevels(levels: AnimalLevels.levelsFor(profile));
}

GeneratedAnimalLevel generateAnimalLevel({
  required int levelNumber,
  required int pairCount,
  math.Random? random,
  AnimalBoardProfile profile = AnimalBoardProfile.large,
}) {
  return generatedThemeLevelFromGameLevel(
    createAnimalLevel(levelNumber: levelNumber, profile: profile),
  );
}

class AnimalLevels {
  const AnimalLevels._();

  static const totalLevelCount = 15;

  static final List<GameLevel> all = levelsFor(AnimalBoardProfile.large);

  static List<GameLevel> levelsFor(AnimalBoardProfile profile) {
    return buildThemedLevels(
      idPrefix: 'animals',
      namePrefix: 'Animal',
      relationships: AnimalRelationships.all,
      totalLevelCount: totalLevelCount,
      profile: profile,
    );
  }

  static GameLevel levelFor(
    int levelNumber, {
    AnimalBoardProfile profile = AnimalBoardProfile.large,
  }) {
    return buildThemedLevel(
      idPrefix: 'animals',
      namePrefix: 'Animal',
      relationships: AnimalRelationships.all,
      totalLevelCount: totalLevelCount,
      levelNumber: levelNumber,
      profile: profile,
    );
  }

  static List<String> validateAll({
    AnimalBoardProfile profile = AnimalBoardProfile.large,
  }) {
    return [
      for (final level in levelsFor(profile))
        ...validateThemedLevelSolutions(level),
    ];
  }
}
