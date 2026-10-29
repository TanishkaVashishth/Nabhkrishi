import 'package:flutter/material.dart';

class NoiseOverlay extends StatelessWidget {
  const NoiseOverlay({super.key});

  @override
  Widget build(BuildContext context) {

    return IgnorePointer(
      child: Opacity(
        opacity: .03,
        child: Image.network(
          "https://grainy-gradients.vercel.app/noise.svg",
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}