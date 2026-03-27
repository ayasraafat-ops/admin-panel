import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF06060F);
  static const Color backgroundLight = Color(0xFF1A1A3E);
  static const Color cardBg = Color(0x0AFFFFFF);
  static const Color cardBorder = Color(0x14FFFFFF);
  static const Color pink = Color(0xFFF093FB);
  static const Color red = Color(0xFFF5576C);
  static const Color blue = Color(0xFF667EEA);
  static const Color green = Color(0xFF68D391);
  static const Color purple = Color(0xFF764BA2);
  static const Color orange = Color(0xFFF6AD55);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0x59FFFFFF);
  static const Color textMuted = Color(0x4DFFFFFF);
  static const Color errorRed = Color(0xFFFC8181);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, red],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [background, backgroundLight],
  );

  static const LinearGradient barGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [blue, purple],
  );
}