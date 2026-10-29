import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/utils/responsive_extensions.dart';

/// The centerpiece of the splash screen:
/// - Hero-tagged so it can morph into the Language Selection screen's logo
/// - Lottie growth animation plays once behind/around it
/// - Fades + scales in on entry rather than just appearing
class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = context.scale(140);

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: logoSize + 60,
          height: logoSize + 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Lottie plays a subtle growth/leaf animation behind the mark.
              Lottie.asset(
                AssetPaths.splashLottie,
                width: logoSize + 60,
                height: logoSize + 60,
                fit: BoxFit.contain,
                repeat: false,
                errorBuilder: (context, error, stackTrace) {
                  // Graceful fallback if the Lottie asset isn't bundled yet —
                  // never let a missing animation crash the splash screen.
                  return const SizedBox.shrink();
                },
              ),
              Hero(
                tag: HeroTags.appLogo,
                child: Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(logoSize * 0.2),
                  child: Image.asset(
                    AssetPaths.logo,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 56,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
