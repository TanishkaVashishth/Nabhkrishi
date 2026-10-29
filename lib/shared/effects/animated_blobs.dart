import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBlobs extends StatefulWidget {
  const AnimatedBlobs({super.key});

  @override
  State<AnimatedBlobs> createState() => _AnimatedBlobsState();
}

class _AnimatedBlobsState extends State<AnimatedBlobs>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, _) {
          final t = controller.value;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -120 + sin(t * pi * 2) * 25,
                left: -80,
                child: _blob(
                  340,
                  const Color(0xff5EC8FF).withValues(alpha: .18),
                ),
              ),

              Positioned(
                bottom: -150,
                right: -100 + cos(t * pi * 2) * 35,
                child: _blob(
                  420,
                  const Color(0xff57D36C).withValues(alpha: .18),
                ),
              ),

              Positioned(
                top: 260 + sin(t * pi * 4) * 20,
                right: -90,
                child: _blob(
                  250,
                  Colors.white.withValues(alpha: .08),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            blurRadius: 150,
            spreadRadius: 20,
            color: color,
          ),
        ],
      ),
    );
  }
}