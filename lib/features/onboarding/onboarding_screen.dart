import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/theme/app_colors.dart';
import '../settings/settings_state.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String _selectedTopic = 'mixed';
  ProblemDifficulty _selectedDifficulty = ProblemDifficulty.easy;
  bool _saving = false;

  static const _topics = [
    _TopicOption(
      id: 'mixed',
      icon: Icons.shuffle_rounded,
      label: 'Mixed',
      subtitle: 'A bit of everything',
      example: '3x + 4 = 10  •  ∫ 2x dx  •  Capitals',
      color: AppColors.neonPink,
    ),
    _TopicOption(
      id: 'arithmetic',
      icon: Icons.calculate_outlined,
      label: 'Arithmetic',
      subtitle: 'Linear equations, solve for x',
      example: '5x − 3 = 12  →  x = ?',
      color: AppColors.neonCyan,
    ),
    _TopicOption(
      id: 'algebra',
      icon: Icons.functions_outlined,
      label: 'Algebra',
      subtitle: 'Variables and expressions',
      example: '7x + 6 = 48  →  x = ?',
      color: AppColors.neonPurple,
    ),
    _TopicOption(
      id: 'integration',
      icon: Icons.area_chart_outlined,
      label: 'Integration',
      subtitle: 'Definite integrals',
      example: '∫ 3x² dx  [0, 2]  →  ?',
      color: AppColors.neonYellow,
    ),
    _TopicOption(
      id: 'geography',
      icon: Icons.public_outlined,
      label: 'Geography',
      subtitle: 'World capitals quiz',
      example: 'Capital of Japan?  →  Tokyo',
      color: AppColors.neonGreen,
    ),
  ];

  Future<void> _finish() async {
    setState(() => _saving = true);
    await ref.read(settingsProvider.notifier).setQuestionTopic(_selectedTopic);
    await ref.read(settingsProvider.notifier).setProblemDifficulty(_selectedDifficulty);
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
          Positioned(top: 0, left: 0, right: 0, child: Container(height: 3, color: AppColors.neonPink)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PERSONALISE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          letterSpacing: 3,
                          color: AppColors.neonPink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'What should we\nchallenge you with?',
                        style: GoogleFonts.spaceMono(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.offWhite,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pick a topic. You can change this anytime in settings.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Topic cards
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _topics.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final topic = _topics[i];
                      final selected = _selectedTopic == topic.id;
                      return _TopicCard(
                        topic: topic,
                        selected: selected,
                        onTap: () => setState(() => _selectedTopic = topic.id),
                      );
                    },
                  ),
                ),

                // Difficulty + CTA
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.offWhite, width: 4)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'DIFFICULTY',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          letterSpacing: 3,
                          color: AppColors.mutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _DiffChip(
                            label: 'EASY',
                            subtitle: 'Simpler numbers',
                            selected: _selectedDifficulty == ProblemDifficulty.easy,
                            color: AppColors.neonGreen,
                            onTap: () => setState(() => _selectedDifficulty = ProblemDifficulty.easy),
                          ),
                          const SizedBox(width: 10),
                          _DiffChip(
                            label: 'MEDIUM',
                            subtitle: 'Bigger numbers',
                            selected: _selectedDifficulty == ProblemDifficulty.medium,
                            color: AppColors.neonPink,
                            onTap: () => setState(() => _selectedDifficulty = ProblemDifficulty.medium),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _saving ? null : _finish,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.neonPink,
                          foregroundColor: AppColors.offWhite,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          side: const BorderSide(color: AppColors.offWhite, width: 3),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.offWhite),
                              )
                            : Text(
                                "LET'S GO →",
                                style: GoogleFonts.spaceMono(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicOption {
  const _TopicOption({
    required this.id,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.example,
    required this.color,
  });

  final String id;
  final IconData icon;
  final String label;
  final String subtitle;
  final String example;
  final Color color;
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.selected,
    required this.onTap,
  });

  final _TopicOption topic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? topic.color.withValues(alpha: 0.08) : AppColors.surface,
          border: Border.all(
            color: selected ? topic.color : AppColors.disabled,
            width: selected ? 3 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: topic.color.withValues(alpha: selected ? 0.2 : 0.08),
                border: Border.all(
                  color: selected ? topic.color : AppColors.disabled,
                  width: 1.5,
                ),
              ),
              child: Icon(topic.icon, color: topic.color, size: 24),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.label,
                    style: GoogleFonts.spaceMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? topic.color : AppColors.offWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topic.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topic.example,
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      color: selected ? topic.color.withValues(alpha: 0.8) : AppColors.disabled,
                    ),
                  ),
                ],
              ),
            ),
            // Radio dot
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? topic.color : AppColors.disabled,
                  width: 2,
                ),
                color: selected ? topic.color : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, color: AppColors.background, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffChip extends StatelessWidget {
  const _DiffChip({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : AppColors.background,
            border: Border.all(
              color: selected ? color : AppColors.disabled,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.disabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
