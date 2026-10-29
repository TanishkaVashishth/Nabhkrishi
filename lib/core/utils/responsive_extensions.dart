import 'package:flutter/material.dart';

/// Lightweight responsive helpers — avoids pulling in a full package
/// dependency for something this simple. Scales relative to a 390pt-wide
/// reference (iPhone 14 / common Android baseline).
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isTablet => screenWidth >= 600;
  bool get isSmallPhone => screenWidth < 360;

  /// Scales a design-reference size down/up based on actual screen width.
  double scale(double designValue, {double reference = 390}) {
    final factor = screenWidth / reference;
    // Clamp so we never get absurdly large logos on tablets or
    // crushed layouts on tiny phones.
    return designValue * factor.clamp(0.85, 1.35);
  }
}
