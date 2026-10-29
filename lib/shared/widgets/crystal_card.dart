import 'dart:ui';

import 'package:flutter/material.dart';

class CrystalCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const CrystalCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  State<CrystalCard> createState() => _CrystalCardState();
}

class _CrystalCardState extends State<CrystalCard> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapUp: (_) {
          setState(() => pressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => pressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: pressed ? .97 : hovered ? 1.02 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: .18),
                  Colors.white.withValues(alpha: .08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: .22),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: hovered ? 40 : 20,
                  spreadRadius: hovered ? 2 : 0,
                  color: Colors.black.withValues(alpha: .12),
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 20,
                  sigmaY: 20,
                ),
                child: Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
