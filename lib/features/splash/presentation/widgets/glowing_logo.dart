import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GlowingLogo extends StatelessWidget {
  const GlowingLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      height: 145,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withValues(alpha: 0.45),
            blurRadius: 60,
            spreadRadius: 8,
          ),
        ],
      ),
      child: const Icon(
        Icons.eco_rounded,
        color: Colors.white,
        size: 72,
      ),
    )
        .animate()
        .scale(
          duration: 900.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn();
  }
}