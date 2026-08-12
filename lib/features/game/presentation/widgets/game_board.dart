import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/game_constants.dart';
import '../../../themes/presentation/controllers/app_progress_controller.dart';
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

enum _BoardFeedbackType { none, successWave, wrongShimmer }

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  static const double _boardCornerRadius = 10;

  late final AnimationController _rollbackController;
  late final AnimationController _feedbackController;
  BoardPosition? _lastPanPosition;
  Offset? _activeDragPosition;
  GamePath? _rollbackPath;
  SplitRollbackPath? _splitRollbackPath;
  Color? _rollbackColor;
  BoardPosition? _invalidEndpointPosition;
  _BoardFeedbackType _feedbackType = _BoardFeedbackType.none;
  Offset? _feedbackOrigin;

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
    _feedbackController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 620),
          )
          ..addListener(_handleFeedbackTick)
          ..addStatusListener(_handleFeedbackStatus);
  }

  @override
  void dispose() {
    _rollbackController
      ..removeListener(_handleRollbackTick)
      ..removeStatusListener(_handleRollbackStatus)
      ..dispose();
    _feedbackController
      ..removeListener(_handleFeedbackTick)
      ..removeStatusListener(_handleFeedbackStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final showSolutionPaths = context
        .watch<AppProgressController>()
        .showSolutionPaths;
    final level = controller.level;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardGeometry = constraints.biggest;
        final endpointPositions = _endpointPositionsFor(level);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(_boardCornerRadius),
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
            borderRadius: BorderRadius.circular(_boardCornerRadius),
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
                if (_feedbackType != _BoardFeedbackType.none)
                  CustomPaint(
                    painter: _BoardFeedbackPainter(
                      type: _feedbackType,
                      progress: _feedbackController.value,
                      origin:
                          _feedbackOrigin ??
                          Offset(
                            boardGeometry.width / 2,
                            boardGeometry.height / 2,
                          ),
                      reducedMotion: _shouldReduceMotion(context),
                      rows: level.rows,
                      columns: level.columns,
                    ),
                  ),
                CustomPaint(
                  painter: GamePathPainter(
                    solutionPaths: showSolutionPaths
                        ? [
                            for (final solution in level.solutions)
                              GamePath(
                                relationshipId: solution.relationshipId,
                                cells: solution.cells,
                                isComplete: true,
                              ),
                          ]
                        : const <GamePath>[],
                    completedPaths: controller.completedPaths.values.toList(),
                    activePath: controller.activeGamePath,
                    rollbackPath: _rollbackPath,
                    splitRollbackPath: _splitRollbackPath,
                    rollbackProgress: _rollbackController.value,
                    rollbackColor: _rollbackColor,
                    rollbackShimmerProgress: _rollbackColor == null
                        ? null
                        : _rollbackController.value,
                    activeDragPosition: _activeDragPosition,
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
                    boardSize: boardGeometry,
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
                    boardSize: boardGeometry,
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
                        : (_) => _handlePanEnd(boardGeometry, level),
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
    );
  }

  void _handlePanStart(Offset localPosition, Size boardSize, GameLevel level) {
    _clearRollbackPath();
    final position = _positionFromOffset(localPosition, boardSize, level);
    if (position == null) {
      return;
    }

    _lastPanPosition = position;
    final didStart = context.read<GameController>().startPath(position);
    setState(() {
      _activeDragPosition = didStart
          ? _clampOffset(localPosition, boardSize)
          : null;
    });
  }

  void _handlePanUpdate(Offset localPosition, Size boardSize, GameLevel level) {
    final controller = context.read<GameController>();
    final position = _positionFromOffset(localPosition, boardSize, level);
    if (position == null) {
      _updateActiveDragPosition(controller, localPosition, boardSize);
      return;
    }

    if (position != _lastPanPosition) {
      _lastPanPosition = position;
      final rejectedPath = controller.rejectWrongEndpoint(position);
      if (rejectedPath != null) {
        _lastPanPosition = null;
        setState(() {
          _activeDragPosition = null;
        });
        _triggerWrongEndpointFeedback(rejectedPath, position, boardSize, level);
        return;
      }

      final cutPath = controller.cutCompletedPathAtAndExtend(position);
      if (cutPath != null) {
        _startSplitRollback(cutPath, position);
      } else {
        controller.extendPath(position);
      }
    }

    _updateActiveDragPosition(controller, localPosition, boardSize);
  }

  void _handlePanEnd(Size boardSize, GameLevel level) {
    _lastPanPosition = null;
    final controller = context.read<GameController>();
    final pathBeforeFinish = controller.activeGamePath;
    final didComplete = controller.finishPath();
    if (_activeDragPosition != null) {
      setState(() {
        _activeDragPosition = null;
      });
    }

    if (!didComplete &&
        pathBeforeFinish != null &&
        pathBeforeFinish.cells.length > 1) {
      _startBoardFeedback(
        _BoardFeedbackType.wrongShimmer,
        _cellCenter(pathBeforeFinish.cells.last, boardSize, level),
      );
      _startRollback(pathBeforeFinish);
    } else if (didComplete && pathBeforeFinish != null) {
      _startBoardFeedback(
        _BoardFeedbackType.successWave,
        _cellCenter(pathBeforeFinish.cells.last, boardSize, level),
      );
      HapticFeedback.mediumImpact();
      if (controller.allPairsConnected && !controller.isBoardFilled) {
        final remainingCells = controller.remainingCellCount;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'All pairs match, but $remainingCells cells are empty. '
                'Redraw a path to fill the board.',
              ),
            ),
          );
      }
    }
  }

  void _handlePanCancel() {
    _lastPanPosition = null;
    final controller = context.read<GameController>();
    final pathBeforeCancel = controller.activeGamePath;
    controller.cancelActivePath();
    if (_activeDragPosition != null) {
      setState(() {
        _activeDragPosition = null;
      });
    }

    if (pathBeforeCancel != null && pathBeforeCancel.cells.length > 1) {
      _startRollback(pathBeforeCancel);
    }
  }

  void _triggerWrongEndpointFeedback(
    GamePath path,
    BoardPosition position,
    Size boardSize,
    GameLevel level,
  ) {
    HapticFeedback.mediumImpact();
    _startBoardFeedback(
      _BoardFeedbackType.wrongShimmer,
      _cellCenter(position, boardSize, level),
    );
    _startRollback(
      path,
      color: Theme.of(context).colorScheme.error,
      invalidEndpointPosition: position,
      duration: GameConstants.wrongPathRollbackDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _startSplitRollback(GamePath path, BoardPosition cutPosition) {
    _rollbackController.stop();
    _rollbackController.value = 1;
    setState(() {
      _rollbackPath = null;
      _splitRollbackPath = SplitRollbackPath(
        path: path,
        cutPosition: cutPosition,
      );
      _rollbackColor = GameConstants.colorForRelationship(path.relationshipId);
      _invalidEndpointPosition = null;
    });
    _rollbackController.animateBack(
      0,
      duration: const Duration(milliseconds: 360),
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
      _splitRollbackPath = null;
      _rollbackColor = color;
      _invalidEndpointPosition = invalidEndpointPosition;
    });
    _rollbackController.animateBack(0, duration: duration, curve: curve);
  }

  void _handleRollbackTick() {
    if ((_rollbackPath == null && _splitRollbackPath == null) || !mounted) {
      return;
    }

    setState(() {});
  }

  void _clearRollbackPath() {
    if (_rollbackPath == null && _splitRollbackPath == null) {
      return;
    }

    _rollbackController.stop();
    setState(() {
      _rollbackPath = null;
      _splitRollbackPath = null;
      _rollbackColor = null;
      _invalidEndpointPosition = null;
      _rollbackController.value = 0;
    });
  }

  void _handleRollbackStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed ||
        (_rollbackPath == null && _splitRollbackPath == null)) {
      return;
    }

    if (!mounted) {
      _rollbackPath = null;
      _splitRollbackPath = null;
      return;
    }

    final shouldClearActiveDragPosition = _rollbackPath != null;
    setState(() {
      _rollbackPath = null;
      _splitRollbackPath = null;
      _rollbackColor = null;
      _invalidEndpointPosition = null;
      if (shouldClearActiveDragPosition) {
        _activeDragPosition = null;
      }
    });
  }

  void _startBoardFeedback(_BoardFeedbackType type, Offset origin) {
    final reducedMotion = _shouldReduceMotion(context);
    _feedbackController
      ..stop()
      ..duration = reducedMotion
          ? const Duration(milliseconds: 180)
          : switch (type) {
              _BoardFeedbackType.successWave => const Duration(
                milliseconds: 640,
              ),
              _BoardFeedbackType.wrongShimmer => const Duration(
                milliseconds: 460,
              ),
              _BoardFeedbackType.none => const Duration(milliseconds: 1),
            };
    setState(() {
      _feedbackType = type;
      _feedbackOrigin = origin;
      _feedbackController.value = 0;
    });
    _feedbackController.forward(from: 0);
  }

  void _handleFeedbackTick() {
    if (_feedbackType == _BoardFeedbackType.none || !mounted) {
      return;
    }

    setState(() {});
  }

  void _handleFeedbackStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    setState(() {
      _feedbackType = _BoardFeedbackType.none;
      _feedbackOrigin = null;
      _feedbackController.value = 0;
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

  Offset _clampOffset(Offset offset, Size boardSize) {
    return Offset(
      offset.dx.clamp(0, boardSize.width).toDouble(),
      offset.dy.clamp(0, boardSize.height).toDouble(),
    );
  }

  Offset _cellCenter(BoardPosition position, Size boardSize, GameLevel level) {
    final cellWidth = boardSize.width / level.columns;
    final cellHeight = boardSize.height / level.rows;
    return Offset(
      (position.column + 0.5) * cellWidth,
      (position.row + 0.5) * cellHeight,
    );
  }

  bool _shouldReduceMotion(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    return mediaQuery?.disableAnimations ??
        mediaQuery?.accessibleNavigation ??
        false;
  }

  void _updateActiveDragPosition(
    GameController controller,
    Offset localPosition,
    Size boardSize,
  ) {
    if (!controller.isDragging || controller.activePath.isEmpty) {
      if (_activeDragPosition != null) {
        setState(() {
          _activeDragPosition = null;
        });
      }
      return;
    }

    final hasStoppedAtEndpoint =
        controller.activePath.length > 1 &&
        controller.isEndpoint(controller.activePath.last);
    final nextPosition = hasStoppedAtEndpoint
        ? null
        : _clampOffset(localPosition, boardSize);
    if (_activeDragPosition == nextPosition) {
      return;
    }

    setState(() {
      _activeDragPosition = nextPosition;
    });
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
  final Size boardSize;
  final bool isSource;
  final bool isConnected;
  final double invalidFeedbackProgress;

  @override
  Widget build(BuildContext context) {
    final cellWidth = boardSize.width / level.columns;
    final cellHeight = boardSize.height / level.rows;
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

class _BoardFeedbackPainter extends CustomPainter {
  const _BoardFeedbackPainter({
    required this.type,
    required this.progress,
    required this.origin,
    required this.reducedMotion,
    required this.rows,
    required this.columns,
  });

  static final SpringDescription _successWaveSpring = SpringDescription(
    mass: 1,
    stiffness: 260,
    damping: 13,
  );

  final _BoardFeedbackType type;
  final double progress;
  final Offset origin;
  final bool reducedMotion;
  final int rows;
  final int columns;

  @override
  void paint(Canvas canvas, Size size) {
    final clampedProgress = progress.clamp(0, 1).toDouble();
    if (clampedProgress <= 0 || type == _BoardFeedbackType.none) {
      return;
    }

    if (reducedMotion) {
      _drawReducedMotionFlash(canvas, size, clampedProgress);
      return;
    }

    switch (type) {
      case _BoardFeedbackType.successWave:
        _drawSuccessWave(canvas, size, clampedProgress);
      case _BoardFeedbackType.wrongShimmer:
        _drawWrongShimmer(canvas, size, clampedProgress);
      case _BoardFeedbackType.none:
        break;
    }
  }

  void _drawReducedMotionFlash(Canvas canvas, Size size, double progress) {
    final color = switch (type) {
      _BoardFeedbackType.successWave => const Color(0xFF2ECC71),
      _BoardFeedbackType.wrongShimmer => const Color(0xFFE53935),
      _BoardFeedbackType.none => Colors.transparent,
    };
    final opacity = (1 - progress) * 0.12;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawSuccessWave(Canvas canvas, Size size, double progress) {
    if (rows <= 0 || columns <= 0) {
      return;
    }

    const green = Color(0xFF2ECC71);
    final fade = (1 - Curves.easeIn.transform(progress)).clamp(0, 1).toDouble();
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;
    final cellExtent = math.min(cellWidth, cellHeight);
    final maxDistance = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final spring = SpringSimulation(_successWaveSpring, 0, 0, -7.0);
    final waveTime = progress * 1.05;
    final maxDelay = 0.38;
    final maxLift = math.min(28.0, cellExtent * 0.42);
    final gap = math.max(1.5, cellExtent * 0.045);

    final washPaint = Paint()
      ..color = green.withValues(alpha: fade * 0.055)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, washPaint);

    final shadowPaint = Paint()
      ..color = green.withValues(alpha: 0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..isAntiAlias = true;
    final tilePaint = Paint()
      ..color = green.withValues(alpha: 0)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final edgePaint = Paint()
      ..color = green.withValues(alpha: 0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, cellExtent * 0.035)
      ..isAntiAlias = true;

    for (var row = 0; row < rows; row += 1) {
      for (var column = 0; column < columns; column += 1) {
        final left = column * cellWidth;
        final top = row * cellHeight;
        final center = Offset(left + cellWidth / 2, top + cellHeight / 2);
        final distanceFactor = (center - origin).distance / maxDistance;
        final localTime = waveTime - distanceFactor * maxDelay;
        if (localTime < 0 || localTime > 0.74) {
          continue;
        }

        final springValue = (-spring.x(
          localTime,
        )).clamp(-0.34, 1.22).toDouble();
        final lift = -springValue * maxLift;
        final intensity = springValue.abs().clamp(0, 1).toDouble();
        if (intensity <= 0.01 && lift.abs() <= 0.2) {
          continue;
        }

        final cellFade = (1 - (localTime / 0.74)).clamp(0, 1).toDouble();
        final opacity = intensity * cellFade;
        final rect = Rect.fromLTWH(
          left + gap,
          top + gap,
          cellWidth - gap * 2,
          cellHeight - gap * 2,
        );
        final shiftedRect = rect.shift(Offset(0, lift));
        final radius = Radius.circular(math.max(8, cellExtent * 0.20));
        final shiftedRRect = RRect.fromRectAndRadius(shiftedRect, radius);
        final shadowRRect = RRect.fromRectAndRadius(
          rect.shift(Offset(0, math.max(3.0, -lift * 0.30))),
          radius,
        );

        shadowPaint.color = green.withValues(alpha: opacity * 0.32);
        tilePaint.color = green.withValues(alpha: opacity * 0.22);
        edgePaint.color = green.withValues(alpha: opacity * 0.42);

        canvas
          ..drawRRect(shadowRRect, shadowPaint)
          ..drawRRect(shiftedRRect, tilePaint)
          ..drawRRect(shiftedRRect, edgePaint);
      }
    }
  }

  void _drawWrongShimmer(Canvas canvas, Size size, double progress) {
    final eased = Curves.easeOutCubic.transform(progress);
    final fade = math.sin(progress * math.pi).clamp(0, 1).toDouble();
    const red = Color(0xFFE53935);

    final washPaint = Paint()
      ..color = red.withValues(alpha: fade * 0.055)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, washPaint);

    final diagonalExtent = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final bandWidth = math.max(48.0, math.min(size.width, size.height) * 0.20);
    final travel = diagonalExtent + bandWidth * 2;
    final bandOffset = -travel / 2 + travel * eased;

    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(size.width / 2, size.height / 2)
      ..rotate(-0.42);

    final bandRect = Rect.fromLTWH(
      -diagonalExtent,
      bandOffset - bandWidth / 2,
      diagonalExtent * 2,
      bandWidth,
    );
    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          red.withValues(alpha: 0),
          red.withValues(alpha: fade * 0.18),
          red.withValues(alpha: fade * 0.06),
          red.withValues(alpha: 0),
        ],
        stops: const [0, 0.42, 0.58, 1],
      ).createShader(bandRect)
      ..isAntiAlias = true;
    canvas
      ..drawRect(bandRect, bandPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _BoardFeedbackPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.progress != progress ||
        oldDelegate.origin != origin ||
        oldDelegate.reducedMotion != reducedMotion ||
        oldDelegate.rows != rows ||
        oldDelegate.columns != columns;
  }
}
