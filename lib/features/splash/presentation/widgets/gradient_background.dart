import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Reusable full-bleed gradient backdrop. Pulled out as its own widget
/// (rather than inlined in SplashPage) so it can be reused behind other
/// full-screen moments — e.g. a "success" screen after onboarding.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final Gradient gradient;

  const GradientBackground({
    super.key,
    required this.child,
    this.gradient = AppColors.splashGradient,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}
