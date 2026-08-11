import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../themes/presentation/controllers/app_progress_controller.dart';
import '../domain/daily_puzzle_history_entry.dart';

class DailyHistoryScreen extends StatelessWidget {
  const DailyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProgress = context.watch<AppProgressController>();
    final history = appProgress.dailyPuzzleHistory(days: 7);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              sliver: SliverList.separated(
                itemCount: history.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _Header(
                      streak: appProgress.dailyStreak(),
                      bestStreak: appProgress.bestDailyStreak(),
                      onBack: () => Navigator.of(context).pop(),
                    );
                  }

                  final entry = history[index - 1];
                  return _DailyHistoryCard(
                    entry: entry,
                    onPlay: entry.isToday
                        ? () => Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.dailyPuzzle)
                        : null,
                    onReplay: entry.isCompleted
                        ? () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.dailyReplay(entry.dateKey))
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.streak,
    required this.bestStreak,
    required this.onBack,
  });

  final int streak;
  final int bestStreak;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Daily History',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatCard(label: 'Streak', value: '$streak days'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(label: 'Best', value: '$bestStreak days'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DailyHistoryCard extends StatelessWidget {
  const _DailyHistoryCard({
    required this.entry,
    required this.onPlay,
    required this.onReplay,
  });

  final DailyPuzzleHistoryEntry entry;
  final VoidCallback? onPlay;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    final challenge = entry.challenge;
    final color = challenge.theme.primaryColor;
    final completed = entry.isCompleted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check_rounded : challenge.theme.icon,
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
                    entry.isToday ? 'Today' : _friendlyDate(entry.date),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(challenge.subtitle),
                  const SizedBox(height: 5),
                  Text(entry.statusLabel),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (completed) _Stars(stars: entry.result.stars),
            if (onReplay != null) ...[
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onReplay,
                icon: const Icon(Icons.replay_rounded),
                tooltip: 'Replay',
              ),
            ] else if (onPlay != null)
              FilledButton(onPressed: onPlay, child: const Text('Play')),
          ],
        ),
      ),
    );
  }

  static String _friendlyDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 3),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
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
            size: 16,
          ),
      ],
    );
  }
}
