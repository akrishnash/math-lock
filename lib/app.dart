import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_router.dart';
import 'core/theme/app_colors.dart';

class MathLockApp extends ConsumerWidget {
  const MathLockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Earn Your Screen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.neonPink,
          onPrimary: AppColors.offWhite,
          primaryContainer: AppColors.surface,
          onPrimaryContainer: AppColors.offWhite,
          secondary: AppColors.neonCyan,
          onSecondary: AppColors.background,
          surface: AppColors.surface,
          onSurface: AppColors.offWhite,
          surfaceContainerHighest: AppColors.muted,
          onSurfaceVariant: AppColors.mutedForeground,
          error: AppColors.destructive,
          onError: AppColors.offWhite,
          outline: AppColors.offWhite,
          shadow: Colors.black54,
          inverseSurface: AppColors.offWhite,
          onInverseSurface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: const BorderSide(color: AppColors.offWhite, width: 4),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.offWhite,
          elevation: 0,
          titleTextStyle: GoogleFonts.spaceMono(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.offWhite,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.neonPink,
            foregroundColor: AppColors.offWhite,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: const BorderSide(color: AppColors.offWhite, width: 4),
            ),
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: GoogleFonts.spaceMono(
            fontSize: 32,
            fontWeight: FontWeight.w500,
            color: AppColors.offWhite,
          ),
          headlineMedium: GoogleFonts.spaceMono(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: AppColors.offWhite,
          ),
          titleLarge: GoogleFonts.spaceMono(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.offWhite,
          ),
          titleMedium: GoogleFonts.spaceMono(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.offWhite,
          ),
          titleSmall: GoogleFonts.spaceMono(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.offWhite,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.offWhite,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.offWhite,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
          labelLarge: GoogleFonts.spaceMono(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.offWhite,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.neonCyan;
            }
            return AppColors.surface;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.neonCyan.withValues(alpha: 0.5);
            }
            return AppColors.switchBg;
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.offWhite, width: 4),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.offWhite, width: 4),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.neonPink, width: 4),
          ),
        ),
      ),
      themeMode: ThemeMode.dark,
      routerConfig: createRouter(ref),
    );
  }
}
