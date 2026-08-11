import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/widgets/primary_button.dart';
import '../../daily/domain/daily_puzzle_challenge.dart';
import '../../daily/domain/daily_puzzle_result.dart';
import '../../themes/data/theme_catalog.dart';
import '../../themes/domain/game_theme.dart';
import '../../themes/presentation/controllers/app_progress_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProgress = context.watch<AppProgressController>();
    final nature = ThemeCatalog.natureWorld;
    final continueTheme =
        appProgress.themeById(
          appProgress.data.lastPlayedThemeId ?? ThemeCatalog.natureThemeId,
        ) ??
        nature;
    final continueProgress = appProgress.progressForTheme(continueTheme.id);
    final continueLevel = appProgress.continueLevelNumber();
    final dailyChallenge = appProgress.dailyPuzzleChallenge();
    final dailyResult = appProgress.dailyPuzzleResult();
    final dailyStreak = appProgress.dailyStreak();
    final bestDailyStreak = appProgress.bestDailyStreak();
    if (!appProgress.data.hasSeenHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<AppProgressController>().markHomeSeen();
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              sliver: SliverList.list(
                children: [
                  _HomeHeader(
                    onSettings: () =>
                        Navigator.of(context).pushNamed(AppRoutes.settings),
                  ),
                  const SizedBox(height: 26),
                  if (appProgress.hasPlayedLevel) ...[
                    _ContinueCard(
                      theme: continueTheme,
                      levelNumber: continueLevel,
                      progress:
                          continueProgress.totalStars / continueTheme.maxStars,
                      stars: continueProgress
                          .levelProgress(continueLevel)
                          .stars,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.themeLevel(continueTheme.id, continueLevel),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    _FirstPlayCard(
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.natureTheme),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _SectionHeader(
                    title: 'Themes',
                    actionLabel: 'Browse',
                    onAction: () =>
                        Navigator.of(context).pushNamed(AppRoutes.themes),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 196,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ThemeCatalog.all.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final theme = ThemeCatalog.all[index];
                        final progress = appProgress.progressForTheme(theme.id);
                        return _ThemePreviewCard(
                          theme: theme,
                          progress: theme.maxStars == 0
                              ? 0
                              : progress.totalStars / theme.maxStars,
                          onTap: theme.isAvailable
                              ? () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.themeDetail(theme.id))
                              : () => _showComingSoon(context),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  _DailyPuzzleCard(
                    challenge: dailyChallenge,
                    result: dailyResult,
                    streak: dailyStreak,
                    bestStreak: bestDailyStreak,
                    onTap: dailyResult.completed
                        ? () => _showComeBackTomorrow(context)
                        : () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.dailyPuzzle),
                    onHistory: () =>
                        Navigator.of(context).pushNamed(AppRoutes.dailyHistory),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  void _showComeBackTomorrow(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Come back tomorrow')));
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Link & Learn',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Match things that belong together',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onSettings,
          icon: const Icon(Icons.settings_rounded),
          tooltip: 'Settings',
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.theme,
    required this.levelNumber,
    required this.progress,
    required this.stars,
    required this.onTap,
  });

  final GameTheme theme;
  final int levelNumber;
  final double progress;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ThemeIconBubble(icon: theme.icon, color: theme.primaryColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue Playing',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text('${theme.name} - Level $levelNumber'),
                  ],
                ),
              ),
              _Stars(stars: stars),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 10,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Continue',
            icon: Icons.play_arrow_rounded,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _FirstPlayCard extends StatelessWidget {
  const _FirstPlayCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          const _ThemeIconBubble(
            icon: Icons.local_florist,
            color: Color(0xFF2E7D32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nature World',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                const Text('Seeds, flowers, trees, rain, and more'),
              ],
            ),
          ),
          FilledButton(onPressed: onTap, child: const Text('Play')),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.theme,
    required this.progress,
    required this.onTap,
  });

  final GameTheme theme;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = !theme.isAvailable;

    return SizedBox(
      width: 220,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ThemeIconBubble(icon: theme.icon, color: theme.primaryColor),
                  const Spacer(),
                  if (locked) const Icon(Icons.lock_rounded),
                ],
              ),
              const Spacer(),
              Text(theme.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(locked ? 'Coming Soon' : '${theme.levels.length} Levels'),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyPuzzleCard extends StatelessWidget {
  const _DailyPuzzleCard({
    required this.challenge,
    required this.result,
    required this.streak,
    required this.bestStreak,
    required this.onTap,
    required this.onHistory,
  });

  final DailyPuzzleChallenge challenge;
  final DailyPuzzleResult result;
  final int streak;
  final int bestStreak;
  final VoidCallback onTap;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final completed = result.completed;
    final stars = result.stars;
    final bestMoves = result.bestMoves ?? result.moves ?? 0;
    final color = challenge.theme.primaryColor;

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: _GlassCard(
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check_circle_rounded : challenge.theme.icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(challenge.subtitle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TinyPill(
                        icon: completed
                            ? Icons.check_rounded
                            : Icons.play_arrow_rounded,
                        label: completed
                            ? 'Solved - $bestMoves moves'
                            : 'Ready today',
                      ),
                      _TinyPill(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Streak $streak',
                      ),
                      if (bestStreak > streak)
                        _TinyPill(
                          icon: Icons.emoji_events_rounded,
                          label: 'Best $bestStreak',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (completed)
              _Stars(stars: stars)
            else
              const Icon(Icons.chevron_right_rounded),
            IconButton(
              onPressed: onHistory,
              icon: const Icon(Icons.history_rounded),
              tooltip: 'Daily history',
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _ThemeIconBubble extends StatelessWidget {
  const _ThemeIconBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 1; index <= 3; index += 1)
          Icon(
            index <= stars ? Icons.star_rounded : Icons.star_border_rounded,
            color: const Color(0xFFFFB300),
            size: 18,
          ),
      ],
    );
  }
}
