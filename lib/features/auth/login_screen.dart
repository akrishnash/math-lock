import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await AuthService.signInWithGoogle();
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'Sign in was cancelled.';
        });
        return;
      }
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _userFriendlySignInError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome back',
                style: GoogleFonts.spaceMono(
                  color: AppColors.offWhite,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue your focus sessions and synced stats.',
                style: GoogleFonts.inter(
                  color: AppColors.mutedForeground,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.offWhite, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.neonPink.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.neonPink, width: 1.5),
                      ),
                      child: const Icon(Icons.lock_clock_outlined, color: AppColors.neonPink),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your onboarding setup is complete. This screen is only for returning users.',
                        style: GoogleFonts.inter(
                          color: AppColors.mutedForeground,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.destructive, width: 1.5),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(color: AppColors.offWhite, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _loading ? null : _signInWithGoogle,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.neonPink,
                  foregroundColor: AppColors.offWhite,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: AppColors.offWhite, width: 3),
                ),
                child: _loading
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
            ],
          ),
        ),
      ),
    );
  }
}

String _userFriendlySignInError(Object e) {
  final s = e.toString().toLowerCase();
  if (s.contains('apiexception') || s.contains(' 10 ') || s.contains('10]')) {
    return 'Google Sign-In is not configured for this build yet.';
  }
  if (s.contains('network') || s.contains('connection')) {
    return 'Network error. Check your connection and try again.';
  }
  if (s.contains('firebase') || s.contains('initialize')) {
    return 'Firebase setup is incomplete for this app build.';
  }
  return 'Unable to sign in right now. Please try again.';
}
