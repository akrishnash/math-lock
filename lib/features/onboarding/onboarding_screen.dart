import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_log.dart' as app_log;
import '../auth/auth_service.dart';
import '../settings/settings_state.dart';

// ─── constants ───────────────────────────────────────────────────────────────

const _kPageCount = 5; // welcome | goal | topic | difficulty | sign-in

// ─── screen ──────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  // user selections
  String _selectedGoal = '';
  String _selectedTopic = 'mixed';
  ProblemDifficulty _selectedDifficulty = ProblemDifficulty.easy;

  // sign-in state
  bool _signingIn = false;
  String? _signInError;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _kPageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    }
  }

  void _back() {
    if (_page > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveAndContinue() async {
    await ref.read(settingsProvider.notifier).setQuestionTopic(_selectedTopic);
    await ref
        .read(settingsProvider.notifier)
        .setProblemDifficulty(_selectedDifficulty);
    _next(); // → sign-in page
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _signingIn = true;
      _signInError = null;
    });
    try {
      final user = await AuthService.signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        await _completeOnboarding();
      } else {
        setState(() {
          _signingIn = false;
          _signInError = 'Sign in was cancelled.';
        });
      }
    } catch (e) {
      app_log.log('Onboarding', 'sign-in error: $e');
      if (!mounted) return;
      setState(() {
        _signingIn = false;
        _signInError =
            'Could not sign in. Try again or continue without account.';
      });
    }
  }

  Future<void> _skipSignIn() async {
    await _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.onboardingCompleted, true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              _WelcomePage(onStart: _next),
              _GoalPage(
                selected: _selectedGoal,
                onSelect: (g) => setState(() => _selectedGoal = g),
                onNext: _next,
              ),
              _TopicPage(
                selected: _selectedTopic,
                onSelect: (t) => setState(() => _selectedTopic = t),
                onNext: _next,
                onBack: _back,
              ),
              _DifficultyPage(
                selected: _selectedDifficulty,
                onSelect: (d) => setState(() => _selectedDifficulty = d),
                onNext: _saveAndContinue,
                onBack: _back,
              ),
              _SignInPage(
                loading: _signingIn,
                error: _signInError,
                onGoogle: _signInWithGoogle,
                onSkip: _skipSignIn,
              ),
            ],
          ),

          // progress dots (pages 1–3 only)
          if (_page > 0 && _page < _kPageCount - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: _ProgressDots(current: _page - 1, total: 3),
            ),
        ],
      ),
    );
  }
}

// ─── progress dots ────────────────────────────────────────────────────────────

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.neonPink : AppColors.muted,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── page 0: welcome ──────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const Spacer(flex: 3),

            // icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.neonPink, width: 2),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonPink.withValues(alpha: 0.25),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      color: AppColors.neonPink, size: 40),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border:
                            Border.all(color: AppColors.neonCyan, width: 1.5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '∫',
                          style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              color: AppColors.neonCyan,
                              height: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            Text(
              'EARN YOUR\nSCREEN',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppColors.offWhite,
                height: 1.15,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Block distracting apps.\nSolve a problem to earn access back.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.mutedForeground,
                height: 1.6,
              ),
            ),

            const Spacer(flex: 2),

            const _HowItWorksRow(),

            const Spacer(flex: 2),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.neonPink,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  side: const BorderSide(color: AppColors.offWhite, width: 2),
                  shape: const RoundedRectangleBorder(),
                ),
                child: Text(
                  'GET STARTED',
                  style: GoogleFonts.spaceMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.offWhite,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksRow extends StatelessWidget {
  const _HowItWorksRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HowItWorksStep(
          icon: Icons.block_outlined,
          color: AppColors.neonPink,
          label: 'Block apps',
        ),
        _Arrow(),
        _HowItWorksStep(
          icon: Icons.calculate_outlined,
          color: AppColors.neonCyan,
          label: 'Solve to unlock',
        ),
        _Arrow(),
        _HowItWorksStep(
          icon: Icons.timer_outlined,
          color: AppColors.neonGreen,
          label: 'Earn minutes',
        ),
      ],
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep(
      {required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              border:
                  Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.mutedForeground,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Icon(Icons.arrow_forward, color: AppColors.disabled, size: 16),
    );
  }
}

// ─── page 1: goal ─────────────────────────────────────────────────────────────

const _goals = [
  _GoalOption(
    id: 'social',
    icon: Icons.people_outline_rounded,
    label: 'Social Media',
    subtitle: 'Instagram, TikTok, Twitter',
    color: AppColors.neonPink,
  ),
  _GoalOption(
    id: 'video',
    icon: Icons.play_circle_outline_rounded,
    label: 'Video & Streaming',
    subtitle: 'YouTube, Netflix, Reels',
    color: AppColors.neonCyan,
  ),
  _GoalOption(
    id: 'work',
    icon: Icons.chat_bubble_outline_rounded,
    label: 'Work Distractions',
    subtitle: 'Slack, Email, News',
    color: AppColors.neonPurple,
  ),
  _GoalOption(
    id: 'everything',
    icon: Icons.phonelink_off_outlined,
    label: 'Everything',
    subtitle: 'Total digital detox',
    color: AppColors.neonYellow,
  ),
];

class _GoalOption {
  const _GoalOption({
    required this.id,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });
  final String id;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
}

class _GoalPage extends StatelessWidget {
  const _GoalPage({
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What's your\nbiggest\ndistraction?",
              style: GoogleFonts.spaceMono(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.offWhite,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We'll help you block it when focus matters.",
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 28),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                children: _goals
                    .map((g) => _GoalCard(
                          goal: g,
                          selected: selected == g.id,
                          onTap: () => onSelect(g.id),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: selected.isNotEmpty ? onNext : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.neonPink,
                  disabledBackgroundColor: AppColors.muted,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: BorderSide(
                    color: selected.isNotEmpty
                        ? AppColors.offWhite
                        : Colors.transparent,
                    width: 2,
                  ),
                  shape: const RoundedRectangleBorder(),
                ),
                child: Text(
                  'NEXT →',
                  style: GoogleFonts.spaceMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selected.isNotEmpty
                        ? AppColors.offWhite
                        : AppColors.disabled,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard(
      {required this.goal, required this.selected, required this.onTap});
  final _GoalOption goal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              selected ? goal.color.withValues(alpha: 0.1) : AppColors.surface,
          border: Border.all(
            color: selected ? goal.color : AppColors.disabled,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    goal.color.withValues(alpha: selected ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(goal.icon, color: goal.color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.label,
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? goal.color : AppColors.offWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  goal.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── page 2: topic ────────────────────────────────────────────────────────────

const _topics = [
  _TopicOption(
    id: 'mixed',
    icon: Icons.shuffle_rounded,
    label: 'Mixed',
    subtitle: 'Equations + Capitals',
    color: AppColors.neonPink,
  ),
  _TopicOption(
    id: 'arithmetic',
    icon: Icons.calculate_outlined,
    label: 'Arithmetic',
    subtitle: 'Solve for x',
    color: AppColors.neonCyan,
  ),
  _TopicOption(
    id: 'integration',
    icon: Icons.area_chart_outlined,
    label: 'Calculus',
    subtitle: 'Definite integrals',
    color: AppColors.neonPurple,
  ),
  _TopicOption(
    id: 'geography',
    icon: Icons.public_outlined,
    label: 'Geography',
    subtitle: 'World capitals',
    color: AppColors.neonGreen,
  ),
];

class _TopicOption {
  const _TopicOption({
    required this.id,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });
  final String id;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
}

class _TopicPage extends StatelessWidget {
  const _TopicPage({
    required this.selected,
    required this.onSelect,
    required this.onNext,
    required this.onBack,
  });
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack,
              child: const Icon(Icons.arrow_back,
                  color: AppColors.mutedForeground, size: 22),
            ),
            const SizedBox(height: 20),
            Text(
              'What should\nchallenge you?',
              style: GoogleFonts.spaceMono(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.offWhite,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You'll solve one of these to unlock a blocked app.",
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 28),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                children: _topics
                    .map((t) => _TopicCard(
                          topic: t,
                          selected: selected == t.id,
                          onTap: () => onSelect(t.id),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 8),
            Center(
              child: Text(
                'You can change this anytime in settings.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.disabled),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.neonPink,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: AppColors.offWhite, width: 2),
                  shape: const RoundedRectangleBorder(),
                ),
                child: Text(
                  'NEXT →',
                  style: GoogleFonts.spaceMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.offWhite,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard(
      {required this.topic, required this.selected, required this.onTap});
  final _TopicOption topic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? topic.color.withValues(alpha: 0.1)
              : AppColors.surface,
          border: Border.all(
            color: selected ? topic.color : AppColors.disabled,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    topic.color.withValues(alpha: selected ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(topic.icon, color: topic.color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.label,
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? topic.color : AppColors.offWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topic.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── page 3: difficulty ───────────────────────────────────────────────────────

class _DifficultyPage extends StatelessWidget {
  const _DifficultyPage({
    required this.selected,
    required this.onSelect,
    required this.onNext,
    required this.onBack,
  });
  final ProblemDifficulty selected;
  final ValueChanged<ProblemDifficulty> onSelect;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack,
              child: const Icon(Icons.arrow_back,
                  color: AppColors.mutedForeground, size: 22),
            ),
            const SizedBox(height: 20),
            Text(
              'How hard\nshould it be?',
              style: GoogleFonts.spaceMono(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.offWhite,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Harder problems earn more unlock minutes.',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 40),

            _BigDiffCard(
              label: 'EASY',
              description:
                  'Simpler numbers, quicker to solve.\nGood for getting started.',
              example: '2x + 3 = 9',
              color: AppColors.neonGreen,
              selected: selected == ProblemDifficulty.easy,
              onTap: () => onSelect(ProblemDifficulty.easy),
            ),
            const SizedBox(height: 16),
            _BigDiffCard(
              label: 'MEDIUM',
              description:
                  'Larger numbers, takes more thought.\nFor when you mean it.',
              example: '7x − 15 = 48',
              color: AppColors.neonPink,
              selected: selected == ProblemDifficulty.medium,
              onTap: () => onSelect(ProblemDifficulty.medium),
            ),

            const Spacer(),

            Center(
              child: Text(
                'You can change this anytime in settings.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.disabled),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.neonPink,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: AppColors.offWhite, width: 2),
                  shape: const RoundedRectangleBorder(),
                ),
                child: Text(
                  'LOOKS GOOD →',
                  style: GoogleFonts.spaceMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.offWhite,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigDiffCard extends StatelessWidget {
  const _BigDiffCard({
    required this.label,
    required this.description,
    required this.example,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String description;
  final String example;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              selected ? color.withValues(alpha: 0.08) : AppColors.surface,
          border: Border.all(
            color: selected ? color : AppColors.disabled,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.spaceMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: selected ? color : AppColors.offWhite,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: selected ? 0.15 : 0.06),
                border:
                    Border.all(color: color.withValues(alpha: 0.3), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                example,
                style: GoogleFonts.spaceMono(
                  fontSize: 13,
                  color: selected ? color : AppColors.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── page 4: sign-in ──────────────────────────────────────────────────────────

class _SignInPage extends StatelessWidget {
  const _SignInPage({
    required this.loading,
    required this.error,
    required this.onGoogle,
    required this.onSkip,
  });
  final bool loading;
  final String? error;
  final VoidCallback onGoogle;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
        child: Column(
          children: [
            const Spacer(flex: 2),

            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withValues(alpha: 0.08),
                border: Border.all(color: AppColors.neonGreen, width: 2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.neonGreen, size: 36),
            ),

            const SizedBox(height: 28),

            Text(
              "You're all set.",
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.offWhite,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Sign in to sync your stats and settings\nacross devices. Totally optional.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.mutedForeground,
                height: 1.6,
              ),
            ),

            const Spacer(flex: 2),

            _BenefitRow(
                icon: Icons.sync_rounded,
                color: AppColors.neonCyan,
                text: 'Settings sync across devices'),
            const SizedBox(height: 12),
            _BenefitRow(
                icon: Icons.bar_chart_rounded,
                color: AppColors.neonPurple,
                text: 'Stats backed up to cloud'),
            const SizedBox(height: 12),
            _BenefitRow(
                icon: Icons.lock_open_outlined,
                color: AppColors.neonGreen,
                text: 'Core features always free'),

            const Spacer(flex: 2),

            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.destructive.withValues(alpha: 0.1),
                  border:
                      Border.all(color: AppColors.destructive, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.offWhite),
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : onGoogle,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.neonPink,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: AppColors.offWhite, width: 2),
                  shape: const RoundedRectangleBorder(),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.offWhite),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _GoogleIcon(),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: GoogleFonts.spaceMono(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.offWhite,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 14),

            TextButton(
              onPressed: loading ? null : onSkip,
              child: Text(
                'Continue without account',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow(
      {required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style:
              GoogleFonts.inter(fontSize: 14, color: AppColors.offWhite),
        ),
      ],
    );
  }
}

// ─── Google icon ──────────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        size: const Size(20, 20), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    final sweeps = [
      const Offset(0, 90),
      const Offset(90, 90),
      const Offset(180, 90),
      const Offset(270, 90),
    ];
    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r - 1.75),
        sweeps[i].dx * 3.14159 / 180,
        sweeps[i].dy * 3.14159 / 180,
        false,
        paint,
      );
    }
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(Offset(cx, cy), Offset(cx + r - 1.75, cy), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
