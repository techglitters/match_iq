import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../data/theme_catalog.dart';
import '../domain/game_theme.dart';
import 'controllers/app_progress_controller.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProgress = context.watch<AppProgressController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              sliver: SliverList.separated(
                itemCount: ThemeCatalog.all.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _Header(onBack: () => Navigator.of(context).pop());
                  }

                  final theme = ThemeCatalog.all[index - 1];
                  final progress = appProgress.progressForTheme(theme.id);
                  return _ThemeCard(
                    theme: theme,
                    progressText: theme.isAvailable
                        ? '${progress.totalStars}/${theme.maxStars} stars'
                        : 'Coming Soon',
                    onTap: theme.isAvailable
                        ? () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.themeDetail(theme.id))
                        : () => _showComingSoon(context),
                  );
                },
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
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        Text(
          'Choose a World',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.progressText,
    required this.onTap,
  });

  final GameTheme theme;
  final String progressText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = !theme.isAvailable;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.14)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(theme.icon, color: theme.primaryColor, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(theme.description),
                    const SizedBox(height: 8),
                    Text(progressText),
                  ],
                ),
              ),
              Icon(locked ? Icons.lock_rounded : Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
