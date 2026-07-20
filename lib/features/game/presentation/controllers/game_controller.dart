import 'package:flutter/foundation.dart';

import '../../../../core/constants/game_constants.dart';
import '../../domain/models/board_position.dart';
import '../../domain/models/game_level.dart';
import '../../domain/models/game_path.dart';
import '../../domain/models/level_pair_placement.dart';

class GameController extends ChangeNotifier {
  GameController({required GameLevel initialLevel, List<GameLevel>? levels})
    : levels = List<GameLevel>.unmodifiable(levels ?? [initialLevel]) {
    _validateLevels(this.levels);
    currentLevelIndex = _levelIndexFor(initialLevel);
    _loadLevel(this.levels[currentLevelIndex], shouldNotify: false);
  }

  final List<GameLevel> levels;
  int currentLevelIndex = 0;
  late GameLevel level;
  Map<String, GamePath> completedPaths = <String, GamePath>{};
  List<String> completedPathOrder = <String>[];
  List<BoardPosition> activePath = <BoardPosition>[];
  String? activeRelationshipId;
  BoardPosition? activeStartPosition;
  bool isDragging = false;
  int moves = 0;
  bool isLevelComplete = false;

  bool _hasDragAttempt = false;

  int get connectedPairCount => completedPaths.length;

  int get totalPairCount => level.pairs.length;

  int get visibleLevelNumber => currentLevelIndex + 1;

  bool get hasNextLevel => currentLevelIndex < levels.length - 1;

  bool get hasProgress {
    return completedPaths.isNotEmpty || activePath.isNotEmpty || moves > 0;
  }

  GamePath? get activeGamePath {
    final relationshipId = activeRelationshipId;
    if (relationshipId == null || activePath.isEmpty) {
      return null;
    }

    return GamePath(
      relationshipId: relationshipId,
      cells: List<BoardPosition>.unmodifiable(activePath),
      isComplete: false,
    );
  }

  void loadLevel(GameLevel newLevel) {
    currentLevelIndex = _levelIndexFor(newLevel);
    _loadLevel(newLevel, shouldNotify: true);
  }

  bool goToNextLevel() {
    if (!hasNextLevel || !isLevelComplete) {
      return false;
    }

    currentLevelIndex += 1;
    _loadLevel(levels[currentLevelIndex], shouldNotify: true);
    return true;
  }

  bool startPath(BoardPosition position) {
    if (isLevelComplete) {
      return false;
    }

    _hasDragAttempt = true;
    final placement = findPlacementAt(position);
    if (placement == null) {
      _clearActivePath(keepDragAttempt: true);
      notifyListeners();
      return false;
    }

    final relationshipId = placement.relationship.id;
    if (completedPaths.containsKey(relationshipId)) {
      completedPaths.remove(relationshipId);
      completedPathOrder.remove(relationshipId);
      isLevelComplete = false;
    }

    activeRelationshipId = relationshipId;
    activeStartPosition = position;
    activePath = <BoardPosition>[position];
    isDragging = true;
    notifyListeners();
    return true;
  }

  bool extendPath(BoardPosition position) {
    if (!isDragging || activePath.isEmpty || isLevelComplete) {
      return false;
    }

    final lastPosition = activePath.last;
    if (position == lastPosition) {
      return false;
    }

    if (activePath.length > 1 &&
        position == activePath[activePath.length - 2]) {
      activePath = List<BoardPosition>.of(activePath)..removeLast();
      notifyListeners();
      return true;
    }

    if (!canAddPosition(position)) {
      return false;
    }

    activePath = List<BoardPosition>.of(activePath)..add(position);
    notifyListeners();
    return true;
  }

  bool finishPath() {
    if (!_hasDragAttempt && !isDragging) {
      return false;
    }

    moves += 1;

    final relationshipId = activeRelationshipId;
    final isValidPath =
        relationshipId != null &&
        activePath.length > 1 &&
        isCorrectTarget(activePath.last);

    if (isValidPath) {
      completedPaths = Map<String, GamePath>.of(completedPaths)
        ..[relationshipId] = GamePath(
          relationshipId: relationshipId,
          cells: List<BoardPosition>.unmodifiable(activePath),
          isComplete: true,
        );
      if (!completedPathOrder.contains(relationshipId)) {
        completedPathOrder = <String>[...completedPathOrder, relationshipId];
      }
      _clearActivePath();
      checkLevelCompletion();
      notifyListeners();
      return true;
    }

    _clearActivePath();
    notifyListeners();
    return false;
  }

  void cancelActivePath() {
    if (!_hasDragAttempt && !isDragging && activePath.isEmpty) {
      return;
    }
    _clearActivePath();
    notifyListeners();
  }

  bool undoLastPath() {
    if (completedPathOrder.isEmpty) {
      return false;
    }

    final relationshipId = completedPathOrder.last;
    completedPathOrder = List<String>.of(completedPathOrder)..removeLast();
    completedPaths = Map<String, GamePath>.of(completedPaths)
      ..remove(relationshipId);
    isLevelComplete = false;
    notifyListeners();
    return true;
  }

  void restartLevel() {
    _resetState();
    notifyListeners();
  }

  bool isPositionOccupied(BoardPosition position) {
    return completedPaths.values.any((path) => path.cells.contains(position));
  }

  bool canAddPosition(BoardPosition position) {
    if (activePath.isEmpty || !_isPositionInsideBoard(position)) {
      return false;
    }

    final lastPosition = activePath.last;
    if (!arePositionsAdjacent(lastPosition, position)) {
      return false;
    }

    if (activePath.contains(position) || isPositionOccupied(position)) {
      return false;
    }

    if (!isEndpoint(position)) {
      return true;
    }

    return isCorrectTarget(position);
  }

  bool arePositionsAdjacent(BoardPosition first, BoardPosition second) {
    final rowDistance = (first.row - second.row).abs();
    final columnDistance = (first.column - second.column).abs();
    return rowDistance + columnDistance == 1;
  }

  LevelPairPlacement? findPlacementAt(BoardPosition position) {
    for (final placement in level.pairs) {
      if (placement.sourcePosition == position ||
          placement.targetPosition == position) {
        return placement;
      }
    }
    return null;
  }

  bool isEndpoint(BoardPosition position) {
    return findPlacementAt(position) != null;
  }

  bool isCorrectTarget(BoardPosition position) {
    final relationshipId = activeRelationshipId;
    final startPosition = activeStartPosition;
    if (relationshipId == null || startPosition == null) {
      return false;
    }

    LevelPairPlacement? placement;
    for (final pair in level.pairs) {
      if (pair.relationship.id == relationshipId) {
        placement = pair;
        break;
      }
    }

    if (placement == null) {
      return false;
    }

    if (startPosition == placement.sourcePosition) {
      return position == placement.targetPosition;
    }

    if (startPosition == placement.targetPosition) {
      return position == placement.sourcePosition;
    }

    return false;
  }

  bool checkLevelCompletion() {
    isLevelComplete = completedPaths.length == level.pairs.length;
    return isLevelComplete;
  }

  void _loadLevel(GameLevel newLevel, {required bool shouldNotify}) {
    _validateLevel(newLevel);

    level = newLevel;
    _resetState();
    if (shouldNotify) {
      notifyListeners();
    }
  }

  void _validateLevels(List<GameLevel> levels) {
    if (levels.isEmpty) {
      throw ArgumentError.value(
        levels.length,
        'levels.length',
        'Must not be 0.',
      );
    }

    for (final level in levels) {
      _validateLevel(level);
    }
  }

  void _validateLevel(GameLevel level) {
    if (level.pairs.length > GameConstants.maxPairsPerLevel) {
      throw ArgumentError.value(
        level.pairs.length,
        'pairs.length',
        'A level can contain at most ${GameConstants.maxPairsPerLevel} pairs.',
      );
    }
  }

  int _levelIndexFor(GameLevel newLevel) {
    for (var index = 0; index < levels.length; index += 1) {
      if (levels[index].id == newLevel.id) {
        return index;
      }
    }
    return 0;
  }

  void _resetState() {
    completedPaths = <String, GamePath>{};
    completedPathOrder = <String>[];
    _clearActivePath();
    moves = 0;
    isLevelComplete = false;
  }

  void _clearActivePath({bool keepDragAttempt = false}) {
    activePath = <BoardPosition>[];
    activeRelationshipId = null;
    activeStartPosition = null;
    isDragging = false;
    _hasDragAttempt = keepDragAttempt;
  }

  bool _isPositionInsideBoard(BoardPosition position) {
    return position.row >= 0 &&
        position.row < level.rows &&
        position.column >= 0 &&
        position.column < level.columns;
  }
}
