import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2350),
    )..forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _goToLanguage();
      }
    });
  }

  void _goToLanguage() {
    ref.read(isSplashFinishedProvider.notifier).state = true;
  }

  double _interval(
    double begin,
    double end, {
    Curve curve = Curves.easeOutCubic,
  }) {
    final value = CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: curve),
    ).value;

    return value.clamp(0.0, 1.0).toDouble();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF041525),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;

          final glow = _interval(
            0.0,
            0.72,
            curve: Curves.easeInOut,
          ).clamp(0.0, 1.0);

          final leaf = _interval(0.18, 0.58, curve: Curves.easeOutBack);

          final name = _interval(0.43, 0.68);

          final tagline = _interval(0.58, 0.78);

          return Stack(
            fit: StackFit.expand,
            children: [
              // ==========================================================
              // BACKGROUND
              // ==========================================================
              const _NabhBackground(),

              // ==========================================================
              // SUBTLE FIELD LIGHT
              // ==========================================================
              CustomPaint(painter: _LightTrailsPainter(progress: t)),

              // ==========================================================
              // LITTLE PARTICLES + TORCHLIGHT
              // ==========================================================
              IgnorePointer(
                child: CustomPaint(painter: _LogoParticlesPainter(progress: t)),
              ),

              // ==========================================================
              // CENTRAL GLOW
              // ==========================================================
              IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: ((glow * 0.8).clamp(0.0, 1.0)).toDouble(),
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF65E8C0,
                            ).withValues(alpha: 0.13),
                            blurRadius: 100,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ==========================================================
              // BRAND
              // ==========================================================
              Center(
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - leaf)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --------------------------------------------------
                      // LEAF
                      // --------------------------------------------------
                      Opacity(
                        opacity: leaf.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.78 + (0.22 * leaf),
                          child: const _LeafLogo(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --------------------------------------------------
                      // NABHKRISHI
                      // --------------------------------------------------
                      Opacity(
                        opacity: name.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - name)),
                          child: Text(
                            'NabhKrishi',
                            style: GoogleFonts.poppins(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 7),

                      // --------------------------------------------------
                      // TAGLINE
                      // --------------------------------------------------
                      Opacity(
                        opacity: tagline.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, 8 * (1 - tagline)),
                          child: Text(
                            'SKY TO SOIL INTELLIGENCE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2.5,
                              color: Colors.white.withValues(alpha: 0.62),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==========================================================
              // VIGNETTE
              // ==========================================================
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.85,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.22),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// BACKGROUND
// ═══════════════════════════════════════════════════════════════════════

class _NabhBackground extends StatelessWidget {
  const _NabhBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF020C18),
            Color(0xFF06314A),
            Color(0xFF08705D),
            Color(0xFF075238),
          ],
          stops: [0.0, 0.38, 0.72, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -130,
            top: -140,
            child: _GlowOrb(size: 390, color: const Color(0xFF36C8DD)),
          ),

          Positioned(
            right: -150,
            bottom: -150,
            child: _GlowOrb(size: 430, color: const Color(0xFF43D477)),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.045),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 100,
            spreadRadius: 25,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// LIGHT TRAILS
// ═══════════════════════════════════════════════════════════════════════

class _LightTrailsPainter extends CustomPainter {
  final double progress;

  _LightTrailsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 10);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 7; i++) {
      final phase = progress * math.pi * 2 + i * 0.85;

      final path = Path();

      final startX = size.width * (0.08 + i * 0.14);

      final sway = math.sin(phase) * 22;

      path.moveTo(startX, -30);

      path.cubicTo(
        startX + sway,
        size.height * 0.28,
        center.dx - sway,
        size.height * 0.38,
        center.dx,
        center.dy,
      );

      path.cubicTo(
        center.dx + sway,
        size.height * 0.62,
        startX - sway,
        size.height * 0.78,
        startX,
        size.height + 30,
      );

      paint
        ..strokeWidth = i == 3 ? 0.8 : 0.45
        ..color = const Color(
          0xFFB9FFE9,
        ).withValues(alpha: i == 3 ? 0.055 : 0.028);

      canvas.drawPath(path, paint);
    }

    // Tiny background particles.
    final random = math.Random(7);

    for (int i = 0; i < 22; i++) {
      final x = random.nextDouble() * size.width;

      final y = random.nextDouble() * size.height;

      final drift = math.sin(progress * math.pi * 2 + i) * 7;

      paint
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFC9FFF0).withValues(alpha: 0.10);

      canvas.drawCircle(Offset(x + drift, y), 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LightTrailsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// LOGO PARTICLES + TORCHLIGHT
// ═══════════════════════════════════════════════════════════════════════

class _LogoParticlesPainter extends CustomPainter {
  final double progress;

  _LogoParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 35);

    final paint = Paint()..style = PaintingStyle.fill;

    const particles = [
      [0.0, 52.0, 0.0],
      [0.45, 58.0, 1.3],
      [0.9, 51.0, 2.4],
      [1.35, 63.0, 3.2],
      [1.8, 55.0, 4.4],
      [2.25, 61.0, 5.1],
      [2.7, 57.0, 0.8],
      [3.15, 65.0, 2.1],
      [3.6, 53.0, 3.8],
      [4.05, 60.0, 5.6],
      [4.5, 56.0, 1.7],
      [4.95, 62.0, 4.9],
    ];

    for (final particle in particles) {
      final angle = particle[0] + progress * math.pi * 2 * 0.32;

      final radius = particle[1];

      final x = center.dx + math.cos(angle) * radius;

      final y = center.dy + math.sin(angle) * radius * 0.72;

      final pulse =
          0.45 +
          0.55 * ((math.sin(progress * math.pi * 4 + particle[2]) + 1) / 2);

      final opacity = (0.12 + 0.25 * pulse).clamp(0.0, 1.0);

      final particleSize = 0.7 + (1.0 * pulse);

      paint.color = const Color(0xFFB9FFE9).withValues(alpha: opacity);

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }

    // --------------------------------------------------------------
    // SOFT MOVING TORCHLIGHT
    // --------------------------------------------------------------

    final torchAngle = progress * math.pi * 2;

    final torchX = center.dx + math.cos(torchAngle) * 75;

    final torchY = center.dy + math.sin(torchAngle) * 48;

    final torch = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFB9FFE9).withValues(alpha: 0.075),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(torchX, torchY), radius: 65),
          );

    canvas.drawCircle(Offset(torchX, torchY), 65, torch);
  }

  @override
  bool shouldRepaint(covariant _LogoParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// LEAF LOGO
// ═══════════════════════════════════════════════════════════════════════

class _LeafLogo extends StatelessWidget {
  const _LeafLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: CustomPaint(painter: _LeafPainter()),
    );
  }
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Soft glow.
    final glow = Paint()
      ..color = const Color(0xFF7CFFE0).withValues(alpha: 0.055)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

    canvas.drawCircle(center, 42, glow);

    // Thin frame.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.13);

    canvas.drawCircle(center, 46, ring);

    // Leaf.
    final leaf = Path()
      ..moveTo(center.dx - 6, center.dy + 31)
      ..cubicTo(
        center.dx - 34,
        center.dy + 12,
        center.dx - 27,
        center.dy - 20,
        center.dx + 25,
        center.dy - 31,
      )
      ..cubicTo(
        center.dx + 34,
        center.dy - 7,
        center.dx + 20,
        center.dy + 21,
        center.dx - 6,
        center.dy + 31,
      )
      ..close();

    final leafPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFFE4FFF7), Color(0xFF7CE8CC), Color(0xFF32B77F)],
      ).createShader(Rect.fromCenter(center: center, width: 70, height: 70));

    canvas.drawPath(leaf, leafPaint);

    // Leaf vein.
    final vein = Path()
      ..moveTo(center.dx - 8, center.dy + 25)
      ..cubicTo(
        center.dx + 1,
        center.dy + 7,
        center.dx + 10,
        center.dy - 10,
        center.dx + 23,
        center.dy - 24,
      );

    final veinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF17604C).withValues(alpha: 0.72);

    canvas.drawPath(vein, veinPaint);
  }

  @override
  bool shouldRepaint(covariant _LeafPainter oldDelegate) {
    return false;
  }
}
