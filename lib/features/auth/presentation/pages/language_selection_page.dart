import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_page.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() =>
      _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  String language = 'English';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _animate(
    double begin,
    double end, {
    Curve curve = Curves.easeOutCubic,
  }) {
    final value = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        begin,
        end,
        curve: curve,
      ),
    ).value;

    return value.clamp(0.0, 1.0).toDouble();
  }

  void _continue() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        reverseTransitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, animation, _) => LoginPage(language: language),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff041525),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final leaf = _animate(
            0.0,
            0.38,
            curve: Curves.easeOutBack,
          );

          final heading = _animate(
            0.18,
            0.52,
          );

          final cards = _animate(
            0.30,
            0.68,
          );

          final button = _animate(
            0.52,
            0.84,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              const _LanguageBackground(),

              IgnorePointer(
                child: CustomPaint(
                  painter: _AmbientParticlesPainter(
                    progress: _controller.value,
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // --------------------------------------------------
                      // LEAF
                      // --------------------------------------------------

                      Opacity(
                        opacity: leaf,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            16 * (1 - leaf),
                          ),
                          child: Transform.scale(
                            scale: 0.84 + (leaf * 0.16),
                            child: const _SmallLeafLogo(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // --------------------------------------------------
                      // HEADING
                      // --------------------------------------------------

                      Opacity(
                        opacity: heading,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            14 * (1 - heading),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Welcome to',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(
                                    alpha: 0.62,
                                  ),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 1.2,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'NabhKrishi',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 31,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.8,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'Choose how you want to experience\n'
                                'Sky to Soil Intelligence',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(
                                    alpha: 0.48,
                                  ),
                                  fontSize: 12.5,
                                  height: 1.5,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 38),

                      // --------------------------------------------------
                      // LANGUAGE CARDS
                      // --------------------------------------------------

                      Opacity(
                        opacity: cards,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            20 * (1 - cards),
                          ),
                          child: Column(
                            children: [
                              _LanguageCard(
                                title: 'English',
                                subtitle: 'Continue in English',
                                symbol: 'EN',
                                selected: language == 'English',
                                onTap: () {
                                  setState(() {
                                    language = 'English';
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              _LanguageCard(
                                title: 'हिन्दी',
                                subtitle: 'हिन्दी में जारी रखें',
                                symbol: 'हि',
                                selected: language == 'Hindi',
                                onTap: () {
                                  setState(() {
                                    language = 'Hindi';
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              _LanguageCard(
                                title: 'ਪੰਜਾਬੀ',
                                subtitle: 'ਪੰਜਾਬੀ ਵਿੱਚ ਜਾਰੀ ਰੱਖੋ',
                                symbol: 'ਪੰ',
                                selected: language == 'Punjabi',
                                onTap: () {
                                  setState(() {
                                    language = 'Punjabi';
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              _LanguageCard(
                                title: 'বাংলা',
                                subtitle: 'বাংলায় এগিয়ে যান',
                                symbol: 'বা',
                                selected: language == 'Bengali',
                                onTap: () {
                                  setState(() {
                                    language = 'Bengali';
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              _LanguageCard(
                                title: 'हरियाणवी',
                                subtitle: 'हरियाणवी में आगे बढ़ो',
                                symbol: 'हरि',
                                selected: language == 'Haryanvi',
                                onTap: () {
                                  setState(() {
                                    language = 'Haryanvi';
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              _LanguageCard(
                                title: 'Hinglish',
                                subtitle: 'Hinglish mein aage badhein',
                                symbol: 'Hing',
                                selected: language == 'Hinglish',
                                onTap: () {
                                  setState(() {
                                    language = 'Hinglish';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // --------------------------------------------------
                      // CONTINUE
                      // --------------------------------------------------

                      Opacity(
                        opacity: button,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            16 * (1 - button),
                          ),
                          child: _ContinueButton(
                            onPressed: _continue,
                          ),
                        ),
                      ),

                      const SizedBox(height: 13),

                      Opacity(
                        opacity: (button * 0.65)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                        child: Text(
                          'You can change this later',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(
                              alpha: 0.34,
                            ),
                            fontSize: 11,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Opacity(
                        opacity: (button * 0.40)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: Text(
                            'NABHKRISHI',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                    ],
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

// ================================================================
// BACKGROUND
// ================================================================

class _LanguageBackground extends StatelessWidget {
  const _LanguageBackground();

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
                Color(0xff03142A),
                Color(0xff062D46),
                Color(0xff086653),
                Color(0xff06452F),
              ],
              stops: [
                0.0,
                0.40,
                0.75,
                1.0,
              ],
            ),
          ),
        ),

        Positioned(
          top: -190,
          right: -150,
          child: _BackgroundGlow(
            size: 430,
            color: const Color(0xff3CCFE0),
          ),
        ),

        Positioned(
          bottom: -220,
          left: -160,
          child: _BackgroundGlow(
            size: 490,
            color: const Color(0xff45D77E),
          ),
        ),

        Positioned(
          top: 230,
          left: -120,
          child: _BackgroundGlow(
            size: 260,
            color: const Color(0xff65E7C2),
          ),
        ),

        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.84,
                colors: [
                  Colors.transparent,
                  Color(0x30000000),
                ],
                stops: [
                  0.46,
                  1.0,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _BackgroundGlow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.025),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.055),
            blurRadius: 110,
            spreadRadius: 24,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// AMBIENT PARTICLES
// ================================================================

class _AmbientParticlesPainter extends CustomPainter {
  final double progress;

  const _AmbientParticlesPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      155,
    );

    final paint = Paint();

    const particles = [
      [0.2, 72.0, 0.0],
      [1.0, 91.0, 1.4],
      [2.1, 69.0, 2.6],
      [3.0, 108.0, 3.4],
      [4.1, 82.0, 4.8],
      [5.0, 96.0, 5.6],
      [5.8, 76.0, 2.0],
      [6.4, 112.0, 0.8],
    ];

    for (final particle in particles) {
      final angle =
          particle[0] +
          progress * math.pi * 2 * 0.055;

      final radius = particle[1];

      final position = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy +
            math.sin(angle) *
                radius *
                0.40,
      );

      final pulse =
          0.5 +
          0.5 *
              math.sin(
                progress * math.pi * 2 +
                    particle[2],
              );

      final alpha = (0.025 + pulse * 0.035)
          .clamp(0.0, 1.0)
          .toDouble();

      paint.color = const Color(0xffB9FFE9)
          .withValues(alpha: alpha);

      canvas.drawCircle(
        position,
        0.65 + pulse * 0.3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _AmbientParticlesPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

// ================================================================
// LEAF
// ================================================================

class _SmallLeafLogo extends StatelessWidget {
  const _SmallLeafLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 82,
      child: CustomPaint(
        painter: _SmallLeafPainter(),
      ),
    );
  }
}

class _SmallLeafPainter extends CustomPainter {
  const _SmallLeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final glow = Paint()
      ..color = const Color(0xff7CFFE0)
          .withValues(alpha: 0.045)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        18,
      );

    canvas.drawCircle(
      center,
      31,
      glow,
    );

    final leaf = Path()
      ..moveTo(
        center.dx - 4,
        center.dy + 22,
      )
      ..cubicTo(
        center.dx - 24,
        center.dy + 9,
        center.dx - 20,
        center.dy - 14,
        center.dx + 18,
        center.dy - 22,
      )
      ..cubicTo(
        center.dx + 25,
        center.dy - 5,
        center.dx + 14,
        center.dy + 15,
        center.dx - 4,
        center.dy + 22,
      )
      ..close();

    final leafPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xffE4FFF7),
          Color(0xff7CE8CC),
          Color(0xff32B77F),
        ],
      ).createShader(
        Rect.fromCenter(
          center: center,
          width: 54,
          height: 54,
        ),
      );

    canvas.drawPath(
      leaf,
      leafPaint,
    );

    final vein = Path()
      ..moveTo(
        center.dx - 5,
        center.dy + 18,
      )
      ..cubicTo(
        center.dx + 1,
        center.dy + 5,
        center.dx + 7,
        center.dy - 7,
        center.dx + 17,
        center.dy - 17,
      );

    final veinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xff17604C)
          .withValues(alpha: 0.7);

    canvas.drawPath(
      vein,
      veinPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _SmallLeafPainter oldDelegate,
  ) {
    return false;
  }
}

// ================================================================
// LANGUAGE CARD
// ================================================================

class _LanguageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String symbol;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.symbol,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        height: 68,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected
              ? const Color(0xff8CE8C6)
                  .withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.055),
          border: Border.all(
            color: selected
                ? const Color(0xff8CE8C6)
                    .withValues(alpha: 0.42)
                : Colors.white.withValues(alpha: 0.10),
            width: selected ? 1.2 : 0.8,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xff62E4B8)
                        .withValues(alpha: 0.10),
                    blurRadius: 26,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 43,
              height: 43,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? const Color(0xff9CFFE0)
                        .withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.06),
              ),
              child: Text(
                symbol,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(
                        alpha: 0.46,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder:
                  (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: selected
                  ? Container(
                      key: const ValueKey(
                        'selected',
                      ),
                      width: 26,
                      height: 26,
                      decoration:
                          const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xff8CE8C6),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Color(0xff075238),
                      ),
                    )
                  : Container(
                      key: const ValueKey(
                        'unselected',
                      ),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: 0.20),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// CONTINUE BUTTON
// ================================================================

class _ContinueButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _ContinueButton({
    required this.onPressed,
  });

  @override
  State<_ContinueButton> createState() =>
      _ContinueButtonState();
}

class _ContinueButtonState
    extends State<_ContinueButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          pressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          pressed = false;
        });

        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          pressed = false;
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: pressed ? 0.985 : 1,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xffE9FFF7),
                Color(0xffBFF7DD),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff7DE6BE)
                    .withValues(alpha: 0.13),
                blurRadius: 25,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: GoogleFonts.poppins(
                  color: const Color(0xff075238),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xff075238),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}