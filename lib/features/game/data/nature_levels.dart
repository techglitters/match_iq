import 'dart:math' as math;

import '../domain/models/game_level.dart';
import 'nature_relationships.dart';
import 'themed_level_builder.dart';

typedef GeneratedNatureLevel = GeneratedThemeLevel;
typedef NatureBoardProfile = ThemeBoardProfile;

List<GameLevel> createNatureLevels({
  math.Random? random,
  NatureBoardProfile profile = NatureBoardProfile.large,
}) {
  return NatureLevels.levelsFor(profile);
}

int get natureLevelCount => NatureLevels.totalLevelCount;

GameLevel createNatureLevel({
  required int levelNumber,
  math.Random? random,
  NatureBoardProfile profile = NatureBoardProfile.large,
}) {
  return NatureLevels.levelFor(levelNumber, profile: profile);
}

List<GeneratedNatureLevel> createGeneratedNatureLevels({
  math.Random? random,
  NatureBoardProfile profile = NatureBoardProfile.large,
}) {
  return generatedThemedLevels(levels: NatureLevels.levelsFor(profile));
}

GeneratedNatureLevel generateNatureLevel({
  required int levelNumber,
  required int pairCount,
  math.Random? random,
  NatureBoardProfile profile = NatureBoardProfile.large,
}) {
  return generatedThemeLevelFromGameLevel(
    createNatureLevel(levelNumber: levelNumber, profile: profile),
  );
}

class NatureLevels {
  const NatureLevels._();

  static const totalLevelCount = 15;

  static final List<GameLevel> all = levelsFor(NatureBoardProfile.large);

  static List<GameLevel> levelsFor(NatureBoardProfile profile) {
    return buildThemedLevels(
      idPrefix: 'nature',
      namePrefix: 'Nature',
      relationships: NatureRelationships.all,
      totalLevelCount: totalLevelCount,
      profile: profile,
    );
  }

  static GameLevel levelFor(
    int levelNumber, {
    NatureBoardProfile profile = NatureBoardProfile.large,
  }) {
    return buildThemedLevel(
      idPrefix: 'nature',
      namePrefix: 'Nature',
      relationships: NatureRelationships.all,
      totalLevelCount: totalLevelCount,
      levelNumber: levelNumber,
      profile: profile,
    );
  }

  static List<String> validateAll({
    NatureBoardProfile profile = NatureBoardProfile.large,
  }) {
    return [
      for (final level in levelsFor(profile))
        ...validateThemedLevelSolutions(level),
    ];
  }
}

List<String> validateLevelSolutions(GameLevel level) {
  return validateThemedLevelSolutions(level);
}
