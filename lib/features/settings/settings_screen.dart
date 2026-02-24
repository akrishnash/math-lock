import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'settings_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Session',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Zen session duration'),
            subtitle: Text('${settings.sessionDurationMinutes} minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickSessionDuration(context, ref),
          ),
          const Divider(),
          Text(
            'Reward',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Unlock duration after solving problem'),
            subtitle: Text('${settings.rewardDurationMinutes} minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickRewardDuration(context, ref),
          ),
          const SizedBox(height: 24),
          Text(
            'Problem',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Problem type'),
            subtitle: Text(settings.problemType == ProblemType.integration
                ? 'Integration'
                : 'Linear equations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickProblemType(context, ref),
          ),
          ListTile(
            title: const Text('Difficulty'),
            subtitle: Text(settings.problemDifficulty == ProblemDifficulty.medium
                ? 'Medium'
                : 'Easy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickDifficulty(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSessionDuration(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(settingsProvider.notifier);
    final values = [30, 60, 90, 120, 180, 240];
    final v = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Session duration'),
        children: values
            .map((m) => ListTile(
                  title: Text('$m min'),
                  onTap: () => Navigator.pop(context, m),
                ))
            .toList(),
      ),
    );
    if (v != null) await notifier.setSessionDurationMinutes(v);
  }

  Future<void> _pickRewardDuration(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(settingsProvider.notifier);
    final values = [5, 10, 15, 20, 30];
    final v = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Unlock duration'),
        children: values
            .map((m) => ListTile(
                  title: Text('$m min'),
                  onTap: () => Navigator.pop(context, m),
                ))
            .toList(),
      ),
    );
    if (v != null) await notifier.setRewardDurationMinutes(v);
  }

  Future<void> _pickProblemType(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(settingsProvider.notifier);
    final v = await showDialog<ProblemType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Problem type'),
        children: [
          ListTile(
            title: const Text('Linear equations'),
            subtitle: const Text('Junior-friendly'),
            onTap: () => Navigator.pop(context, ProblemType.linear),
          ),
          ListTile(
            title: const Text('Integration'),
            onTap: () => Navigator.pop(context, ProblemType.integration),
          ),
        ],
      ),
    );
    if (v != null) await notifier.setProblemType(v);
  }

  Future<void> _pickDifficulty(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(settingsProvider.notifier);
    final v = await showDialog<ProblemDifficulty>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Difficulty'),
        children: [
          ListTile(
            title: const Text('Easy'),
            onTap: () => Navigator.pop(context, ProblemDifficulty.easy),
          ),
          ListTile(
            title: const Text('Medium'),
            onTap: () => Navigator.pop(context, ProblemDifficulty.medium),
          ),
        ],
      ),
    );
    if (v != null) await notifier.setProblemDifficulty(v);
  }
}
