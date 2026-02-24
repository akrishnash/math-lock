import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/zen_platform.dart';
import '../settings/settings_state.dart';
import '../stats/stats_state.dart';

class ProblemScreenArgs {
  const ProblemScreenArgs({
    required this.packageName,
    required this.appLabel,
    required this.rewardMinutes,
  });

  final String packageName;
  final String appLabel;
  final int rewardMinutes;
}

class ProblemScreen extends ConsumerStatefulWidget {
  const ProblemScreen({super.key, this.args});

  final ProblemScreenArgs? args;

  @override
  ConsumerState<ProblemScreen> createState() => _ProblemScreenState();
}

class _ProblemScreenState extends ConsumerState<ProblemScreen> {
  late ProblemScreenArgs _args;
  String _problemText = '';
  double _expectedAnswer = 0;
  final _answerController = TextEditingController();
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _args = widget.args ?? const ProblemScreenArgs(
      packageName: '',
      appLabel: 'App',
      rewardMinutes: 10,
    );
    _generate();
  }

  void _generate() {
    final settings = ref.read(settingsProvider);
    if (settings.problemType == ProblemType.linear) {
      _generateLinear(settings.problemDifficulty);
    } else {
      _generateIntegration(settings.problemDifficulty);
    }
  }

  void _generateLinear(ProblemDifficulty difficulty) {
    final r = Random();
    int a, b, c;
    if (difficulty == ProblemDifficulty.easy) {
      a = r.nextInt(5) + 1;
      b = r.nextInt(10) - 5;
      c = r.nextInt(30) - 10;
    } else {
      a = r.nextInt(8) + 2;
      b = r.nextInt(20) - 10;
      c = r.nextInt(80) - 40;
    }
    // ax + b = c  =>  x = (c - b) / a
    final x = (c - b) / a;
    if (x != x.roundToDouble()) {
      _generateLinear(difficulty);
      return;
    }
    final bStr = b >= 0 ? '+ $b' : '- ${-b}';
    _problemText = '${a}x $bStr = $c';
    _expectedAnswer = (c - b) / a;
    setState(() {
      _error = null;
      _answerController.clear();
    });
  }

  void _generateIntegration(ProblemDifficulty difficulty) {
    final r = Random();
    // ∫ k*x^n dx from 0 to upper = k * upper^(n+1) / (n+1)
    int k, n, upper;
    if (difficulty == ProblemDifficulty.easy) {
      k = r.nextInt(3) + 1;
      n = 1;
      upper = r.nextInt(4) + 1;
    } else {
      k = r.nextInt(4) + 1;
      n = r.nextInt(2) + 1;
      upper = r.nextInt(5) + 1;
    }
    final answer = k * (pow(upper, n + 1) / (n + 1)).toDouble();
    _problemText = '∫ $k*x^$n dx from 0 to $upper';
    _expectedAnswer = answer;
    setState(() {
      _error = null;
      _answerController.clear();
    });
  }

  Future<void> _submit() async {
    final raw = _answerController.text.trim();
    final value = double.tryParse(raw);
    if (value == null) {
      setState(() => _error = 'Enter a number');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    const tolerance = 0.01;
    final correct = (value - _expectedAnswer).abs() < tolerance;
    if (correct) {
      await ZenPlatform.allowPackageForMinutes(
        packageName: _args.packageName,
        minutes: _args.rewardMinutes,
      );
      ref.read(statsProvider.notifier).recordUnlockViaProblem();
      if (mounted) {
        context.go('/');
      }
    } else {
      setState(() {
        _checking = false;
        _error = 'Incorrect. Try again.';
        _generate();
      });
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solve to unlock'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Unlock ${_args.appLabel} for ${_args.rewardMinutes} minutes',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Problem',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _problemText,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _answerController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Answer (number)',
                          errorText: _error,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _checking ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _checking
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _checking ? null : () => _generate(),
                child: const Text('New problem'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
