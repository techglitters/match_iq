import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../themes/data/theme_catalog.dart';
import '../../themes/presentation/controllers/app_progress_controller.dart';
import 'widgets/level_node.dart';
import 'widgets/level_path_painter.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  static const _nodeSize = 92.0;
  static const _topPadding = 104.0;
  static const _verticalStep = 116.0;

  final _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProgress = context.watch<AppProgressController>();
    final theme = ThemeCatalog.natureWorld;
    final progress = appProgress.progressForTheme(theme.id);
    final mapHeight = _topPadding + theme.levels.length * _verticalStep + 80;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nature Map',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${progress.totalStars} / ${theme.maxStars} stars',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final points = [
                    for (
                      var levelNumber = 1;
                      levelNumber <= theme.levels.length;
                      levelNumber += 1
                    )
                      _nodeCenter(levelNumber, constraints.maxWidth),
                  ];

                  return SingleChildScrollView(
                    controller: _scrollController,
                    child: SizedBox(
                      height: mapHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: LevelPathPainter(points: points),
                            ),
                          ),
                          for (final level in theme.levels)
                            _PositionedLevelNode(
                              levelNumber: level.levelNumber,
                              width: constraints.maxWidth,
                              status: _statusFor(
                                progress
                                    .levelProgress(level.levelNumber)
                                    .completed,
                                progress.isUnlocked(level.levelNumber),
                                progress.highestUnlockedLevel ==
                                    level.levelNumber,
                              ),
                              stars: progress
                                  .levelProgress(level.levelNumber)
                                  .stars,
                              onTap: progress.isUnlocked(level.levelNumber)
                                  ? () => Navigator.of(context).pushNamed(
                                      AppRoutes.natureLevel(level.levelNumber),
                                    )
                                  : null,
                              isCurrent:
                                  progress.highestUnlockedLevel ==
                                  level.levelNumber,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  LevelStatus _statusFor(bool completed, bool unlocked, bool current) {
    if (completed) {
      return LevelStatus.completed;
    }
    if (current) {
      return LevelStatus.current;
    }
    if (unlocked) {
      return LevelStatus.unlocked;
    }
    return LevelStatus.locked;
  }

  Offset _nodeCenter(int levelNumber, double width) {
    final x = width * _xFactor(levelNumber);
    final y = _topPadding + (levelNumber - 1) * _verticalStep;
    return Offset(x, y);
  }

  double _xFactor(int levelNumber) {
    const pattern = [
      0.22,
      0.38,
      0.66,
      0.80,
      0.72,
      0.50,
      0.24,
      0.18,
      0.48,
      0.78,
    ];
    return pattern[(levelNumber - 1) % pattern.length];
  }

  void _scrollToCurrent() {
    if (!_scrollController.hasClients || !mounted) {
      return;
    }
    final appProgress = context.read<AppProgressController>();
    final currentLevel = appProgress.highestUnlockedLevel(
      ThemeCatalog.natureThemeId,
    );
    final viewport = _scrollController.position.viewportDimension;
    final target =
        _topPadding + (currentLevel - 1) * _verticalStep - viewport / 2;
    final clamped = target.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(clamped.toDouble());
  }
}

class _PositionedLevelNode extends StatelessWidget {
  const _PositionedLevelNode({
    required this.levelNumber,
    required this.width,
    required this.status,
    required this.stars,
    required this.onTap,
    required this.isCurrent,
  });

  final int levelNumber;
  final double width;
  final LevelStatus status;
  final int stars;
  final VoidCallback? onTap;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final x =
        width * _xFactor(levelNumber) - _LevelMapScreenState._nodeSize / 2;
    final y =
        _LevelMapScreenState._topPadding +
        (levelNumber - 1) * _LevelMapScreenState._verticalStep -
        _LevelMapScreenState._nodeSize / 2;

    return Positioned(
      left: x,
      top: y,
      width: _LevelMapScreenState._nodeSize,
      child: LevelNode(
        levelNumber: levelNumber,
        status: status,
        stars: stars,
        onTap: onTap,
        isCurrent: isCurrent,
      ),
    );
  }

  double _xFactor(int levelNumber) {
    const pattern = [
      0.22,
      0.38,
      0.66,
      0.80,
      0.72,
      0.50,
      0.24,
      0.18,
      0.48,
      0.78,
    ];
    return pattern[(levelNumber - 1) % pattern.length];
  }
}
