import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_log.dart' as app_log;
import '../problems/problem_screen.dart';

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

class _InterventionScreenState extends ConsumerState<InterventionScreen> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.args?.remainingSeconds ?? 0;
    app_log.log('Intervention', 'initState: args=${widget.args != null ? "pkg=${widget.args!.packageName}" : "null"}');
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
    super.dispose();
  }

  String get _timeRemaining {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    final parts = <String>[];
    if (h > 0) parts.add('${h}h');
    parts.add('${m}m');
    parts.add('${s}s');
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    app_log.log('Intervention', 'build: args=${args != null ? "yes" : "null"}');
    if (args == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No unlock data'),
              const SizedBox(height: 16),
              Text('Route may have been opened without extra.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedForeground)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Icon(
                Icons.lock,
                size: 120,
                color: AppColors.neonPink,
              ),
              const SizedBox(height: 32),
              Text(
                args.timesUp ? 'TIMES UP, BUDDY.' : 'NICE TRY.',
                style: GoogleFonts.spaceMono(
                  fontSize: 48,
                  fontWeight: FontWeight.w500,
                  color: AppColors.offWhite,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Time remaining:',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  color: AppColors.offWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _timeRemaining,
                style: GoogleFonts.spaceMono(
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neonCyan,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                args.timesUp
                    ? 'Your grace period is over. Solve another problem to unlock again.'
                    : 'Go do something productive. Read a book. Touch grass. Your choice.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
              ),
              const Spacer(flex: 1),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
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
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.mutedForeground),
                    backgroundColor: AppColors.muted,
                    foregroundColor: AppColors.mutedForeground,
                  ),
                  child: Text(
                    args.timesUp ? 'Solve another problem' : "I'm desperate. Let me do math for access.",
                    style: GoogleFonts.inter(fontSize: 14),
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
