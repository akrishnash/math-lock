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
      body: Stack(
        children: [
          // Decorative neon accent lines
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 3, color: AppColors.neonPink),
          ),
          Positioned(
            top: 3,
            left: 0,
            right: 0,
            child: Container(height: 1, color: AppColors.neonCyan.withValues(alpha: 0.4)),
          ),
          SafeArea(
            child: Column(
              children: [
                // Hero section
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Brand mark
                        const _BrandMark(),
                        const SizedBox(height: 32),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 1,
                              color: AppColors.neonPink.withValues(alpha: 0.6),
                            ),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Block distractions. Prove you need it.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 1,
                              color: AppColors.neonPink.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // Feature pills
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: const [
                            _FeaturePill(icon: Icons.lock_outline, label: 'App Blocking'),
                            _FeaturePill(icon: Icons.calculate_outlined, label: 'Math Unlock'),
                            _FeaturePill(icon: Icons.timer_outlined, label: 'Focus Timer'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Auth section
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        top: BorderSide(color: AppColors.offWhite, width: 4),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'GET STARTED',
                          style: GoogleFonts.spaceMono(
                            fontSize: 13,
                            letterSpacing: 2.5,
                            color: AppColors.neonPink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sign in to sync your stats and settings across devices.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.destructive.withValues(alpha: 0.15),
                              border: Border.all(color: AppColors.destructive, width: 2),
                            ),
                            child: Text(
                              _error!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.offWhite,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
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
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.offWhite,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const _GoogleIcon(),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 15,
                                        color: AppColors.offWhite,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.disabled, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.disabled,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.disabled, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () async {
                                  await ref.read(authSkippedProvider.notifier).setSkipped(true);
                                  if (context.mounted) context.go('/');
                                },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: AppColors.disabled, width: 1),
                          ),
                          child: Text(
                            'Continue without account',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
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

/// Hero brand mark for the login screen.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icon cluster: lock + math glyph
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.neonPink.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            // Middle ring
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.neonPink, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonPink.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Lock icon
            const Icon(Icons.lock_outline_rounded, color: AppColors.neonPink, size: 36),
            // Math symbol top-right
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.neonCyan, width: 1.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '∫',
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      color: AppColors.neonCyan,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            // Checkmark bottom-right
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.neonGreen, width: 1.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.neonGreen, size: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        // App name
        Text(
          'EARN YOUR SCREEN',
          style: GoogleFonts.spaceMono(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.offWhite,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        // Neon underline
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 32, height: 2, color: AppColors.neonCyan),
            const SizedBox(width: 6),
            Container(width: 8, height: 2, color: AppColors.neonPink),
          ],
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.disabled, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.neonCyan, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Painted Google "G" logo using canvas.
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    final sweeps = [
      const Offset(0, 90),
      const Offset(90, 90),
      const Offset(180, 90),
      const Offset(270, 90),
    ];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r - 1.75),
        sweeps[i].dx * 3.14159 / 180,
        sweeps[i].dy * 3.14159 / 180,
        false,
        paint,
      );
    }

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(Offset(cx, cy), Offset(cx + r - 1.75, cy), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
