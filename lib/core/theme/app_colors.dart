import 'package:flutter/material.dart';

/// Centralized color tokens for NabhKrishi.
/// Blends NabhKrishi's signature Sky-meets-Earth identity with
/// the fresh, high-contrast, farmer-friendly reference design system.
class AppColors {
  AppColors._();

  // Reference Brand Background & Surface (Clean, Airy, High-Contrast)
  static const Color background = Color(0xFFF8F9F3);
  static const Color surface = Colors.white;
  static const Color surfaceSoft = Color(0xFFF3F4EC);
  static const Color surfaceMuted = Color(0xFFE2E3DB);

  // Forest Greens
  static const Color primary = Color(0xFF0F5238);
  static const Color primaryMedium = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF116C4A);
  static const Color primaryDark = Color(0xFF0A3D2A);

  // Mints & Accents
  static const Color mintBg = Color(0xFFE6F4EA);
  static const Color mintAccent = Color(0xFFA1F4C8);
  static const Color mintHighlight = Color(0xFFA8E7C5);
  static const Color mintBorder = Color(0xFFA8E7C5);

  // Crimson / Danger / Disease Alert
  static const Color danger = Color(0xFFBA1A1A);
  static const Color dangerDark = Color(0xFF93000A);
  static const Color dangerLight = Color(0xFFFFDAD6);

  // Amber / Warning / Moderate Risk
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFF4E5);

  // Sky / Weather / Telemetry
  static const Color weatherBlue = Color(0xFF0288D1);
  static const Color weatherDarkBlue = Color(0xFF01579B);
  static const Color weatherLightBlue = Color(0xFFE1F5FE);
  static const Color weatherBorderBlue = Color(0xFFB3E5FC);

  // Typography & Borders
  static const Color textPrimary = Color(0xFF1A1C18);
  static const Color textSecondary = Color(0xFF404943);
  static const Color textMuted = Color(0xFF707973);
  static const Color textTertiary = Color(0xFF8A938C);
  static const Color accent = Color(0xFF2D6A4F);
  static const Color border = Color(0xFFBFC9C1);
  static const Color borderLight = Color(0x66BFC9C1);

  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  // Backward Compatible Legacy Brand Tokens
  static const Color skyBlueDark = Color(0xFF0D47A1);
  static const Color skyBlueLight = Color(0xFF4FC3F7);
  static const Color earthGreenLight = Color(0xFF66BB6A);
  static const Color earthGreenDark = Color(0xFF1B5E20);
  static const Color amberAccent = Color(0xFFFFB300);
  static const Color ivory = Color(0xFFFDFBF6);
  static const Color charcoal = Color(0xFF212121);
  static const Color success = Color(0xFF43A047);
  static const Color error = Color(0xFFD32F2F);

  /// Signature splash gradient: sky at the top, earth at the bottom.
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      skyBlueDark,
      skyBlueLight,
      earthGreenLight,
      earthGreenDark,
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );
}

