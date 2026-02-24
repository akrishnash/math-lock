import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../problems/problem_screen.dart';
import '../settings/settings_state.dart';

class BlockScreen extends ConsumerWidget {
  const BlockScreen({
    super.key,
    required this.packageName,
    required this.appLabel,
    required this.remainingSeconds,
    required this.rewardMinutes,
  });

  final String packageName;
  final String appLabel;
  final int remainingSeconds;
  final int rewardMinutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rewardMinutes = ref.watch(settingsProvider).rewardDurationMinutes;
    final minutes = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.block,
                  size: 64,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '$appLabel is locked',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Time left in Zen session: $timeStr',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 1),
              FilledButton(
                onPressed: () {
                  context.push(
                    '/problem',
                    extra: ProblemScreenArgs(
                      packageName: packageName,
                      appLabel: appLabel,
                      rewardMinutes: rewardMinutes,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Solve problem to unlock for a while'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
