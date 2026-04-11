import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../auth/auth_service.dart';
import '../problems/topic_registry.dart';
import 'settings_state.dart';

// ── design tokens ─────────────────────────────────────────────────────────────
const _black = Color(0xFF000000);
const _card = Color(0xFF1C1C1E);
const _cardAlt = Color(0xFF2C2C2E);
const _green = Color(0xFF30D158);
const _red = Color(0xFFFF3B30);
const _muted = Color(0xFF8E8E93);
const _separator = Color(0xFF38383A);
const _white = Color(0xFFFFFFFF);
const _white60 = Color(0x99FFFFFF);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: _black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _black,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _white, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Settings',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _white,
              ),
            ),
            centerTitle: true,
          ),

          // ── Challenge ─────────────────────────────────────────────────────
          _sectionHeader('CHALLENGE'),
          _sliverCard(children: [
            _SegmentRow(
              label: 'Topic',
              icon: Icons.school_rounded,
              options: TopicRegistry.topicIds,
              labelOf: (id) => TopicRegistry.label(id),
              current: settings.questionTopic,
              onChanged: notifier.setQuestionTopic,
              wrap: true,
            ),
            _divider(),
            _SegmentRow(
              label: 'Difficulty',
              icon: Icons.bolt_rounded,
              options: const ['easy', 'medium'],
              labelOf: (v) => v[0].toUpperCase() + v.substring(1),
              current: settings.problemDifficulty == ProblemDifficulty.easy ? 'easy' : 'medium',
              onChanged: (v) => notifier.setProblemDifficulty(
                v == 'medium' ? ProblemDifficulty.medium : ProblemDifficulty.easy,
              ),
            ),
            _divider(),
            _SegmentRow(
              label: 'Problem type',
              icon: Icons.functions_rounded,
              options: const ['linear', 'integration'],
              labelOf: (v) => v[0].toUpperCase() + v.substring(1),
              current: settings.problemType == ProblemType.linear ? 'linear' : 'integration',
              onChanged: (v) => notifier.setProblemType(
                v == 'integration' ? ProblemType.integration : ProblemType.linear,
              ),
            ),
          ]),

          // ── Timing ───────────────────────────────────────────────────────
          _sectionHeader('TIMING'),
          _sliverCard(children: [
            _StepperRow(
              label: 'Penalty (future)',
              icon: Icons.warning_amber_rounded,
              iconColor: _red,
              value: settings.penaltyMinutes,
              unit: 'min',
              min: 1,
              max: 30,
              onDecrement: () => notifier.setPenaltyMinutes(
                (settings.penaltyMinutes - 1).clamp(1, 30),
              ),
              onIncrement: () => notifier.setPenaltyMinutes(
                (settings.penaltyMinutes + 1).clamp(1, 30),
              ),
            ),
            _divider(),
            _StepperRow(
              label: 'Reward window',
              icon: Icons.timer_rounded,
              iconColor: _green,
              value: settings.rewardDurationMinutes,
              unit: 'min',
              min: 1,
              max: 60,
              onDecrement: () => notifier.setRewardDurationMinutes(
                (settings.rewardDurationMinutes - 1).clamp(1, 60),
              ),
              onIncrement: () => notifier.setRewardDurationMinutes(
                (settings.rewardDurationMinutes + 1).clamp(1, 60),
              ),
            ),
          ]),

          // ── Lock mode ─────────────────────────────────────────────────────
          _sectionHeader('LOCK MODE'),
          _sliverCard(children: [
            _SegmentRow(
              label: 'Mode',
              icon: Icons.lock_rounded,
              options: const ['apps', 'phone'],
              labelOf: (v) => v == 'apps' ? 'Block apps' : 'Lock phone',
              current: settings.lockMode == LockMode.apps ? 'apps' : 'phone',
              onChanged: (v) => notifier.setLockMode(
                v == 'phone' ? LockMode.full : LockMode.apps,
              ),
            ),
          ]),

          // ── Feedback ─────────────────────────────────────────────────────
          _sectionHeader('FEEDBACK'),
          _sliverCard(children: [
            _ToggleRow(
              label: 'Sounds',
              icon: Icons.volume_up_rounded,
              value: settings.enableSounds,
              onChanged: notifier.setEnableSounds,
            ),
            _divider(),
            _ToggleRow(
              label: 'Vibration',
              icon: Icons.vibration_rounded,
              value: settings.enableVibration,
              onChanged: notifier.setEnableVibration,
            ),
            _divider(),
            _ToggleRow(
              label: 'Allow reopen in unlock window',
              icon: Icons.restart_alt_rounded,
              value: settings.allowReopenWithinWindow,
              onChanged: notifier.setAllowReopenWithinWindow,
            ),
          ]),

          // ── Accent color ──────────────────────────────────────────────────
          _sectionHeader('ACCENT COLOR'),
          _sliverCard(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  ...AppColors.accentColors.entries.map((e) {
                    final selected = settings.accentColorKey == e.key;
                    return GestureDetector(
                      onTap: () => notifier.setAccentColorKey(e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 12),
                        width: selected ? 44 : 36,
                        height: selected ? 44 : 36,
                        decoration: BoxDecoration(
                          color: e.value,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? _white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: e.value.withValues(alpha: 0.6), blurRadius: 12)]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded, color: _black, size: 18)
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ]),

          // ── Account ───────────────────────────────────────────────────────
          _sectionHeader('ACCOUNT'),
          _sliverCard(children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                await AuthService.signOut();
                if (context.mounted) context.go('/login');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout_rounded, color: _red, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sign out',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: _red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  static Widget _sectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _muted,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  static Widget _sliverCard({required List<Widget> children}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  static Widget _divider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 60),
      color: _separator,
    );
  }
}

// ── reusable row widgets ──────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _cardAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _white60, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 15, color: _white),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _green,
            activeTrackColor: _green.withValues(alpha: 0.3),
            inactiveThumbColor: _muted,
            inactiveTrackColor: _cardAlt,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final int value;
  final String unit;
  final int min;
  final int max;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 15, color: _white),
            ),
          ),
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: value <= min ? null : onDecrement,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(
              '$value $unit',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: value >= max ? null : onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? _cardAlt : _cardAlt.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? _white : _muted,
          size: 18,
        ),
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({
    required this.label,
    required this.icon,
    required this.options,
    required this.labelOf,
    required this.current,
    required this.onChanged,
    this.wrap = false,
  });

  final String label;
  final IconData icon;
  final List<String> options;
  final String Function(String) labelOf;
  final String current;
  final ValueChanged<String> onChanged;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final chips = options.map((o) {
      final selected = current == o;
      return GestureDetector(
        onTap: () => onChanged(o),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? _white : _cardAlt,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            labelOf(o),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? _black : _muted,
            ),
          ),
        ),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _cardAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _white60, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 15, color: _white),
                ),
                const SizedBox(height: 10),
                wrap
                    ? Wrap(spacing: 8, runSpacing: 8, children: chips)
                    : Row(children: [
                        for (int i = 0; i < chips.length; i++) ...[
                          chips[i],
                          if (i < chips.length - 1) const SizedBox(width: 8),
                        ]
                      ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
