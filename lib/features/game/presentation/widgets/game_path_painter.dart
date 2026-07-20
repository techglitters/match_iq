import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/game_constants.dart';
import '../../domain/models/board_position.dart';
import '../../domain/models/game_path.dart';

class GamePathPainter extends CustomPainter {
  const GamePathPainter({
    required this.completedPaths,
    required this.activePath,
    required this.rollbackPath,
    required this.rollbackProgress,
    required this.rollbackColor,
    required this.rollbackShimmerProgress,
    required this.rows,
    required this.columns,
    required this.endpointPositions,
  });

  final List<GamePath> completedPaths;
  final GamePath? activePath;
  final GamePath? rollbackPath;
  final double rollbackProgress;
  final Color? rollbackColor;
  final double? rollbackShimmerProgress;
  final int rows;
  final int columns;
  final Set<BoardPosition> endpointPositions;

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in completedPaths) {
      _drawPath(
        canvas,
        size,
        path,
        GameConstants.colorForRelationship(path.relationshipId),
        opacity: 0.88,
      );
    }

    final currentPath = activePath;
    if (currentPath != null) {
      _drawPath(
        canvas,
        size,
        currentPath,
        GameConstants.colorForRelationship(currentPath.relationshipId),
        opacity: 0.62,
      );
    }

    final retractingPath = rollbackPath;
    final progress = rollbackProgress.clamp(0, 1).toDouble();
    if (retractingPath != null && progress > 0) {
      _drawPath(
        canvas,
        size,
        retractingPath,
        rollbackColor ??
            GameConstants.colorForRelationship(retractingPath.relationshipId),
        opacity: rollbackColor == null ? 0.52 * progress : 0.82 * progress,
        visibleFraction: progress,
        shimmerProgress: rollbackShimmerProgress,
      );
    }
  }

  void _drawPath(
    Canvas canvas,
    Size size,
    GamePath path,
    Color color, {
    required double opacity,
    double visibleFraction = 1,
    double? shimmerProgress,
  }) {
    if (path.cells.length < 2) {
      return;
    }

    final strokeWidth = _strokeWidth(size);
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    final drawnPath = _buildTrimmedPath(path, size, strokeWidth);
    final visiblePath = visibleFraction >= 1
        ? drawnPath
        : _extractPathFraction(drawnPath, visibleFraction);

    canvas.drawPath(visiblePath, paint);

    final shimmer = shimmerProgress;
    if (shimmer == null || shimmer <= 0) {
      return;
    }

    final shimmerStrength = shimmer.clamp(0, 1).toDouble();
    final shimmerEnd = math.min(visibleFraction, shimmerStrength);
    final shimmerStart = math.max(0.0, shimmerEnd - 0.18);
    final shimmerPath = _extractPathWindow(drawnPath, shimmerStart, shimmerEnd);
    final shimmerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.54 * shimmerStrength)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * 0.44
      ..isAntiAlias = true;
    canvas.drawPath(shimmerPath, shimmerPaint);
  }

  Path _buildTrimmedPath(GamePath path, Size size, double strokeWidth) {
    final points = [for (final cell in path.cells) _cellCenter(cell, size)];
    final endpointInset = _endpointRadius(size) + strokeWidth / 2;

    if (endpointPositions.contains(path.cells.first)) {
      points[0] = _pointMovedToward(points.first, points[1], endpointInset);
    }

    final lastIndex = points.length - 1;
    if (endpointPositions.contains(path.cells.last)) {
      points[lastIndex] = _pointMovedToward(
        points.last,
        points[lastIndex - 1],
        endpointInset,
      );
    }

    final drawnPath = Path()..moveToPoint(points.first);
    for (final point in points.skip(1)) {
      drawnPath.lineToPoint(point);
    }
    return drawnPath;
  }

  Path _extractPathFraction(Path source, double fraction) {
    final visibleFraction = fraction.clamp(0, 1).toDouble();
    if (visibleFraction <= 0) {
      return Path();
    }

    final metrics = source.computeMetrics().toList();
    final totalLength = metrics.fold<double>(
      0,
      (total, metric) => total + metric.length,
    );
    var remainingLength = totalLength * visibleFraction;
    final visiblePath = Path();

    for (final metric in metrics) {
      if (remainingLength <= 0) {
        break;
      }

      final segmentLength = math.min(metric.length, remainingLength);
      visiblePath.addPath(metric.extractPath(0, segmentLength), Offset.zero);
      remainingLength -= segmentLength;
    }

    return visiblePath;
  }

  Path _extractPathWindow(
    Path source,
    double startFraction,
    double endFraction,
  ) {
    final start = startFraction.clamp(0, 1).toDouble();
    final end = endFraction.clamp(start, 1).toDouble();
    if (end <= start) {
      return Path();
    }

    final metrics = source.computeMetrics().toList();
    final totalLength = metrics.fold<double>(
      0,
      (total, metric) => total + metric.length,
    );
    var remainingSkipLength = totalLength * start;
    var remainingTakeLength = totalLength * (end - start);
    final windowPath = Path();

    for (final metric in metrics) {
      if (remainingTakeLength <= 0) {
        break;
      }

      if (remainingSkipLength >= metric.length) {
        remainingSkipLength -= metric.length;
        continue;
      }

      final localStart = remainingSkipLength;
      final localLength = math.min(
        metric.length - localStart,
        remainingTakeLength,
      );
      windowPath.addPath(
        metric.extractPath(localStart, localStart + localLength),
        Offset.zero,
      );
      remainingSkipLength = 0;
      remainingTakeLength -= localLength;
    }

    return windowPath;
  }

  Offset _pointMovedToward(Offset from, Offset toward, double distance) {
    final delta = toward - from;
    final length = delta.distance;
    if (length == 0 || distance >= length) {
      return from;
    }
    return from + delta / length * distance;
  }

  Offset _cellCenter(BoardPosition position, Size size) {
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;
    return Offset(
      (position.column + 0.5) * cellWidth,
      (position.row + 0.5) * cellHeight,
    );
  }

  double _cellExtent(Size size) {
    return math.min(size.width / columns, size.height / rows);
  }

  double _strokeWidth(Size size) {
    return _cellExtent(size) * 0.22;
  }

  double _endpointRadius(Size size) {
    return _cellExtent(size) * GameConstants.endpointIconScale / 2;
  }

  @override
  bool shouldRepaint(covariant GamePathPainter oldDelegate) {
    return oldDelegate.completedPaths != completedPaths ||
        oldDelegate.activePath != activePath ||
        oldDelegate.rollbackPath != rollbackPath ||
        oldDelegate.rollbackProgress != rollbackProgress ||
        oldDelegate.rollbackColor != rollbackColor ||
        oldDelegate.rollbackShimmerProgress != rollbackShimmerProgress ||
        oldDelegate.rows != rows ||
        oldDelegate.columns != columns ||
        oldDelegate.endpointPositions != endpointPositions;
  }
}

extension on Path {
  void moveToPoint(Offset offset) {
    moveTo(offset.dx, offset.dy);
  }

  void lineToPoint(Offset offset) {
    lineTo(offset.dx, offset.dy);
  }
}
