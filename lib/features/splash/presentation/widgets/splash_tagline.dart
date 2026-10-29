import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

/// App name + tagline, fading/sliding in slightly after the logo so the
/// eye has a clear sequence to follow (logo -> name -> tagline).
class SplashTagline extends StatefulWidget {
  const SplashTagline({super.key});

  @override
  State<SplashTagline> createState() => _SplashTaglineState();
}

class _SplashTaglineState extends State<SplashTagline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Delay start so this sequences after the logo's own entrance animation.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Column(
          children: [
            Text('NabhKrishi', style: AppTextStyles.display),
            const SizedBox(height: 8),
            Text(
              'Sky-smart farming, in your hands',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
