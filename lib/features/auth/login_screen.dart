import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_service.dart';

const _bgColors = [Color(0xFF090F1A), Color(0xFF0B1C26), Color(0xFF0C1F1A)];
const _bgStops = [0.0, 0.45, 1.0];
const _white = Colors.white;
const _white70 = Color(0xB3FFFFFF);
const _white40 = Color(0x66FFFFFF);
const _white10 = Color(0x1AFFFFFF);

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
          child: Padding(
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
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: _white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign in to continue your focus sessions and sync your stats.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const Spacer(flex: 3),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x22FF4444),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x66FF4444), width: 1),
                    ),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: _white70, fontSize: 13),
                    ),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _white,
                      foregroundColor: const Color(0xFF0B1827),
                      elevation: 0,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF0B1827),
                            ),
                          )
                        : Text(
                            'Continue with Google',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'New here? Download and open the app to get started.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: _white40, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
