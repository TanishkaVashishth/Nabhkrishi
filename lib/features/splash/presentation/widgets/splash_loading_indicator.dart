import 'package:flutter/material.dart';

/// Thin, understated progress indicator — deliberately not a big spinner.
/// Apple/Google splash conventions favor something quiet at the bottom
/// over anything that competes visually with the logo.
class SplashLoadingIndicator extends StatelessWidget {
  const SplashLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
      ),
    );
  }
}
