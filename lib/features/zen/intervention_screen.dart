import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/app_log.dart' as app_log;
import '../problems/problem_screen.dart';

// ── design tokens ─────────────────────────────────────────────────────────────
const _black = Color(0xFF000000);
const _card = Color(0xFF1C1C1E);
const _red = Color(0xFFFF3B30);
const _gradA = Color(0xFFB3FF6E);
const _gradB = Color(0xFF00C9A7);
const _muted = Color(0xFF8E8E93);
const _white = Color(0xFFFFFFFF);

class InterventionScreenArgs {
  const InterventionScreenArgs({
    required this.packageName,
    required this.appLabel,
    required this.remainingSeconds,
    required this.rewardMinutes,
    this.timesUp = false,
  });

  final String packageName;
  final String appLabel;
  final int remainingSeconds;
  final int rewardMinutes;
  final bool timesUp;
}

class InterventionScreen extends ConsumerStatefulWidget {
  const InterventionScreen({super.key, this.args});

  final InterventionScreenArgs? args;

  @override
  ConsumerState<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends ConsumerState<InterventionScreen>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.args?.remainingSeconds ?? 0;
    app_log.log('Intervention', 'initState: args=${widget.args != null ? "pkg=${widget.args!.packageName}" : "null"}');

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) _remainingSeconds--;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _timeRemaining {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    app_log.log('Intervention', 'build: args=${args != null ? "yes" : "null"}');

    if (args == null) {
      return Scaffold(
        backgroundColor: _black,
        body: Center(
          child: Text(
            'No unlock data',
            style: GoogleFonts.inter(color: _muted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── lock icon with glow ──────────────────────────────────────
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 0.92 + 0.08 * _pulseController.value;
                final glowRadius = 40.0 + 20.0 * _pulseController.value;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _card,
                      boxShadow: [
                        BoxShadow(
                          color: _red.withValues(alpha: 0.3 + 0.2 * _pulseController.value),
                          blurRadius: glowRadius,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_rounded, color: _red, size: 52),
                  ),
                );
              },
            ),

            const SizedBox(height: 36),

            // ── headline ─────────────────────────────────────────────────
            Text(
              args.timesUp ? 'Time\'s Up.' : 'Nice Try.',
              style: GoogleFonts.inter(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: _white,
                height: 1.1,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              args.timesUp
                  ? 'Your grace period is over.'
                  : '${args.appLabel} is locked.',
              style: GoogleFonts.inter(fontSize: 17, color: _muted),
            ),

            const SizedBox(height: 40),

            // ── countdown ────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    'SESSION REMAINING',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _muted,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _timeRemaining,
                    style: GoogleFonts.inter(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: _white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    args.timesUp
                        ? 'Solve a problem to earn more time'
                        : 'Hang tight — do something productive',
                    style: GoogleFonts.inter(fontSize: 13, color: _muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // ── CTA ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: GestureDetector(
                onTap: () {
                  app_log.log('Intervention', 'navigating to /challenge');
                  context.go(
                    '/challenge',
                    extra: ProblemScreenArgs(
                      packageName: args.packageName,
                      appLabel: args.appLabel,
                      rewardMinutes: args.rewardMinutes,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_gradA, _gradB]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      args.timesUp
                          ? 'Solve Another Problem'
                          : 'Solve a Problem for Access',
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
          ],
        ),
      ),
    );
  }
}
