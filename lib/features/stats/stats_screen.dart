import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'stats_state.dart';

// ── design tokens ─────────────────────────────────────────────────────────────
const _black = Color(0xFF000000);
const _card = Color(0xFF1C1C1E);
const _cardAlt = Color(0xFF2C2C2E);
const _green = Color(0xFF30D158);
const _blue = Color(0xFF0A84FF);
const _gradA = Color(0xFFB3FF6E);
const _gradB = Color(0xFF00C9A7);
const _muted = Color(0xFF8E8E93);
const _separator = Color(0xFF38383A);
const _white = Color(0xFFFFFFFF);
const _white60 = Color(0x99FFFFFF);

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);

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
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _white,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Focus Stats',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _white,
              ),
            ),
            centerTitle: true,
          ),

          // ── hero metric ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A2A1A), Color(0xFF0A1A20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_gradA, _gradB],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            color: _black,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Total Challenges Solved',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _white60,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [_gradA, _gradB],
                      ).createShader(bounds),
                      child: Text(
                        '${stats.totalUnlockViaProblem}',
                        style: GoogleFonts.inter(
                          fontSize: 72,
                          fontWeight: FontWeight.w700,
                          color: _white,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'problems solved to unlock apps',
                      style: GoogleFonts.inter(fontSize: 14, color: _muted),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── this week ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'RECENT PROGRESS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Today',
                        value: '${stats.todayCount}',
                        icon: Icons.today_rounded,
                        color: _green,
                      ),
                    ),
                    Container(width: 1, height: 60, color: _separator),
                    Expanded(
                      child: _StatTile(
                        label: 'This Week',
                        value: '${stats.thisWeekCount}',
                        icon: Icons.calendar_today_rounded,
                        color: _blue,
                      ),
                    ),
                    Container(width: 1, height: 60, color: _separator),
                    Expanded(
                      child: _StatTile(
                        label: 'Streak',
                        value: '${stats.currentStreakDays}d',
                        icon: Icons.local_fire_department_rounded,
                        color: const Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(
                'Daily average: ${stats.dailyAverageThisWeek.toStringAsFixed(1)} solves over the last 7 days',
                style: GoogleFonts.inter(fontSize: 13, color: _muted),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // ── streak / insights ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Text(
                'ACHIEVEMENTS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                children: [
                  _AchievementRow(
                    icon: Icons.emoji_events_rounded,
                    color: const Color(0xFFFFD60A),
                    title: 'First solve',
                    subtitle: 'You solved your first problem',
                    unlocked: stats.totalUnlockViaProblem >= 1,
                  ),
                  const SizedBox(height: 10),
                  _AchievementRow(
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF6B35),
                    title: '3-day streak',
                    subtitle: 'Solved at least one challenge for 3 days',
                    unlocked: stats.currentStreakDays >= 3,
                  ),
                  const SizedBox(height: 10),
                  _AchievementRow(
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFFF6B35),
                    title: '10 solves',
                    subtitle: 'Solved 10 problems total',
                    unlocked: stats.totalUnlockViaProblem >= 10,
                  ),
                  const SizedBox(height: 10),
                  _AchievementRow(
                    icon: Icons.diamond_rounded,
                    color: const Color(0xFF7B61FF),
                    title: '50 solves',
                    subtitle: 'Solved 50 problems total',
                    unlocked: stats.totalUnlockViaProblem >= 50,
                  ),
                  const SizedBox(height: 10),
                  _AchievementRow(
                    icon: Icons.military_tech_rounded,
                    color: _gradA,
                    title: 'Century',
                    subtitle: 'Solved 100 problems total',
                    unlocked: stats.totalUnlockViaProblem >= 100,
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: _white,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: _muted)),
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.unlocked,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.35,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: unlocked ? color : _muted, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 13, color: _muted),
                  ),
                ],
              ),
            ),
            Icon(
              unlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
              color: unlocked ? _green : _cardAlt,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
