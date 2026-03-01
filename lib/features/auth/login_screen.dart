import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_log.dart' as app_log;
import 'auth_state.dart';
import 'auth_service.dart';

/// Maps sign-in exceptions to user-friendly messages and setup hints.
String _userFriendlySignInError(Object e) {
  final s = e.toString().toLowerCase();
  if (s.contains('apiexception') || s.contains(' 10 ') || s.contains('10]')) {
    return 'App not configured for Google Sign-In. In Firebase Console: add your app SHA-1 (Project settings → Android), enable Google sign-in, and use a real google-services.json. See auth_config.dart.';
  }
  if (s.contains('network') || s.contains('connection')) {
    return 'Network error. Check your connection and try again.';
  }
  if (s.contains('sign_in_failed') || s.contains('clientconfiguration')) {
    return 'Google Sign-In not configured. Set AuthConfig.webClientId to your Firebase Web client ID (see auth_config.dart).';
  }
  if (s.contains('firebase') || s.contains('initialize')) {
    return 'Firebase not set up. Replace android/app/google-services.json with your file from Firebase Console.';
  }
  return e.toString();
}

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
      if (user != null) {
        context.go('/');
      } else {
        setState(() {
          _loading = false;
          _error = 'Sign in was cancelled';
        });
      }
    } catch (e, st) {
      if (!mounted) return;
      final message = _userFriendlySignInError(e);
      setState(() {
        _loading = false;
        _error = message;
      });
      debugPrint('Sign-in error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    app_log.log('Login', 'build');
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PRIORITYFLOW',
                style: GoogleFonts.spaceMono(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: AppColors.offWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Block distractions. Prove you need it.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 64),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.destructive, width: 2),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.offWhite,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _signInWithGoogle,
                  icon: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.offWhite,
                          ),
                        )
                      : Icon(
                          Icons.login,
                          color: AppColors.offWhite,
                          size: 24,
                        ),
                  label: Text(
                    _loading ? 'Signing in…' : 'Sign in with Google',
                    style: GoogleFonts.spaceMono(
                      fontSize: 16,
                      color: AppColors.offWhite,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.neonPink,
                    foregroundColor: AppColors.offWhite,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    side: const BorderSide(color: AppColors.offWhite, width: 4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _loading
                    ? null
                    : () async {
                        await ref.read(authSkippedProvider.notifier).setSkipped(true);
                        if (context.mounted) context.go('/');
                      },
                child: Text(
                  'Skip',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.mutedForeground,
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
