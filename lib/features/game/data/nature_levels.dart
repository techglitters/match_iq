import 'dart:collection';
import 'dart:math' as math;

import '../domain/models/game_level.dart';
import 'nature_relationships.dart';
import 'themed_level_builder.dart';

typedef GeneratedNatureLevel = GeneratedThemeLevel;
typedef NatureBoardProfile = ThemeBoardProfile;

const natureDefaultBoardProfile = NatureBoardProfile(
  maxRows: 10,
  maxColumns: 10,
  maxPairs: 10,
);

List<GameLevel> createNatureLevels({
  math.Random? random,
  NatureBoardProfile profile = natureDefaultBoardProfile,
}) {
  return NatureLevels.levelsFor(profile);
}

int get natureLevelCount => NatureLevels.totalLevelCount;

GameLevel createNatureLevel({
  required int levelNumber,
  math.Random? random,
  NatureBoardProfile profile = natureDefaultBoardProfile,
}) {
  return NatureLevels.levelFor(levelNumber, profile: profile);
}

List<GeneratedNatureLevel> createGeneratedNatureLevels({
  math.Random? random,
  NatureBoardProfile profile = natureDefaultBoardProfile,
}) {
  return generatedThemedLevels(levels: NatureLevels.levelsFor(profile));
}

GeneratedNatureLevel generateNatureLevel({
  required int levelNumber,
  required int pairCount,
  math.Random? random,
  NatureBoardProfile profile = natureDefaultBoardProfile,
}) {
  return generatedThemeLevelFromGameLevel(
    createNatureLevel(levelNumber: levelNumber, profile: profile),
  );
}

class NatureLevels {
  const NatureLevels._();

  static const totalLevelCount = 100;

  static final Map<String, List<GameLevel>> _levelsByProfile = {};

  static final List<GameLevel> all = levelsFor(natureDefaultBoardProfile);

  static List<GameLevel> levelsFor(NatureBoardProfile profile) {
    final natureProfile = _natureProfile(profile);
    final profileKey =
        '${natureProfile.maxRows}:${natureProfile.maxColumns}:${natureProfile.maxPairs}';
    return _levelsByProfile.putIfAbsent(
      profileKey,
      () => _LazyNatureLevelList(
        levelCount: totalLevelCount,
        profile: natureProfile,
      ),
    );
  }

  static GameLevel levelFor(
    int levelNumber, {
    NatureBoardProfile profile = natureDefaultBoardProfile,
  }) {
    final natureProfile = _natureProfile(profile);
    return buildThemedLevel(
      idPrefix: 'nature',
      namePrefix: 'Nature',
      relationships: NatureRelationships.all,
      totalLevelCount: totalLevelCount,
      levelNumber: levelNumber,
      profile: natureProfile,
      progression: ThemedLevelProgression.chaptered,
    );
  }

  static List<String> validateAll({
    NatureBoardProfile profile = natureDefaultBoardProfile,
  }) {
    return [
      for (final level in levelsFor(profile))
        ...validateThemedLevelSolutions(level),
    ];
  }

  static NatureBoardProfile _natureProfile(NatureBoardProfile profile) {
    final squareLimit = math.min(10, profile.maxRows);
    return NatureBoardProfile(
      maxRows: squareLimit,
      maxColumns: squareLimit,
      maxPairs: math.max(8, profile.maxPairs),
    );
  }
}

class _LazyNatureLevelList extends ListBase<GameLevel> {
  _LazyNatureLevelList({required int levelCount, required this.profile})
    : _length = levelCount,
      _cache = List<GameLevel?>.filled(levelCount, null);

  final int _length;
  final NatureBoardProfile profile;
  final List<GameLevel?> _cache;

  @override
  int get length => _length;

  @override
  set length(int value) => throw UnsupportedError('Nature levels are fixed.');

  @override
  GameLevel operator [](int index) {
    RangeError.checkValidIndex(index, this);
    return _cache[index] ??= NatureLevels.levelFor(index + 1, profile: profile);
  }

  @override
  void operator []=(int index, GameLevel value) {
    throw UnsupportedError('Nature levels are read-only.');
  }
}

List<String> validateLevelSolutions(GameLevel level) {
  return validateThemedLevelSolutions(level);
}
