import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../auth/auth_service.dart';
import '../settings/settings_state.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

const _bgColors = [Color(0xFF090F1A), Color(0xFF0B1C26), Color(0xFF0C1F1A)];
const _bgStops = [0.0, 0.45, 1.0];

const _white = Colors.white;
const _white70 = Color(0xB3FFFFFF);
const _white40 = Color(0x66FFFFFF);
const _white15 = Color(0x26FFFFFF);
const _white10 = Color(0x1AFFFFFF);
const _white08 = Color(0x14FFFFFF);

// ─────────────────────────────────────────────────────────────────────────────

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

  // 6 pages: 0=welcome, 1=goal, 2=topic, 3=difficulty, 4=loading, 5=sign-in
  static const _totalPages = 6;

  static const _goals = <_GoalOption>[
    _GoalOption(
      id: 'focus',
      title: 'Stay Focused',
      subtitle: 'Block distractions\nwhile you work',
      icon: Icons.center_focus_strong_rounded,
    ),
    _GoalOption(
      id: 'discipline',
      title: 'Build Discipline',
      subtitle: 'Add friction before\nsocial apps',
      icon: Icons.fitness_center_rounded,
    ),
    _GoalOption(
      id: 'screen-time',
      title: 'Less Screen Time',
      subtitle: 'Unlock windows keep\nusage low',
      icon: Icons.hourglass_top_rounded,
    ),
    _GoalOption(
      id: 'mindful',
      title: 'Be Mindful',
      subtitle: 'Pause and reflect\nbefore opening apps',
      icon: Icons.self_improvement_rounded,
    ),
  ];

  static const _topics = <_TopicOption>[
    _TopicOption(id: 'mixed', icon: Icons.shuffle_rounded, label: 'Mixed', subtitle: 'A bit of everything'),
    _TopicOption(id: 'arithmetic', icon: Icons.calculate_outlined, label: 'Arithmetic', subtitle: 'Quick mental math'),
    _TopicOption(id: 'algebra', icon: Icons.functions_outlined, label: 'Algebra', subtitle: 'Variables & expressions'),
    _TopicOption(id: 'integration', icon: Icons.area_chart_outlined, label: 'Calculus', subtitle: 'Integral practice'),
    _TopicOption(id: 'geography', icon: Icons.public_outlined, label: 'Geography', subtitle: 'World capitals'),
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
    if (_page >= _totalPages - 1) return;
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _back() async {
    if (_page <= 0) return;
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 260),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF2A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _bgColors,
            stops: _bgStops,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (_page >= 1 && _page <= 3) ...[
                const SizedBox(height: 16),
                _DotsProgress(current: _page - 1, total: 3),
              ] else
                const SizedBox(height: 0),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (v) => setState(() => _page = v),
                  children: [
                    // 0 – Welcome
                    _WelcomeStep(onStart: _next),
                    // 1 – Goal
                    _GoalStep(
                      options: _goals,
                      selected: _goal,
                      onSelected: (id) => setState(() => _goal = id),
                      onNext: _next,
                      onBack: _back,
                    ),
                    // 2 – Topic
                    _TopicStep(
                      options: _topics,
                      selected: _selectedTopic,
                      onSelected: (id) => setState(() => _selectedTopic = id),
                      onNext: _next,
                      onBack: _back,
                    ),
                    // 3 – Difficulty
                    _DifficultyStep(
                      selected: _selectedDifficulty,
                      onSelected: (d) => setState(() => _selectedDifficulty = d),
                      onNext: _next,
                      onBack: _back,
                    ),
                    // 4 – Customizing (loading)
                    _LoadingStep(onDone: _next),
                    // 5 – Sign-in
                    _SignInStep(
                      saving: _saving,
                      onSignIn: _signInAndFinish,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Progress dots ─────────────────────────────────────────────────────────────

class _DotsProgress extends StatelessWidget {
  const _DotsProgress({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? _white : _white40,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

// ── Shared pill button ────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _white,
          foregroundColor: const Color(0xFF0B1827),
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF0B1827),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

// ── Frosted glass card ────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.selected = false,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? _white15 : _white08,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _white70 : _white15,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ── 0 · Welcome ───────────────────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 3),
          // Lock icon
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _white10,
                shape: BoxShape.circle,
                border: Border.all(color: _white40, width: 1.5),
              ),
              child: const Icon(Icons.lock_outline_rounded, color: _white, size: 40),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Earn Your Screen',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _white,
              fontSize: 36,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Solve a math problem to unlock\nyour apps. Build focus. Earn your screen time.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _white70,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const Spacer(flex: 4),
          _PillButton(label: 'Get Started', onPressed: onStart),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Takes less than a minute',
              style: GoogleFonts.inter(color: _white40, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 1 · Goal ──────────────────────────────────────────────────────────────────

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BackLink(onTap: onBack),
          const SizedBox(height: 20),
          Text(
            'What is your\nprimary goal?',
            style: GoogleFonts.inter(
              color: _white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick the one that fits best.',
            style: GoogleFonts.inter(color: _white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _GoalGrid(
              options: options,
              selected: selected,
              onSelected: onSelected,
            ),
          ),
          const SizedBox(height: 16),
          _PillButton(
            label: 'Next',
            onPressed: selected.isNotEmpty ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _GoalGrid extends StatelessWidget {
  const _GoalGrid({
    required this.options,
    required this.selected,
    required this.onSelected,
  });
  final List<_GoalOption> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    // 2×2 grid
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += 2) {
      rows.add(
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _GoalCard(
                  option: options[i],
                  selected: selected == options[i].id,
                  onTap: () => onSelected(options[i].id),
                ),
              ),
              const SizedBox(width: 12),
              if (i + 1 < options.length)
                Expanded(
                  child: _GoalCard(
                    option: options[i + 1],
                    selected: selected == options[i + 1].id,
                    onTap: () => onSelected(options[i + 1].id),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
      if (i + 2 < options.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final _GoalOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(option.icon, color: selected ? _white : _white70, size: 28),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.title,
                style: GoogleFonts.inter(
                  color: _white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                option.subtitle,
                style: GoogleFonts.inter(color: _white70, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 2 · Topic ─────────────────────────────────────────────────────────────────

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BackLink(onTap: onBack),
          const SizedBox(height: 20),
          Text(
            'Choose your\nchallenge topic',
            style: GoogleFonts.inter(
              color: _white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You can change this anytime in settings.',
            style: GoogleFonts.inter(color: _white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.55,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: options.map((topic) {
                final sel = selected == topic.id;
                return _GlassCard(
                  selected: sel,
                  onTap: () => onSelected(topic.id),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(topic.icon, color: sel ? _white : _white70, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              topic.label,
                              style: GoogleFonts.inter(
                                color: _white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              topic.subtitle,
                              style: GoogleFonts.inter(
                                color: _white70,
                                fontSize: 10,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _PillButton(
            label: 'Next',
            onPressed: selected.isNotEmpty ? onNext : null,
          ),
        ],
      ),
    );
  }
}

// ── 3 · Difficulty ────────────────────────────────────────────────────────────

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BackLink(onTap: onBack),
          const SizedBox(height: 20),
          Text(
            'How tough\nshould the lock be?',
            style: GoogleFonts.inter(
              color: _white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Medium problems take longer — adding real friction.',
            style: GoogleFonts.inter(color: _white70, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _DifficultyCard(
                    title: 'Easy',
                    subtitle: 'Quick calculations. Perfect for light friction during the day.',
                    icon: Icons.flash_on_rounded,
                    selected: selected == ProblemDifficulty.easy,
                    onTap: () => onSelected(ProblemDifficulty.easy),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _DifficultyCard(
                    title: 'Medium',
                    subtitle: 'Longer problems that require focus. A real pause before unlocking.',
                    icon: Icons.bolt_rounded,
                    selected: selected == ProblemDifficulty.medium,
                    onTap: () => onSelected(ProblemDifficulty.medium),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _PillButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: selected ? _white15 : _white08,
              shape: BoxShape.circle,
              border: Border.all(color: selected ? _white70 : _white40, width: 1),
            ),
            child: Icon(icon, color: _white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: _white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: _white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? _white : Colors.transparent,
              border: Border.all(color: selected ? _white : _white40, width: 1.5),
            ),
            child: selected
                ? const Icon(Icons.check, size: 14, color: Color(0xFF0B1827))
                : null,
          ),
        ],
      ),
    );
  }
}

// ── 4 · Loading ───────────────────────────────────────────────────────────────

class _LoadingStep extends StatefulWidget {
  const _LoadingStep({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_LoadingStep> createState() => _LoadingStepState();
}

class _LoadingStepState extends State<_LoadingStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  int _msgIndex = 0;

  static const _messages = [
    'Customizing your lock...',
    'Setting up challenges...',
    'Finalizing your profile...',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    // Cycle through messages
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _msgIndex = 1);
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _msgIndex = 2);
    });
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _white40, width: 1.5),
                color: _white08,
              ),
              child: const Icon(Icons.lock_outline_rounded, color: _white, size: 44),
            ),
          ),
          const SizedBox(height: 48),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              _messages[_msgIndex],
              key: ValueKey(_msgIndex),
              style: GoogleFonts.inter(
                color: _white70,
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5 · Sign-in ───────────────────────────────────────────────────────────────

class _SignInStep extends StatelessWidget {
  const _SignInStep({
    required this.saving,
    required this.onSignIn,
  });
  final bool saving;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _white10,
                shape: BoxShape.circle,
                border: Border.all(color: _white40, width: 1.5),
              ),
              child: const Icon(Icons.person_outline_rounded, color: _white, size: 32),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'One last step',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sign in to save your progress and sync settings across devices.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: _white70, fontSize: 14, height: 1.6),
          ),
          const Spacer(flex: 3),
          _PillButton(
            label: 'Continue with Google',
            onPressed: saving ? null : onSignIn,
            loading: saving,
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Free to use · No spam · Secure sign-in',
              style: GoogleFonts.inter(color: _white40, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Back link ─────────────────────────────────────────────────────────────────

class _BackLink extends StatelessWidget {
  const _BackLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back_ios_new_rounded, color: _white70, size: 14),
            const SizedBox(width: 4),
            Text(
              'Back',
              style: GoogleFonts.inter(color: _white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error helper ──────────────────────────────────────────────────────────────

String _userFriendlySignInError(Object e) {
  final s = e.toString().toLowerCase();
  if (s.contains('apiexception') || s.contains(' 10 ') || s.contains('10]')) {
    return 'Google Sign-In is not configured for this build.';
  }
  if (s.contains('network') || s.contains('connection')) {
    return 'Network error. Check your connection and try again.';
  }
  if (s.contains('firebase') || s.contains('initialize')) {
    return 'Firebase setup is incomplete for this build.';
  }
  return 'Unable to sign in right now. Please try again.';
}

// ── Data models ───────────────────────────────────────────────────────────────

class _GoalOption {
  const _GoalOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _TopicOption {
  const _TopicOption({
    required this.id,
    required this.icon,
    required this.label,
    required this.subtitle,
  });
  final String id;
  final IconData icon;
  final String label;
  final String subtitle;
}
