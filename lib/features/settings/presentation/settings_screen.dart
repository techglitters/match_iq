import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../themes/presentation/controllers/app_progress_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProgress = context.watch<AppProgressController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                ),
                const SizedBox(width: 16),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  secondary: const Icon(Icons.route_rounded),
                  title: const Text('Show solution paths'),
                  subtitle: const Text(
                    'Display the known route for each pair as a faint, color-coded line.',
                  ),
                  value: appProgress.showSolutionPaths,
                  onChanged: (value) => context
                      .read<AppProgressController>()
                      .setShowSolutionPaths(value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  secondary: const Icon(Icons.lock_open_rounded),
                  title: const Text('Free play mode'),
                  subtitle: const Text(
                    'Open every available level without completing earlier levels.',
                  ),
                  value: appProgress.freePlayMode,
                  onChanged: (value) => context
                      .read<AppProgressController>()
                      .setFreePlayMode(value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.90)),
      ),
      child: Column(children: children),
    );
  }
}
