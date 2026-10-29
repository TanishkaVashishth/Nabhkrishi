import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Type scale used across NabhKrishi. Kept deliberately small (5 styles)
/// so every screen reuses the same hierarchy instead of inventing new sizes.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.ivory,
    letterSpacing: 0.2,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.charcoal,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.charcoal,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
  );
}
