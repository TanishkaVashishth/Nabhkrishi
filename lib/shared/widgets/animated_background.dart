import 'dart:ui';

import 'package:flutter/material.dart';

class AnimatedBackground extends StatelessWidget {
  final Widget child;

  const AnimatedBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff061B46),
                Color(0xff0E4A74),
                Color(0xff1D8E63),
                Color(0xff0A5B37),
              ],
            ),
          ),
        ),

        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 40,
            sigmaY: 40,
          ),
          child: Container(
            color: Colors.transparent,
          ),
        ),

        child,
      ],
    );
  }
}