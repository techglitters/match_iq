import 'package:flutter/foundation.dart';

import '../../../../core/constants/game_constants.dart';
import '../../domain/models/board_position.dart';
import '../../domain/models/game_level.dart';
import '../../domain/models/game_path.dart';
import '../../domain/models/level_pair_placement.dart';

typedef GameLevelBuilder = GameLevel Function(int levelNumber);

class GameController extends ChangeNotifier {
  GameController({
    required GameLevel initialLevel,
    List<GameLevel>? levels,
    GameLevelBuilder? levelBuilder,
    int? maxLevelCount,
  }) : _levels = List<GameLevel>.of(levels ?? [initialLevel]),
       _levelBuilder = levelBuilder,
       _maxLevelCount = _resolveMaxLevelCount(levels, maxLevelCount) {
    _validateLevels(_levels);
    currentLevelIndex = _levelIndexFor(initialLevel);
    if (currentLevelIndex < 0) {
      _validateLevel(initialLevel);
      _levels.insert(0, initialLevel);
      currentLevelIndex = 0;
    }
    _loadLevel(_levels[currentLevelIndex], shouldNotify: false);
  }

  final List<GameLevel> _levels;
  final GameLevelBuilder? _levelBuilder;
  final int _maxLevelCount;
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

  int get totalBoardCellCount => level.rows * level.columns;

  bool get allPairsConnected => completedPaths.length == level.pairs.length;

  Set<BoardPosition> get coveredPositions {
    return {
      for (final path in completedPaths.values) ...path.cells,
      ...activePath,
    };
  }

  int get coveredCellCount => coveredPositions.length;

  int get remainingCellCount => totalBoardCellCount - coveredCellCount;

  int get coveragePercent {
    if (totalBoardCellCount == 0) {
      return 0;
    }
    return coveredCellCount * 100 ~/ totalBoardCellCount;
  }

  bool get isBoardFilled => coveredCellCount == totalBoardCellCount;

  int get visibleLevelNumber => currentLevelIndex + 1;

  bool get hasNextLevel => currentLevelIndex < _maxLevelCount - 1;

  List<GameLevel> get levels => List<GameLevel>.unmodifiable(_levels);

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
    currentLevelIndex = _cacheLevel(newLevel);
    _loadLevel(newLevel, shouldNotify: true);
  }

  bool goToNextLevel() {
    if (!hasNextLevel || !isLevelComplete) {
      return false;
    }

    currentLevelIndex += 1;
    _loadLevel(_levelAt(currentLevelIndex), shouldNotify: true);
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

    if (activePath.length > 1 && isEndpoint(lastPosition)) {
      return false;
    }

    if (!canAddPosition(position)) {
      return false;
    }

    activePath = List<BoardPosition>.of(activePath)..add(position);
    notifyListeners();
    return true;
  }

  GamePath? cutCompletedPathAtAndExtend(BoardPosition position) {
    if (!isDragging || activePath.isEmpty || isLevelComplete) {
      return null;
    }

    final relationshipId = activeRelationshipId;
    if (relationshipId == null ||
        !_isPositionInsideBoard(position) ||
        activePath.contains(position) ||
        isEndpoint(position)) {
      return null;
    }

    final lastPosition = activePath.last;
    if (activePath.length > 1 && isEndpoint(lastPosition)) {
      return null;
    }

    if (!arePositionsAdjacent(lastPosition, position)) {
      return null;
    }

    final cutPath = _completedPathAt(
      position,
      excludingRelationshipId: relationshipId,
    );
    if (cutPath == null) {
      return null;
    }

    completedPaths = Map<String, GamePath>.of(completedPaths)
      ..remove(cutPath.relationshipId);
    completedPathOrder = List<String>.of(completedPathOrder)
      ..remove(cutPath.relationshipId);
    activePath = List<BoardPosition>.of(activePath)..add(position);
    isLevelComplete = false;
    notifyListeners();
    return cutPath;
  }

  GamePath? rejectWrongEndpoint(BoardPosition position) {
    if (!canRejectWrongEndpoint(position)) {
      return null;
    }

    final relationshipId = activeRelationshipId;
    if (relationshipId == null) {
      return null;
    }

    final rejectedCells = List<BoardPosition>.of(activePath)..add(position);
    final rejectedPath = GamePath(
      relationshipId: relationshipId,
      cells: List<BoardPosition>.unmodifiable(rejectedCells),
      isComplete: false,
    );

    moves += 1;
    _clearActivePath();
    notifyListeners();
    return rejectedPath;
  }

  bool finishPath() {
    if (!_hasDragAttempt && !isDragging) {
      return false;
    }

    moves += 1;

    final relationshipId = activeRelationshipId;
    final isValidPath =
        relationshipId != null &&
        activePath.length >= GameConstants.minimumCellsToCompletePath &&
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

  GamePath? _completedPathAt(
    BoardPosition position, {
    required String excludingRelationshipId,
  }) {
    for (final path in completedPaths.values) {
      if (path.relationshipId == excludingRelationshipId) {
        continue;
      }

      if (path.cells.contains(position)) {
        return path;
      }
    }
    return null;
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

  bool canRejectWrongEndpoint(BoardPosition position) {
    if (!isDragging || activePath.isEmpty || isLevelComplete) {
      return false;
    }

    if (activePath.length > 1 && isEndpoint(activePath.last)) {
      return false;
    }

    if (!_isPositionInsideBoard(position) ||
        !arePositionsAdjacent(activePath.last, position) ||
        activePath.contains(position)) {
      return false;
    }

    return isEndpoint(position) && !isCorrectTarget(position);
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
    isLevelComplete = allPairsConnected && isBoardFilled;
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
    final maxPairs =
        level.rows * level.columns ~/ GameConstants.minimumCellsPerPath;
    if (level.pairs.length > maxPairs) {
      throw ArgumentError.value(
        level.pairs.length,
        'pairs.length',
        'A ${level.rows}x${level.columns} level can contain at most $maxPairs pairs.',
      );
    }

    final endpoints = <BoardPosition>{};
    for (final pair in level.pairs) {
      for (final endpoint in [pair.sourcePosition, pair.targetPosition]) {
        if (endpoint.row < 0 ||
            endpoint.row >= level.rows ||
            endpoint.column < 0 ||
            endpoint.column >= level.columns) {
          throw ArgumentError.value(
            endpoint,
            'endpoint',
            'Endpoint must be inside the level board.',
          );
        }
        if (!endpoints.add(endpoint)) {
          throw ArgumentError.value(
            endpoint,
            'endpoint',
            'Endpoints must be unique.',
          );
        }
      }
    }
  }

  GameLevel _levelAt(int index) {
    if (index < _levels.length) {
      return _levels[index];
    }

    final builder = _levelBuilder;
    if (builder == null) {
      throw StateError('No level builder is available for level ${index + 1}.');
    }

    while (_levels.length <= index) {
      final nextLevelNumber = _levels.length + 1;
      final nextLevel = builder(nextLevelNumber);
      _validateLevel(nextLevel);
      _levels.add(nextLevel);
    }

    return _levels[index];
  }

  int _levelIndexFor(GameLevel newLevel) {
    for (var index = 0; index < _levels.length; index += 1) {
      if (_levels[index].id == newLevel.id) {
        return index;
      }
    }
    return -1;
  }

  int _cacheLevel(GameLevel newLevel) {
    final existingIndex = _levelIndexFor(newLevel);
    if (existingIndex >= 0) {
      return existingIndex;
    }

    _validateLevel(newLevel);
    _levels.add(newLevel);
    return _levels.length - 1;
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

int _resolveMaxLevelCount(List<GameLevel>? levels, int? maxLevelCount) {
  if (maxLevelCount != null) {
    return maxLevelCount;
  }

  return levels?.length ?? 1;
}
