import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/theme_catalog.dart';
import '../domain/game_theme.dart';
import 'controllers/app_progress_controller.dart';

class ThemeDetailScreen extends StatelessWidget {
  const ThemeDetailScreen({
    this.themeId = ThemeCatalog.natureThemeId,
    super.key,
  });

  final String themeId;

  @override
  Widget build(BuildContext context) {
    final appProgress = context.watch<AppProgressController>();
    final theme = appProgress.themeById(themeId) ?? ThemeCatalog.natureWorld;
    final progress = appProgress.progressForTheme(theme.id);
    final playLevel = appProgress.playLevelNumber(theme.id);
    final completion = theme.maxStars == 0
        ? 0.0
        : progress.totalStars / theme.maxStars;
    if (theme.isAvailable && appProgress.activeTheme.id != theme.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<AppProgressController>().selectTheme(theme.id);
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.settings),
                        icon: const Icon(Icons.settings_rounded),
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _HeroPanel(
                    theme: theme,
                    completion: completion,
                    totalStars: progress.totalStars,
                    unlockedLevel: progress.highestUnlockedLevel,
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Play Level $playLevel',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.themeLevel(theme.id, playLevel)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.themeLevels(theme.id)),
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Level Map'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.theme,
    required this.completion,
    required this.totalStars,
    required this.unlockedLevel,
  });

  final GameTheme theme;
  final double completion;
  final int totalStars;
  final int unlockedLevel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(theme.icon, color: theme.primaryColor, size: 42),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(theme.description),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricPill(label: 'Levels', value: '15'),
                _MetricPill(label: 'Unlocked', value: '$unlockedLevel'),
                _MetricPill(
                  label: 'Stars',
                  value: '$totalStars / ${theme.maxStars}',
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: completion.clamp(0, 1),
                minHeight: 12,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Text('$label $value'),
      ),
    );
  }
}
