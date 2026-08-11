import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/game_constants.dart';
import '../../domain/models/board_position.dart';
import '../../domain/models/game_path.dart';

class SplitRollbackPath {
  const SplitRollbackPath({required this.path, required this.cutPosition});

  final GamePath path;
  final BoardPosition cutPosition;
}

class GamePathPainter extends CustomPainter {
  const GamePathPainter({
    required this.solutionPaths,
    required this.completedPaths,
    required this.activePath,
    required this.rollbackPath,
    required this.splitRollbackPath,
    required this.rollbackProgress,
    required this.rollbackColor,
    required this.rollbackShimmerProgress,
    required this.activeDragPosition,
    required this.rows,
    required this.columns,
    required this.endpointPositions,
  });

  final List<GamePath> solutionPaths;
  final List<GamePath> completedPaths;
  final GamePath? activePath;
  final GamePath? rollbackPath;
  final SplitRollbackPath? splitRollbackPath;
  final double rollbackProgress;
  final Color? rollbackColor;
  final double? rollbackShimmerProgress;
  final Offset? activeDragPosition;
  final int rows;
  final int columns;
  final Set<BoardPosition> endpointPositions;

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in solutionPaths) {
      _drawPath(
        canvas,
        size,
        path,
        GameConstants.colorForRelationship(path.relationshipId),
        opacity: 0.22,
      );
    }

    for (final path in completedPaths) {
      _drawPath(
        canvas,
        size,
        path,
        GameConstants.colorForRelationship(path.relationshipId),
        opacity: 0.88,
      );
    }

    final splitPath = splitRollbackPath;
    final progress = rollbackProgress.clamp(0, 1).toDouble();
    if (splitPath != null && progress > 0) {
      _drawSplitRollbackPath(
        canvas,
        size,
        splitPath,
        rollbackColor ??
            GameConstants.colorForRelationship(splitPath.path.relationshipId),
        progress,
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
        trailingPoint: activeDragPosition,
      );
    }

    final retractingPath = rollbackPath;
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

  void _drawSplitRollbackPath(
    Canvas canvas,
    Size size,
    SplitRollbackPath splitPath,
    Color color,
    double progress,
  ) {
    final cells = splitPath.path.cells;
    final cutIndex = cells.indexOf(splitPath.cutPosition);
    if (cutIndex < 0) {
      return;
    }

    if (cutIndex > 0) {
      _drawPath(
        canvas,
        size,
        GamePath(
          relationshipId: splitPath.path.relationshipId,
          cells: List<BoardPosition>.unmodifiable(
            cells.sublist(0, cutIndex + 1),
          ),
          isComplete: false,
        ),
        color,
        opacity: 0.78 * progress,
        visibleFraction: progress,
      );
    }

    if (cutIndex < cells.length - 1) {
      _drawPath(
        canvas,
        size,
        GamePath(
          relationshipId: splitPath.path.relationshipId,
          cells: List<BoardPosition>.unmodifiable(
            cells.sublist(cutIndex).reversed,
          ),
          isComplete: false,
        ),
        color,
        opacity: 0.78 * progress,
        visibleFraction: progress,
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
    Offset? trailingPoint,
  }) {
    if (path.cells.length < 2 && trailingPoint == null) {
      return;
    }

    final strokeWidth = _strokeWidth(size);

    final drawnPath = _buildTrimmedPath(
      path,
      size,
      strokeWidth,
      endpointInset: _endpointInteriorInset(size),
      trailingPoint: trailingPoint,
    );
    final glowPath = _buildTrimmedPath(
      path,
      size,
      strokeWidth,
      endpointInset: _endpointGlowInset(size),
      trailingPoint: trailingPoint,
    );
    final visiblePath = visibleFraction >= 1
        ? drawnPath
        : _extractPathFraction(drawnPath, visibleFraction);
    final visibleGlowPath = visibleFraction >= 1
        ? glowPath
        : _extractPathFraction(glowPath, visibleFraction);
    _drawGlowingStroke(
      canvas,
      size,
      visiblePath,
      visibleGlowPath,
      color,
      opacity,
    );

    final shimmer = shimmerProgress;
    if (shimmer == null || shimmer <= 0) {
      return;
    }

    final shimmerStrength = shimmer.clamp(0, 1).toDouble();
    final shimmerEnd = math.min(visibleFraction, shimmerStrength);
    final shimmerStart = math.max(0.0, shimmerEnd - 0.18);
    final shimmerPath = _extractPathWindow(drawnPath, shimmerStart, shimmerEnd);
    final shimmerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.74 * shimmerStrength)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * 0.48
      ..isAntiAlias = true;
    canvas.drawPath(shimmerPath, shimmerPaint);
  }

  void _drawGlowingStroke(
    Canvas canvas,
    Size size,
    Path bodyPath,
    Path glowPath,
    Color color,
    double opacity,
  ) {
    final strokeWidth = _strokeWidth(size);
    final glowSigma = _glowSigma(size);
    final outerGlowPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.18)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * 5.4
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma * 1.55)
      ..isAntiAlias = true;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.34)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * 3.6
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma)
      ..isAntiAlias = true;
    final softPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.42)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * 2.15
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma * 0.48)
      ..isAntiAlias = true;
    final bodyPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.92)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;
    final corePaint = Paint()
      ..color = Color.lerp(
        color,
        Colors.white,
        0.76,
      )!.withValues(alpha: math.min(1, opacity * 1.08))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * 0.36
      ..isAntiAlias = true;

    canvas
      ..drawPath(glowPath, outerGlowPaint)
      ..drawPath(glowPath, glowPaint)
      ..drawPath(glowPath, softPaint)
      ..drawPath(bodyPath, bodyPaint)
      ..drawPath(bodyPath, corePaint);
  }

  Path _buildTrimmedPath(
    GamePath path,
    Size size,
    double strokeWidth, {
    required double endpointInset,
    Offset? trailingPoint,
  }) {
    final points = [for (final cell in path.cells) _cellCenter(cell, size)];
    if (trailingPoint != null &&
        (path.cells.length == 1 ||
            !endpointPositions.contains(path.cells.last))) {
      points.addAll(_orthogonalTrailingPoints(points, trailingPoint));
    }

    if (points.length < 2) {
      return Path();
    }

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

    return _buildSmoothPath(points, _cornerRadius(size, strokeWidth));
  }

  Path _buildSmoothPath(List<Offset> points, double cornerRadius) {
    final smoothedPath = Path()..moveToPoint(points.first);
    if (points.length == 2) {
      smoothedPath.lineToPoint(points.last);
      return smoothedPath;
    }

    for (var index = 1; index < points.length - 1; index += 1) {
      final previous = points[index - 1];
      final current = points[index];
      final next = points[index + 1];
      final incoming = previous - current;
      final outgoing = next - current;
      final incomingLength = incoming.distance;
      final outgoingLength = outgoing.distance;

      if (incomingLength == 0 || outgoingLength == 0) {
        smoothedPath.lineToPoint(current);
        continue;
      }

      final radius = math.min(
        cornerRadius,
        math.min(incomingLength, outgoingLength) * 0.42,
      );
      final beforeCorner = current + incoming / incomingLength * radius;
      final afterCorner = current + outgoing / outgoingLength * radius;
      smoothedPath
        ..lineToPoint(beforeCorner)
        ..quadraticBezierTo(
          current.dx,
          current.dy,
          afterCorner.dx,
          afterCorner.dy,
        );
    }

    smoothedPath.lineToPoint(points.last);
    return smoothedPath;
  }

  List<Offset> _orthogonalTrailingPoints(
    List<Offset> acceptedPoints,
    Offset trailingPoint,
  ) {
    final anchor = acceptedPoints.last;
    final delta = trailingPoint - anchor;
    const axisEpsilon = 0.5;

    if (delta.distance <= axisEpsilon) {
      return const [];
    }

    if (delta.dx.abs() <= axisEpsilon) {
      return [Offset(anchor.dx, trailingPoint.dy)];
    }

    if (delta.dy.abs() <= axisEpsilon) {
      return [Offset(trailingPoint.dx, anchor.dy)];
    }

    final horizontalFirst = _shouldContinueHorizontallyFirst(
      acceptedPoints,
      delta,
    );
    final corner = horizontalFirst
        ? Offset(trailingPoint.dx, anchor.dy)
        : Offset(anchor.dx, trailingPoint.dy);

    return [corner, trailingPoint];
  }

  bool _shouldContinueHorizontallyFirst(
    List<Offset> acceptedPoints,
    Offset trailingDelta,
  ) {
    if (acceptedPoints.length < 2) {
      return trailingDelta.dx.abs() >= trailingDelta.dy.abs();
    }

    final previousDelta =
        acceptedPoints.last - acceptedPoints[acceptedPoints.length - 2];
    if (previousDelta.dx.abs() == previousDelta.dy.abs()) {
      return trailingDelta.dx.abs() >= trailingDelta.dy.abs();
    }

    return previousDelta.dx.abs() > previousDelta.dy.abs();
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
    if (length == 0) {
      return from;
    }
    final effectiveDistance = math.min(distance, length * 0.72);
    return from + delta / length * effectiveDistance;
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
    return _cellExtent(size) * 0.20;
  }

  double _glowSigma(Size size) {
    return math.max(4, _cellExtent(size) * 0.095);
  }

  double _cornerRadius(Size size, double strokeWidth) {
    return math.max(strokeWidth * 1.35, _cellExtent(size) * 0.22);
  }

  double _endpointRadius(Size size) {
    return _cellExtent(size) * GameConstants.endpointIconScale / 2;
  }

  double _endpointInteriorInset(Size size) {
    return _endpointRadius(size) * 1.06;
  }

  double _endpointGlowInset(Size size) {
    return _endpointRadius(size) * 1.22;
  }

  @override
  bool shouldRepaint(covariant GamePathPainter oldDelegate) {
    return oldDelegate.solutionPaths != solutionPaths ||
        oldDelegate.completedPaths != completedPaths ||
        oldDelegate.activePath != activePath ||
        oldDelegate.rollbackPath != rollbackPath ||
        oldDelegate.splitRollbackPath != splitRollbackPath ||
        oldDelegate.rollbackProgress != rollbackProgress ||
        oldDelegate.rollbackColor != rollbackColor ||
        oldDelegate.rollbackShimmerProgress != rollbackShimmerProgress ||
        oldDelegate.activeDragPosition != activeDragPosition ||
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
