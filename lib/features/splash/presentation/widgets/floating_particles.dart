import 'dart:math';

import 'package:flutter/material.dart';

class FloatingParticles extends StatefulWidget {
  const FloatingParticles({super.key});

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  final random = Random(7);

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, _) {
          return CustomPaint(
            painter: _ParticlePainter(controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;

  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (int i = 0; i < 35; i++) {
      final x =
          (size.width / 35) * i + sin((t + i) * 5) * 12;

      final y =
          ((size.height + 120) * ((t + i / 35) % 1)) - 80;

      paint.color = Colors.white.withValues(alpha: 0.12);

      canvas.drawCircle(
        Offset(x, size.height - y),
        2 + (i % 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}