import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_service.dart';
import '../settings/settings_state.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _page = 0;
  bool _saving = false;

  String _goal = 'focus';
  String _selectedTopic = 'mixed';
  ProblemDifficulty _selectedDifficulty = ProblemDifficulty.easy;

  static const _goals = <_GoalOption>[
    _GoalOption(
      id: 'focus',
      title: 'Stay focused',
      subtitle: 'Block distractions while studying or working.',
      icon: Icons.center_focus_strong_rounded,
      color: AppColors.neonPink,
    ),
    _GoalOption(
      id: 'discipline',
      title: 'Build discipline',
      subtitle: 'Add friction before social and entertainment apps.',
      icon: Icons.fitness_center_rounded,
      color: AppColors.neonYellow,
    ),
    _GoalOption(
      id: 'screen-time',
      title: 'Reduce screen time',
      subtitle: 'Use short unlock windows so your usage naturally drops.',
      icon: Icons.hourglass_top_rounded,
      color: AppColors.neonCyan,
    ),
  ];

  static const _topics = <_TopicOption>[
    _TopicOption(
      id: 'mixed',
      icon: Icons.shuffle_rounded,
      label: 'Mixed',
      subtitle: 'A bit of everything',
      color: AppColors.neonPink,
    ),
    _TopicOption(
      id: 'arithmetic',
      icon: Icons.calculate_outlined,
      label: 'Arithmetic',
      subtitle: 'Linear equations and quick math',
      color: AppColors.neonCyan,
    ),
    _TopicOption(
      id: 'algebra',
      icon: Icons.functions_outlined,
      label: 'Algebra',
      subtitle: 'Variables and expressions',
      color: AppColors.neonPurple,
    ),
    _TopicOption(
      id: 'integration',
      icon: Icons.area_chart_outlined,
      label: 'Integration',
      subtitle: 'Definite and basic integral practice',
      color: AppColors.neonYellow,
    ),
    _TopicOption(
      id: 'geography',
      icon: Icons.public_outlined,
      label: 'Geography',
      subtitle: 'World capitals quiz',
      color: AppColors.neonGreen,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page >= 4) return;
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _back() async {
    if (_page <= 0) return;
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _complete() async {
    await ref.read(settingsProvider.notifier).setQuestionTopic(_selectedTopic);
    await ref.read(settingsProvider.notifier).setProblemDifficulty(_selectedDifficulty);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.onboardingCompleted, true);
    await prefs.setString(StorageKeys.onboardingGoal, _goal);

    if (!mounted) return;
    context.go('/');
  }

  Future<void> _signInAndFinish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final user = await AuthService.signInWithGoogle();
      if (!mounted) return;
      if (user == null) {
        setState(() => _saving = false);
        _showError('Sign in was cancelled.');
        return;
      }
      await _complete();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(_userFriendlySignInError(e));
    }
  }

  Future<void> _finishWithoutAccount() async {
    if (_saving) return;
    setState(() => _saving = true);
    await _complete();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.destructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _ProgressBar(currentStep: _page + 1, totalSteps: 5),
            const SizedBox(height: 12),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _WelcomeStep(onNext: _next),
                  _GoalStep(
                    options: _goals,
                    selected: _goal,
                    onSelected: (id) => setState(() => _goal = id),
                    onNext: _next,
                    onBack: _back,
                  ),
                  _TopicStep(
                    options: _topics,
                    selected: _selectedTopic,
                    onSelected: (id) => setState(() => _selectedTopic = id),
                    onNext: _next,
                    onBack: _back,
                  ),
                  _DifficultyStep(
                    selected: _selectedDifficulty,
                    onSelected: (difficulty) => setState(() => _selectedDifficulty = difficulty),
                    onNext: _next,
                    onBack: _back,
                  ),
                  _SignInStep(
                    saving: _saving,
                    onBack: _back,
                    onSignIn: _signInAndFinish,
                    onSkip: _finishWithoutAccount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _userFriendlySignInError(Object e) {
  final s = e.toString().toLowerCase();
  if (s.contains('apiexception') || s.contains(' 10 ') || s.contains('10]')) {
    return 'Google Sign-In is not configured for this build yet. Check Firebase SHA-1 and web client ID.';
  }
  if (s.contains('network') || s.contains('connection')) {
    return 'Network error. Check your connection and try again.';
  }
  if (s.contains('firebase') || s.contains('initialize')) {
    return 'Firebase setup is incomplete for this app build.';
  }
  return 'Unable to sign in right now. Please try again.';
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final active = index < currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
              height: 4,
              decoration: BoxDecoration(
                color: active ? AppColors.neonPink : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonPink, width: 3),
            ),
            child: const Icon(
              Icons.lock_clock_outlined,
              color: AppColors.neonPink,
              size: 64,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Earn your screen time.',
            style: GoogleFonts.spaceMono(
              color: AppColors.offWhite,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We will set up your unlock challenges in under a minute.',
            style: GoogleFonts.inter(
              color: AppColors.mutedForeground,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.neonPink,
              foregroundColor: AppColors.offWhite,
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: const BorderSide(color: AppColors.offWhite, width: 3),
            ),
            child: Text(
              'Start setup',
              style: GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.onNext,
    required this.onBack,
  });

  final List<_GoalOption> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'What is your main goal?',
      subtitle: 'Pick the one that best describes why you are installing this.',
      onBack: onBack,
      onNext: onNext,
      child: Column(
        children: options.map((goal) {
          final isSelected = selected == goal.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectableCard(
              selected: isSelected,
              color: goal.color,
              title: goal.title,
              subtitle: goal.subtitle,
              leading: Icon(goal.icon, color: goal.color),
              onTap: () => onSelected(goal.id),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopicStep extends StatelessWidget {
  const _TopicStep({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.onNext,
    required this.onBack,
  });

  final List<_TopicOption> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Choose your challenge topic',
      subtitle: 'You can change this anytime from settings.',
      onBack: onBack,
      onNext: onNext,
      child: Column(
        children: options.map((topic) {
          final isSelected = selected == topic.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectableCard(
              selected: isSelected,
              color: topic.color,
              title: topic.label,
              subtitle: topic.subtitle,
              leading: Icon(topic.icon, color: topic.color),
              onTap: () => onSelected(topic.id),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DifficultyStep extends StatelessWidget {
  const _DifficultyStep({
    required this.selected,
    required this.onSelected,
    required this.onNext,
    required this.onBack,
  });

  final ProblemDifficulty selected;
  final ValueChanged<ProblemDifficulty> onSelected;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Select difficulty',
      subtitle: 'Medium uses larger numbers and tougher calculations.',
      onBack: onBack,
      onNext: onNext,
      nextLabel: 'Continue',
      child: Column(
        children: [
          _SelectableCard(
            selected: selected == ProblemDifficulty.easy,
            color: AppColors.neonGreen,
            title: 'Easy',
            subtitle: 'Fast to solve when you need quick unlocks.',
            leading: const Icon(Icons.flash_on, color: AppColors.neonGreen),
            onTap: () => onSelected(ProblemDifficulty.easy),
          ),
          const SizedBox(height: 10),
          _SelectableCard(
            selected: selected == ProblemDifficulty.medium,
            color: AppColors.neonPink,
            title: 'Medium',
            subtitle: 'Longer focus break with more challenge.',
            leading: const Icon(Icons.bolt, color: AppColors.neonPink),
            onTap: () => onSelected(ProblemDifficulty.medium),
          ),
        ],
      ),
    );
  }
}

class _SignInStep extends StatelessWidget {
  const _SignInStep({
    required this.saving,
    required this.onBack,
    required this.onSignIn,
    required this.onSkip,
  });

  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onSignIn;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton.icon(
            onPressed: saving ? null : onBack,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(
              'Back',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              foregroundColor: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Last step: sign in',
            style: GoogleFonts.spaceMono(
              color: AppColors.offWhite,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Save your settings and stats across devices. You can also continue without an account.',
            style: GoogleFonts.inter(
              color: AppColors.mutedForeground,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: saving ? null : onSignIn,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.neonPink,
              foregroundColor: AppColors.offWhite,
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: const BorderSide(color: AppColors.offWhite, width: 3),
            ),
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.offWhite,
                    ),
                  )
                : Text(
                    'Continue with Google',
                    style: GoogleFonts.spaceMono(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: saving ? null : onSkip,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.mutedForeground,
              side: const BorderSide(color: AppColors.disabled, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Continue without account',
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepFrame extends StatelessWidget {
  const _StepFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onBack,
    required this.onNext,
    this.nextLabel = 'Next',
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(
              'Back',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              foregroundColor: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.spaceMono(
              color: AppColors.offWhite,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: AppColors.mutedForeground,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: child,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.neonPink,
              foregroundColor: AppColors.offWhite,
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: const BorderSide(color: AppColors.offWhite, width: 3),
            ),
            child: Text(
              nextLabel,
              style: GoogleFonts.spaceMono(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
  });

  final bool selected;
  final Color color;
  final String title;
  final String subtitle;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.12) : AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? color : AppColors.disabled,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: selected ? 0.22 : 0.08),
                  border: Border.all(color: color.withValues(alpha: 0.7)),
                ),
                child: Center(child: leading),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceMono(
                        color: selected ? color : AppColors.offWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? color : AppColors.disabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalOption {
  const _GoalOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

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
