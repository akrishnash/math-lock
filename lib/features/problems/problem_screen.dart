import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/platform/zen_platform.dart';
import '../../core/utils/app_log.dart' as app_log;
import '../settings/settings_state.dart';
import '../stats/stats_state.dart';
import 'models/challenge_question.dart';
import 'providers/question_providers.dart';
import 'topic_registry.dart';

// ── design tokens ─────────────────────────────────────────────────────────────
const _black = Color(0xFF000000);
const _card = Color(0xFF1C1C1E);
const _red = Color(0xFFFF3B30);
const _gradA = Color(0xFFB3FF6E);
const _gradB = Color(0xFF00C9A7);
const _muted = Color(0xFF8E8E93);
const _white = Color(0xFFFFFFFF);

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

class _ProblemScreenState extends ConsumerState<ProblemScreen>
    with SingleTickerProviderStateMixin {
  late ProblemScreenArgs _args;
  ChallengeQuestion? _question;
  String _input = '';
  String? _selectedOption;
  bool _checking = false;
  bool _showError = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _args = widget.args ?? const ProblemScreenArgs(
      packageName: '',
      appLabel: 'App',
      rewardMinutes: 10,
    );
    app_log.log('Challenge', 'initState: appLabel=${_args.appLabel} rewardMinutes=${_args.rewardMinutes}');

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _generate();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
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

  Future<void> _showSuccessAndGoHome() async {
    final mins = _args.rewardMinutes;
    final packageName = _args.packageName;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_gradA, _gradB]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.check_rounded, color: _black, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                'Unlocked!',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$mins minutes of access. Use it wisely.',
                style: GoogleFonts.inter(fontSize: 15, color: _muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_gradA, _gradB]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Enjoy',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    _shakeController.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      color: _showError ? const Color(0xFF2A0000) : _black,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Prove You Need It',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _white,
                      ),
                    ),
                    const Spacer(),
                    if (_showError)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Wrong answer — try again',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // ── math prompt ──────────────────────────────────────
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          final offset = _showError
                              ? (8 * (0.5 - (_shakeAnimation.value % 1)).abs() * 2 - 4)
                              : 0.0;
                          return Transform.translate(
                            offset: Offset(offset, 0),
                            child: child,
                          );
                        },
                        child: _MathPromptCard(
                          prompt: q?.prompt ?? '',
                          accentColor: _showError ? _red : _accentColor,
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (isMultipleChoice) ...[
                        ...?q?.options.map((opt) {
                          final selected = _selectedOption == opt;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: _checking ? null : () => setState(() => _selectedOption = opt),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _accentColor.withValues(alpha: 0.15)
                                      : _card,
                                  borderRadius: BorderRadius.circular(14),
                                  border: selected
                                      ? Border.all(color: _accentColor, width: 1.5)
                                      : null,
                                ),
                                child: Text(
                                  opt,
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                    color: selected ? _accentColor : _white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }),
                      ] else ...[
                        // ── answer display ──────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(16),
                            border: _showError
                                ? Border.all(color: _red.withValues(alpha: 0.6), width: 1.5)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _input.isEmpty ? '0' : _input,
                                style: GoogleFonts.inter(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w600,
                                  color: _input.isEmpty ? _muted : _accentColor,
                                  height: 1,
                                ),
                              ),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 500),
                                opacity: _input.isEmpty ? 0 : 1,
                                child: Text(
                                  '|',
                                  style: GoogleFonts.inter(
                                    fontSize: 48,
                                    color: _accentColor,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── numpad ───────────────────────────────────────
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.6,
                          children: [
                            '7', '8', '9',
                            '4', '5', '6',
                            '1', '2', '3',
                            '-', '0', 'DEL',
                          ].map((key) {
                            final isDel = key == 'DEL';
                            return GestureDetector(
                              onTap: _checking ? null : () => _onKeyPress(key),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDel
                                      ? _red.withValues(alpha: 0.12)
                                      : _card,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: isDel
                                      ? const Icon(Icons.backspace_rounded, color: _red, size: 22)
                                      : Text(
                                          key,
                                          style: GoogleFonts.inter(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w500,
                                            color: _white,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── submit ───────────────────────────────────────────
                      GestureDetector(
                        onTap: (_checking || !_hasAnswer) ? null : _submit,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _hasAnswer ? 1.0 : 0.4,
                          child: Container(
                            width: double.infinity,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_gradA, _gradB]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: _checking
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: _black,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Submit Answer',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _black,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
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
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            _isIntegral ? 'EVALUATE THE INTEGRAL' : 'SOLVE FOR x',
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              color: accentColor,
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
      final parts = prompt.split(' ');
      final rest = parts.sublist(1).join(' ');
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: '∫ ',
              style: GoogleFonts.inter(
                fontSize: 48,
                color: _white,
                height: 1,
              ),
            ),
            TextSpan(
              text: rest,
              style: GoogleFonts.inter(
                fontSize: 26,
                color: _white,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }
    return Text(
      prompt,
      style: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: _white,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }
}
