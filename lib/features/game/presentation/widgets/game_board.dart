import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/game_constants.dart';
import '../../domain/models/board_position.dart';
import '../../domain/models/game_level.dart';
import '../../domain/models/game_path.dart';
import '../../domain/models/level_pair_placement.dart';
import '../controllers/game_controller.dart';
import 'endpoint_icon.dart';
import 'game_path_painter.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rollbackController;
  BoardPosition? _lastPanPosition;
  GamePath? _rollbackPath;
  Color? _rollbackColor;
  BoardPosition? _invalidEndpointPosition;

  @override
  void initState() {
    super.initState();
    _rollbackController =
        AnimationController(
            vsync: this,
            duration: GameConstants.pathRollbackDuration,
          )
          ..addListener(_handleRollbackTick)
          ..addStatusListener(_handleRollbackStatus);
  }

  @override
  void dispose() {
    _rollbackController
      ..removeListener(_handleRollbackTick)
      ..removeStatusListener(_handleRollbackStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final level = controller.level;
    final colorScheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boardSize = constraints.biggest.shortestSide;
          final boardGeometry = Size.square(boardSize);
          final endpointPositions = _endpointPositionsFor(level);

          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.16),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _GameGridPainter(
                      rows: level.rows,
                      columns: level.columns,
                      lineColor: colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  CustomPaint(
                    painter: GamePathPainter(
                      completedPaths: controller.completedPaths.values.toList(),
                      activePath: controller.activeGamePath,
                      rollbackPath: _rollbackPath,
                      rollbackProgress: _rollbackController.value,
                      rollbackColor: _rollbackColor,
                      rollbackShimmerProgress: _rollbackColor == null
                          ? null
                          : _rollbackController.value,
                      rows: level.rows,
                      columns: level.columns,
                      endpointPositions: endpointPositions,
                    ),
                  ),
                  for (final placement in level.pairs) ...[
                    _EndpointPlacement(
                      level: level,
                      placement: placement,
                      position: placement.sourcePosition,
                      boardSize: boardSize,
                      isSource: true,
                      isConnected: controller.completedPaths.containsKey(
                        placement.relationship.id,
                      ),
                      invalidFeedbackProgress:
                          _invalidEndpointPosition == placement.sourcePosition
                          ? _rollbackController.value
                          : 0,
                    ),
                    _EndpointPlacement(
                      level: level,
                      placement: placement,
                      position: placement.targetPosition,
                      boardSize: boardSize,
                      isSource: false,
                      isConnected: controller.completedPaths.containsKey(
                        placement.relationship.id,
                      ),
                      invalidFeedbackProgress:
                          _invalidEndpointPosition == placement.targetPosition
                          ? _rollbackController.value
                          : 0,
                    ),
                  ],
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: controller.isLevelComplete
                          ? null
                          : (details) => _handlePanStart(
                              details.localPosition,
                              boardGeometry,
                              level,
                            ),
                      onPanUpdate: controller.isLevelComplete
                          ? null
                          : (details) => _handlePanUpdate(
                              details.localPosition,
                              boardGeometry,
                              level,
                            ),
                      onPanEnd: controller.isLevelComplete
                          ? null
                          : (_) => _handlePanEnd(),
                      onPanCancel: controller.isLevelComplete
                          ? null
                          : _handlePanCancel,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handlePanStart(Offset localPosition, Size boardSize, GameLevel level) {
    _clearRollbackPath();
    final position = _positionFromOffset(localPosition, boardSize, level);
    if (position == null) {
      return;
    }

    _lastPanPosition = position;
    context.read<GameController>().startPath(position);
  }

  void _handlePanUpdate(Offset localPosition, Size boardSize, GameLevel level) {
    final position = _positionFromOffset(localPosition, boardSize, level);
    if (position == null || position == _lastPanPosition) {
      return;
    }

    _lastPanPosition = position;
    final controller = context.read<GameController>();
    final rejectedPath = controller.rejectWrongEndpoint(position);
    if (rejectedPath != null) {
      _lastPanPosition = null;
      _triggerWrongEndpointFeedback(rejectedPath, position);
      return;
    }

    controller.extendPath(position);
  }

  void _handlePanEnd() {
    _lastPanPosition = null;
    final controller = context.read<GameController>();
    final pathBeforeFinish = controller.activeGamePath;
    final didComplete = controller.finishPath();

    if (!didComplete &&
        pathBeforeFinish != null &&
        pathBeforeFinish.cells.length > 1) {
      _startRollback(pathBeforeFinish);
    }
  }

  void _handlePanCancel() {
    _lastPanPosition = null;
    final controller = context.read<GameController>();
    final pathBeforeCancel = controller.activeGamePath;
    controller.cancelActivePath();

    if (pathBeforeCancel != null && pathBeforeCancel.cells.length > 1) {
      _startRollback(pathBeforeCancel);
    }
  }

  void _triggerWrongEndpointFeedback(GamePath path, BoardPosition position) {
    HapticFeedback.mediumImpact();
    _startRollback(
      path,
      color: Theme.of(context).colorScheme.error,
      invalidEndpointPosition: position,
      duration: GameConstants.wrongPathRollbackDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _startRollback(
    GamePath path, {
    Color? color,
    BoardPosition? invalidEndpointPosition,
    Duration duration = GameConstants.pathRollbackDuration,
    Curve curve = Curves.easeInCubic,
  }) {
    _rollbackController.stop();
    _rollbackController.value = 1;
    setState(() {
      _rollbackPath = path;
      _rollbackColor = color;
      _invalidEndpointPosition = invalidEndpointPosition;
    });
    _rollbackController.animateBack(0, duration: duration, curve: curve);
  }

  void _handleRollbackTick() {
    if (_rollbackPath == null || !mounted) {
      return;
    }

    setState(() {});
  }

  void _clearRollbackPath() {
    if (_rollbackPath == null) {
      return;
    }

    _rollbackController.stop();
    setState(() {
      _rollbackPath = null;
      _rollbackColor = null;
      _invalidEndpointPosition = null;
      _rollbackController.value = 0;
    });
  }

  void _handleRollbackStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed || _rollbackPath == null) {
      return;
    }

    if (!mounted) {
      _rollbackPath = null;
      return;
    }

    setState(() {
      _rollbackPath = null;
      _rollbackColor = null;
      _invalidEndpointPosition = null;
    });
  }

  Set<BoardPosition> _endpointPositionsFor(GameLevel level) {
    return {
      for (final placement in level.pairs) ...[
        placement.sourcePosition,
        placement.targetPosition,
      ],
    };
  }

  BoardPosition? _positionFromOffset(
    Offset localPosition,
    Size boardSize,
    GameLevel level,
  ) {
    if (localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx >= boardSize.width ||
        localPosition.dy >= boardSize.height) {
      return null;
    }

    final row = (localPosition.dy / (boardSize.height / level.rows)).floor();
    final column = (localPosition.dx / (boardSize.width / level.columns))
        .floor();

    if (row < 0 || row >= level.rows || column < 0 || column >= level.columns) {
      return null;
    }

    return BoardPosition(row: row, column: column);
  }
}

class _EndpointPlacement extends StatelessWidget {
  const _EndpointPlacement({
    required this.level,
    required this.placement,
    required this.position,
    required this.boardSize,
    required this.isSource,
    required this.isConnected,
    required this.invalidFeedbackProgress,
  });

  final GameLevel level;
  final LevelPairPlacement placement;
  final BoardPosition position;
  final double boardSize;
  final bool isSource;
  final bool isConnected;
  final double invalidFeedbackProgress;

  @override
  Widget build(BuildContext context) {
    final cellWidth = boardSize / level.columns;
    final cellHeight = boardSize / level.rows;
    final iconSize =
        (cellWidth < cellHeight ? cellWidth : cellHeight) *
        GameConstants.endpointIconScale;
    final item = isSource
        ? placement.relationship.source
        : placement.relationship.target;
    final color = GameConstants.colorForRelationship(placement.relationship.id);

    return Positioned(
      left: position.column * cellWidth + (cellWidth - iconSize) / 2,
      top: position.row * cellHeight + (cellHeight - iconSize) / 2,
      width: iconSize,
      height: iconSize,
      child: EndpointIcon(
        item: item,
        color: color,
        isConnected: isConnected,
        invalidFeedbackProgress: invalidFeedbackProgress,
      ),
    );
  }
}

class _GameGridPainter extends CustomPainter {
  const _GameGridPainter({
    required this.rows,
    required this.columns,
    required this.lineColor,
  });

  final int rows;
  final int columns;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    for (var column = 1; column < columns; column += 1) {
      final dx = column * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    }

    for (var row = 1; row < rows; row += 1) {
      final dy = row * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GameGridPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.columns != columns ||
        oldDelegate.lineColor != lineColor;
  }
}
