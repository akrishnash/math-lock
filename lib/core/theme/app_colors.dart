import 'package:flutter/material.dart';

/// Math-Lock / Zen mod design system colors (Figma palette).
abstract final class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF16161D);
  static const Color offWhite = Color(0xFFF0F0F0);
  static const Color neonPink = Color(0xFFFF006E);
  static const Color neonCyan = Color(0xFF00F5FF);
  static const Color neonPurple = Color(0xFFB537FF);
  static const Color neonYellow = Color(0xFFFFD60A);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color destructive = Color(0xFFff1744);
  static const Color muted = Color(0xFF1f1f2a);
  static const Color mutedForeground = Color(0xFFa0a0b0);
  static const Color switchBg = Color(0xFF2a2a3a);
  static const Color disabled = Color(0xFF505050);

  static const Map<String, Color> accentColors = {
    'pink': neonPink,
    'cyan': neonCyan,
    'purple': neonPurple,
    'yellow': neonYellow,
    'green': neonGreen,
  };
}
