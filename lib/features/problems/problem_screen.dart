import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/platform/zen_platform.dart';
import '../../core/utils/app_log.dart' as app_log;
import '../settings/settings_state.dart';
import '../stats/stats_state.dart';
import 'models/challenge_question.dart';
import 'providers/question_providers.dart';
import 'topic_registry.dart';

const String _fullLockPackage = '_full';

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
  ChallengeQuestion? _question;
  String _input = '';
  String? _selectedOption;
  bool _checking = false;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _args = widget.args ?? const ProblemScreenArgs(
      packageName: '',
      appLabel: 'App',
      rewardMinutes: 2,
    );
    app_log.log('Challenge', 'initState: appLabel=${_args.appLabel} rewardMinutes=${_args.rewardMinutes}');
    _generate();
  }

  void _generate() {
    final settings = ref.read(settingsProvider);
    final topicId = TopicRegistry.topicIds.contains(settings.questionTopic)
        ? settings.questionTopic
        : 'mixed';
    final r = Random();
    final q = generateQuestion(
      topicId: topicId,
      difficulty: settings.problemDifficulty,
      random: r,
    );
    setState(() {
      _question = q;
      _showError = false;
      _input = '';
      _selectedOption = null;
    });
  }

  void _onKeyPress(String key) {
    if (key == 'DEL') {
      setState(() {
        if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
      });
    } else if (key == '-' && _input.isEmpty) {
      setState(() => _input = '-');
    } else if (key != '-') {
      setState(() => _input += key);
    }
  }

  int get _penaltyMinutes => ref.read(settingsProvider).penaltyMinutes;

  Future<void> _showSuccessAndGoHome() async {
    final mins = _args.rewardMinutes;
    final packageName = _args.packageName;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Great!',
          style: GoogleFonts.spaceMono(color: AppColors.offWhite),
        ),
        content: Text(
          '$mins minutes grace for you. Enjoy yourself.',
          style: GoogleFonts.inter(color: AppColors.offWhite),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Enjoy'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (packageName.isNotEmpty && packageName != _fullLockPackage) {
      await ZenPlatform.launchApp(packageName);
    }
    if (!mounted) return;
    context.go('/');
  }

  bool get _hasAnswer {
    final q = _question;
    if (q == null) return false;
    if (q.inputKind == ChallengeInputKind.multipleChoice) {
      return _selectedOption != null;
    }
    return _input.isNotEmpty;
  }

  Future<void> _submit() async {
    final q = _question;
    if (q == null) return;

    setState(() {
      _checking = true;
      _showError = false;
    });

    bool correct;
    if (q.inputKind == ChallengeInputKind.multipleChoice) {
      correct = _selectedOption == q.correctAnswer;
    } else {
      final value = double.tryParse(_input);
      if (value == null) {
        setState(() => _checking = false);
        return;
      }
      final expected = double.tryParse(q.correctAnswer);
      correct = expected != null && (value - expected).abs() < 0.01;
    }

    if (correct) {
      if (ref.read(settingsProvider).enableVibration) {
        HapticFeedback.heavyImpact();
      }
      if (_args.packageName == _fullLockPackage) {
        await ZenPlatform.allowFullUnlockForMinutes(_args.rewardMinutes);
      } else {
        await ZenPlatform.allowPackageForMinutes(
          packageName: _args.packageName,
          minutes: _args.rewardMinutes,
        );
      }
      ref.read(statsProvider.notifier).recordUnlockViaProblem();
      if (!mounted) return;
      await _showSuccessAndGoHome();
      return;
    }

    if (ref.read(settingsProvider).enableVibration) {
      HapticFeedback.vibrate();
    }
    setState(() {
      _checking = false;
      _showError = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _showError = false);
    _generate();
  }

  Color get _accentColor => ref.watch(settingsProvider).accentColor;

  @override
  Widget build(BuildContext context) {
    if (_question == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _generate();
      });
    }

    final q = _question;
    final isMultipleChoice = q?.inputKind == ChallengeInputKind.multipleChoice;

    return Scaffold(
      backgroundColor: _showError ? AppColors.destructive : AppColors.background,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: _showError ? AppColors.destructive : AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.offWhite, width: 4),
                    ),
                  ),
                  child: Text(
                    'PROVE YOU NEED IT.',
                    style: GoogleFonts.spaceMono(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: AppColors.offWhite,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      if (_showError) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            border: Border.all(color: AppColors.offWhite, width: 4),
                          ),
                          child: Text(
                            'ACCESS DENIED. +$_penaltyMinutes MINS ADDED TO TIMER.',
                            style: GoogleFonts.spaceMono(
                              fontSize: 14,
                              color: AppColors.offWhite,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      _MathPromptCard(
                        prompt: q?.prompt ?? '',
                        accentColor: _accentColor,
                      ),
                      const SizedBox(height: 24),
                      if (isMultipleChoice) ...[
                        ...?q?.options.map((opt) {
                          final selected = _selectedOption == opt;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: Material(
                                color: selected ? _accentColor.withValues(alpha: 0.2) : AppColors.surface,
                                child: InkWell(
                                  onTap: _checking ? null : () => setState(() => _selectedOption = opt),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: selected ? _accentColor : AppColors.offWhite,
                                        width: 4,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        opt,
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          color: AppColors.offWhite,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.offWhite, width: 4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _input,
                                style: GoogleFonts.spaceMono(
                                  fontSize: 48,
                                  color: _accentColor,
                                ),
                              ),
                              Text(
                                '_',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 48,
                                  color: _accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.8,
                          children: [
                            '7', '8', '9',
                            '4', '5', '6',
                            '1', '2', '3',
                            '-', '0', 'DEL',
                          ].map((key) {
                            final isDel = key == 'DEL';
                            return Material(
                              color: AppColors.surface,
                              child: InkWell(
                                onTap: _checking ? null : () => _onKeyPress(key),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.offWhite, width: 4),
                                    color: isDel ? AppColors.surface : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      key,
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 24,
                                        color: isDel ? AppColors.destructive : AppColors.offWhite,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: (_checking || !_hasAnswer) ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: !_hasAnswer ? AppColors.muted : _accentColor,
                            foregroundColor: !_hasAnswer ? AppColors.disabled : AppColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            side: BorderSide(
                              color: !_hasAnswer ? AppColors.disabled : AppColors.offWhite,
                              width: 4,
                            ),
                          ),
                          child: Text(
                            'SUBMIT ANSWER',
                            style: GoogleFonts.spaceMono(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MathPromptCard extends StatelessWidget {
  const _MathPromptCard({required this.prompt, required this.accentColor});

  final String prompt;
  final Color accentColor;

  bool get _isIntegral => prompt.startsWith('∫');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.offWhite, width: 4),
      ),
      child: Column(
        children: [
          Text(
            _isIntegral ? 'EVALUATE THE INTEGRAL' : 'SOLVE FOR x',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 2.5,
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _buildMathText(),
        ],
      ),
    );
  }

  Widget _buildMathText() {
    if (_isIntegral) {
      // Render ∫ larger, rest normal
      final parts = prompt.split(' ');
      // parts[0] = '∫', rest is the expression
      final rest = parts.sublist(1).join(' ');
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: '∫ ',
              style: GoogleFonts.spaceMono(
                fontSize: 48,
                color: AppColors.offWhite,
                height: 1,
              ),
            ),
            TextSpan(
              text: rest,
              style: GoogleFonts.spaceMono(
                fontSize: 26,
                color: AppColors.offWhite,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }
    return Text(
      prompt,
      style: GoogleFonts.spaceMono(
        fontSize: 28,
        color: AppColors.offWhite,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }
}
