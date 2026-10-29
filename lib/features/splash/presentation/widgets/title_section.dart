import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TitleSection extends StatelessWidget {
  const TitleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "NabhKrishi",
          style: GoogleFonts.poppins(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -.8,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          "Sky to Soil Intelligence",
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    )
        .animate(delay: 700.ms)
        .fadeIn(duration: 700.ms)
        .moveY(begin: 40, end: 0);
  }
}