import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../models/satellite_field_data.dart';

/// Interactive Native Flutter recreation of the NabhKrishi-Web Reference:
/// - SatelliteExperience.tsx
/// - SatelliteScanScene.tsx
/// - Satellite.tsx (Solar panels, SAR dish, beacon, hover)
/// - RadarSweep.tsx (Expanding & fading turquoise ring #58E0C9)
/// - WheatField.tsx (500 procedural wheat blades, wind sway, golden #D8A34D)
/// - ScanHighlight.tsx (Pulsing turquoise ring smoothly gliding between R1-R4)
class SatelliteRadarScannerWidget extends StatefulWidget {
  final int selectedRegionIndex;
  final ValueChanged<int> onRegionSelected;
  final String language;
  final bool isHindi;

  const SatelliteRadarScannerWidget({
    super.key,
    required this.selectedRegionIndex,
    required this.onRegionSelected,
    this.language = 'en',
    this.isHindi = false,
  });

  @override
  State<SatelliteRadarScannerWidget> createState() => _SatelliteRadarScannerWidgetState();
}

class _SatelliteRadarScannerWidgetState extends State<SatelliteRadarScannerWidget>
    with TickerProviderStateMixin {
  late final AnimationController _cycleController;
  late final AnimationController _highlightController;

  late Offset _currentHighlightOffset;
  late Offset _targetHighlightOffset;
  Offset _previousHighlightOffset = Offset.zero;

  // Cached random properties for procedural wheat blades (height, phase, radius, angle)
  late final List<_WheatBladeData> _wheatBlades;

  @override
  void initState() {
    super.initState();

    // 1. Continuous animation for wind sway, radar expansion, and satellite hover
    _cycleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 2. Smooth glide animation for scan-highlight ring transitions
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    final initialRegion = kPrototypeSatelliteRegions[widget.selectedRegionIndex];
    _currentHighlightOffset = initialRegion.relativeOffset;
    _targetHighlightOffset = initialRegion.relativeOffset;
    _previousHighlightOffset = initialRegion.relativeOffset;

    // Generate 500 procedural radial wheat blades to match reference specification
    final rng = math.Random(42);
    _wheatBlades = List.generate(500, (i) {
      final r = math.sqrt(rng.nextDouble()) * 0.90; // radial distribution
      final theta = rng.nextDouble() * 2 * math.pi;
      final height = 11.0 + rng.nextDouble() * 9.0;
      final phase = rng.nextDouble() * 2 * math.pi;
      final lean = (rng.nextDouble() - 0.5) * 0.4;
      final isDigitalTip = rng.nextDouble() < 0.22; // 22% digital turquoise tips

      return _WheatBladeData(
        r: r,
        theta: theta,
        height: height,
        phase: phase,
        lean: lean,
        isDigitalTip: isDigitalTip,
      );
    });
  }

  @override
  void didUpdateWidget(covariant SatelliteRadarScannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRegionIndex != widget.selectedRegionIndex) {
      _previousHighlightOffset = _targetHighlightOffset;
      _targetHighlightOffset =
          kPrototypeSatelliteRegions[widget.selectedRegionIndex].relativeOffset;
      _highlightController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _cycleController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeLanguage = widget.language.isNotEmpty
        ? widget.language
        : (widget.isHindi ? 'hi' : 'en');
    final loc = AppLocalizations(activeLanguage);

    return Container(
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF07100C), // Reference background: #07100C
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF58E0C9).withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF58E0C9).withValues(alpha: 0.12),
            blurRadius: 28,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // 1. Native Canvas with Satellite, Wheat Field, Radar Sweep & Highlight
            GestureDetector(
              onTapUp: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPos = details.localPosition;
                // Center of circular wheat field (located in bottom half of canvas)
                final fieldCenter = Offset(box.size.width / 2, box.size.height * 0.58);
                final fieldRadius = math.min(box.size.width, box.size.height) * 0.38;

                int closestIdx = widget.selectedRegionIndex;
                double minDistance = 60.0;

                for (int i = 0; i < kPrototypeSatelliteRegions.length; i++) {
                  final reg = kPrototypeSatelliteRegions[i];
                  final pt = Offset(
                    fieldCenter.dx + reg.relativeOffset.dx * fieldRadius,
                    fieldCenter.dy + reg.relativeOffset.dy * fieldRadius * 0.70, // 2.5D perspective scale
                  );
                  final dist = (localPos - pt).distance;
                  if (dist < minDistance) {
                    minDistance = dist;
                    closestIdx = i;
                  }
                }

                if (closestIdx != widget.selectedRegionIndex) {
                  widget.onRegionSelected(closestIdx);
                }
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([_cycleController, _highlightController]),
                builder: (context, _) {
                  // Smoothly interpolate highlight position
                  final tHighlight = CurvedAnimation(
                    parent: _highlightController,
                    curve: Curves.easeInOutCubic,
                  ).value;
                  _currentHighlightOffset = Offset.lerp(
                    _previousHighlightOffset,
                    _targetHighlightOffset,
                    _highlightController.isAnimating ? tHighlight : 1.0,
                  )!;

                  return CustomPaint(
                    size: Size.infinite,
                    painter: _ReferenceSatelliteScanPainter(
                      cycleProgress: _cycleController.value,
                      highlightOffset: _currentHighlightOffset,
                      selectedRegionIndex: widget.selectedRegionIndex,
                      regions: kPrototypeSatelliteRegions,
                      wheatBlades: _wheatBlades,
                      language: activeLanguage,
                    ),
                  );
                },
              ),
            ),

            // 2. Top Telemetry Status Badges
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Active Sensor Badge
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF031A22).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF58E0C9).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF58E0C9),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              loc.translate('sentinel_sar_band'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceMono(
                                color: const Color(0xFF58E0C9),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Polarization Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      loc.translate('vv_polarization'),
                      style: GoogleFonts.spaceMono(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Bottom Status Bar: "⟳ SCANNING..."
            Positioned(
              bottom: 12,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF58E0C9).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.radar_rounded,
                          size: 13,
                          color: Color(0xFF58E0C9),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${loc.translate('scanning')} ${kPrototypeSatelliteRegions[widget.selectedRegionIndex].label}',
                          style: GoogleFonts.spaceMono(
                            color: const Color(0xFF58E0C9),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2A1A).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        loc.translate('tap_sector_hint'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheatBladeData {
  final double r;
  final double theta;
  final double height;
  final double phase;
  final double lean;
  final bool isDigitalTip;

  const _WheatBladeData({
    required this.r,
    required this.theta,
    required this.height,
    required this.phase,
    required this.lean,
    required this.isDigitalTip,
  });
}

class _ReferenceSatelliteScanPainter extends CustomPainter {
  final double cycleProgress; // 0.0 to 1.0 continuously looping
  final Offset highlightOffset;
  final int selectedRegionIndex;
  final List<SatelliteRegionSignal> regions;
  final List<_WheatBladeData> wheatBlades;
  final String language;

  _ReferenceSatelliteScanPainter({
    required this.cycleProgress,
    required this.highlightOffset,
    required this.selectedRegionIndex,
    required this.regions,
    required this.wheatBlades,
    required this.language,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ------------------------------------------------------------------------
    // Geometry & Positions
    // ------------------------------------------------------------------------
    // Field center in 2.5D perspective (positioned lower in the canvas)
    final fieldCenter = Offset(size.width / 2, size.height * 0.58);
    final fieldRadiusX = size.width * 0.44;
    final fieldRadiusY = size.height * 0.30; // 2.5D perspective foreshortening

    // Satellite position above the field
    // Subtle hover animation with sinusoidal floating
    final hoverY = math.sin(cycleProgress * 2 * math.pi) * 4.0;
    final satellitePos = Offset(size.width / 2, size.height * 0.17 + hoverY);

    // ------------------------------------------------------------------------
    // 1. Background Grid & Space Depth
    // ------------------------------------------------------------------------
    _drawDeepSpaceGrid(canvas, size);

    // ------------------------------------------------------------------------
    // 2. Circular Field Platform Base (#1B2A1A)
    // ------------------------------------------------------------------------
    _drawFieldPlatform(canvas, fieldCenter, fieldRadiusX, fieldRadiusY);

    // ------------------------------------------------------------------------
    // 3. Radar Beam swath from Satellite Dish to Field
    // ------------------------------------------------------------------------
    _drawRadarBeamSwath(canvas, satellitePos, fieldCenter, fieldRadiusX, fieldRadiusY);

    // ------------------------------------------------------------------------
    // 4. Radar Sweep: Expanding & Fading Turquoise Ring (#58E0C9)
    // ------------------------------------------------------------------------
    _drawExpandingRadarSweep(canvas, fieldCenter, fieldRadiusX, fieldRadiusY);

    // ------------------------------------------------------------------------
    // 5. Wheat Field: ~360 Procedural Blades with Subtle Wind Sway (#D8A34D)
    // ------------------------------------------------------------------------
    _drawWheatBlades(canvas, fieldCenter, fieldRadiusX, fieldRadiusY);

    // ------------------------------------------------------------------------
    // 6. Scan Highlight Ring (Pulsing turquoise ring sitting on field)
    // ------------------------------------------------------------------------
    _drawScanHighlight(canvas, fieldCenter, fieldRadiusX, fieldRadiusY);

    // ------------------------------------------------------------------------
    // 7. Region Markers (R1, R2, R3, R4)
    // ------------------------------------------------------------------------
    _drawRegionReticles(canvas, fieldCenter, fieldRadiusX, fieldRadiusY);

    // ------------------------------------------------------------------------
    // 8. Overhead Satellite (Chassis, Solar Panels, SAR Dish, Nav Light)
    // ------------------------------------------------------------------------
    _drawReferenceSatellite(canvas, satellitePos);
  }

  void _drawDeepSpaceGrid(Canvas canvas, Size size) {
    // Subtle orbital range rings from satellite
    final orbitPaint = Paint()
      ..color = const Color(0xFF58E0C9).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final satCenter = Offset(size.width / 2, size.height * 0.17);
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(satCenter, i * 45.0, orbitPaint);
    }
  }

  void _drawFieldPlatform(Canvas canvas, Offset center, double rx, double ry) {
    final fieldRect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);

    // Base soil & vegetative field gradient (#1B2A1A)
    final baseGradient = RadialGradient(
      center: const Alignment(0.0, -0.2),
      radius: 0.95,
      colors: [
        const Color(0xFF223620), // Rich organic wheat vegetation
        const Color(0xFF1B2A1A), // Reference dark field base #1B2A1A
        const Color(0xFF0E1A11), // Shadow rim
      ],
      stops: const [0.0, 0.70, 1.0],
    );

    final basePaint = Paint()
      ..shader = baseGradient.createShader(fieldRect)
      ..style = PaintingStyle.fill;
    canvas.drawOval(fieldRect, basePaint);

    // Outer circular boundary glow (#58E0C9)
    final borderPaint = Paint()
      ..color = const Color(0xFF58E0C9).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(fieldRect, borderPaint);

    // Inner concentric sector guide lines
    final innerGuidePaint = Paint()
      ..color = const Color(0xFF58E0C9).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 1.3, height: ry * 1.3),
      innerGuidePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 0.65, height: ry * 0.65),
      innerGuidePaint,
    );

    // Sector divider cross lines
    canvas.drawLine(
      Offset(center.dx - rx * 0.85, center.dy),
      Offset(center.dx + rx * 0.85, center.dy),
      innerGuidePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - ry * 0.85),
      Offset(center.dx, center.dy + ry * 0.85),
      innerGuidePaint,
    );
  }

  void _drawRadarBeamSwath(
    Canvas canvas,
    Offset satPos,
    Offset fieldCenter,
    double rx,
    double ry,
  ) {
    // Semi-transparent radar cone emanating downward from satellite antenna to field
    final dishPos = Offset(satPos.dx, satPos.dy + 14);

    final swathPath = Path()
      ..moveTo(dishPos.dx - 8, dishPos.dy)
      ..lineTo(fieldCenter.dx - rx * 0.75, fieldCenter.dy)
      ..lineTo(fieldCenter.dx + rx * 0.75, fieldCenter.dy)
      ..lineTo(dishPos.dx + 8, dishPos.dy)
      ..close();

    final swathGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF58E0C9).withValues(alpha: 0.18),
        const Color(0xFF58E0C9).withValues(alpha: 0.04),
        const Color(0xFF58E0C9).withValues(alpha: 0.00),
      ],
      stops: const [0.0, 0.60, 1.0],
    );

    final swathPaint = Paint()
      ..shader = swathGradient.createShader(swathPath.getBounds())
      ..style = PaintingStyle.fill;

    canvas.drawPath(swathPath, swathPaint);
  }

  void _drawExpandingRadarSweep(
    Canvas canvas,
    Offset center,
    double rx,
    double ry,
  ) {
    // Reference RadarSweep:
    // Starts small (~0.2), expands toward edge (1.0), fading as it expands
    // Repeatedly: starts small, expands, fades, restarts.
    final ringProgress = (cycleProgress * 1.5) % 1.0;
    final ringScale = 0.15 + ringProgress * 0.85;
    final ringOpacity = (1.0 - ringProgress).clamp(0.0, 1.0) * 0.75;

    final sweepRect = Rect.fromCenter(
      center: center,
      width: rx * 2 * ringScale,
      height: ry * 2 * ringScale,
    );

    final sweepPaint = Paint()
      ..color = const Color(0xFF58E0C9).withValues(alpha: ringOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawOval(sweepRect, sweepPaint);

    // Subtle second echo ring for added depth
    final echoProgress = ((cycleProgress * 1.5) + 0.5) % 1.0;
    final echoScale = 0.15 + echoProgress * 0.85;
    final echoOpacity = (1.0 - echoProgress).clamp(0.0, 1.0) * 0.40;

    final echoRect = Rect.fromCenter(
      center: center,
      width: rx * 2 * echoScale,
      height: ry * 2 * echoScale,
    );

    final echoPaint = Paint()
      ..color = const Color(0xFF58E0C9).withValues(alpha: echoOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawOval(echoRect, echoPaint);
  }

  void _drawWheatBlades(
    Canvas canvas,
    Offset center,
    double rx,
    double ry,
  ) {
    // Golden wheat color (#D8A34D) & Digital turquoise tips (#58E0C9)
    const baseWheatColor = Color(0xFFD8A34D);
    const digitalWheatColor = Color(0xFF58E0C9);

    final wheatPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final currentTime = cycleProgress * 2 * math.pi;

    for (final blade in wheatBlades) {
      // 2.5D perspective coordinates on the circular platform
      final px = center.dx + blade.r * rx * math.cos(blade.theta);
      final py = center.dy + blade.r * ry * math.sin(blade.theta);

      // Wind sway displacement using sine wave
      final sway = math.sin(currentTime * 2.0 + blade.phase) * (3.5 + blade.lean * 4.0);

      final tipX = px + sway;
      final tipY = py - blade.height;

      // Color selection
      wheatPaint.color = blade.isDigitalTip
          ? digitalWheatColor.withValues(alpha: 0.85)
          : baseWheatColor.withValues(alpha: 0.75);
      wheatPaint.strokeWidth = blade.isDigitalTip ? 1.6 : 1.2;

      // Draw tapered wheat blade line
      canvas.drawLine(Offset(px, py), Offset(tipX, tipY), wheatPaint);

      // Wheat ear head dot on top
      if (blade.r < 0.85) {
        final earPaint = Paint()
          ..color = blade.isDigitalTip
              ? digitalWheatColor.withValues(alpha: 0.90)
              : baseWheatColor.withValues(alpha: 0.85)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(tipX, tipY), 1.3, earPaint);
      }
    }
  }

  void _drawScanHighlight(
    Canvas canvas,
    Offset center,
    double rx,
    double ry,
  ) {
    // Reference ScanHighlight:
    // - Sits on wheat field
    // - Follows selected region position (highlightOffset)
    // - Pulses slightly (scale 1 ± 0.08)
    // - High turquoise visibility (#58E0C9)
    final hx = center.dx + highlightOffset.dx * rx;
    final hy = center.dy + highlightOffset.dy * ry;

    final pulseScale = 1.0 + math.sin(cycleProgress * 4 * math.pi) * 0.08;
    final baseRadius = 22.0 * pulseScale;

    // Glowing outer aura
    final auraPaint = Paint()
      ..color = const Color(0xFF58E0C9).withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx, hy), width: baseRadius * 2.2, height: baseRadius * 1.4),
      auraPaint,
    );

    // Primary turquoise ring
    final ringPaint = Paint()
      ..color = const Color(0xFF58E0C9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx, hy), width: baseRadius * 1.8, height: baseRadius * 1.1),
      ringPaint,
    );

    // Center focal point
    final corePaint = Paint()
      ..color = const Color(0xFF58E0C9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(hx, hy), 3.5, corePaint);
  }

  void _drawRegionReticles(
    Canvas canvas,
    Offset center,
    double rx,
    double ry,
  ) {
    for (int i = 0; i < regions.length; i++) {
      final reg = regions[i];
      final px = center.dx + reg.relativeOffset.dx * rx;
      final py = center.dy + reg.relativeOffset.dy * ry;
      final isSelected = i == selectedRegionIndex;

      final reticleColor = isSelected ? const Color(0xFF58E0C9) : Colors.white60;

      // Small reticle ring
      final reticlePaint = Paint()
        ..color = reticleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.8 : 1.0;
      canvas.drawCircle(Offset(px, py), isSelected ? 9.0 : 6.5, reticlePaint);

      // Label text
      final textPainter = TextPainter(
        text: TextSpan(
          text: reg.label,
          style: TextStyle(
            color: reticleColor,
            fontSize: isSelected ? 11.5 : 9.5,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.spaceMono().fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(px - textPainter.width / 2, py + (isSelected ? 11 : 9)),
      );
    }
  }

  void _drawReferenceSatellite(Canvas canvas, Offset satPos) {
    // Reference Satellite components:
    // 1. Satellite body (light metallic gray)
    // 2. Left solar panel (dark blue photovoltaic)
    // 3. Right solar panel (dark blue photovoltaic)
    // 4. SAR antenna/dish (light gray)
    // 5. Small navigation light (turquoise)
    // Subtle rotation / tilt animation as satellite orbits and hovers
    final tiltAngle = math.sin(cycleProgress * 2 * math.pi) * 0.05;

    canvas.save();
    canvas.translate(satPos.dx, satPos.dy);
    canvas.rotate(tiltAngle);

    // A. Left Solar Panel Array
    final solarPaint = Paint()..color = const Color(0xFF1B3B6F); // Dark blue photovoltaic
    final solarGridPaint = Paint()
      ..color = const Color(0xFF58E0C9).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final leftPanelRect = const Rect.fromLTWH(-36, -7, 20, 14);
    canvas.drawRRect(RRect.fromRectAndRadius(leftPanelRect, const Radius.circular(2)), solarPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(leftPanelRect, const Radius.circular(2)), solarGridPaint);

    // Left solar panel cell grid lines
    canvas.drawLine(
      const Offset(-26, -7),
      const Offset(-26, 7),
      solarGridPaint,
    );

    // Left panel arm
    final armPaint = Paint()
      ..color = const Color(0xFFC4CAD4)
      ..strokeWidth = 1.8;
    canvas.drawLine(const Offset(-16, 0), const Offset(-9, 0), armPaint);

    // B. Right Solar Panel Array
    final rightPanelRect = const Rect.fromLTWH(16, -7, 20, 14);
    canvas.drawRRect(RRect.fromRectAndRadius(rightPanelRect, const Radius.circular(2)), solarPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rightPanelRect, const Radius.circular(2)), solarGridPaint);

    // Right solar panel cell grid lines
    canvas.drawLine(
      const Offset(26, -7),
      const Offset(26, 7),
      solarGridPaint,
    );

    // Right panel arm
    canvas.drawLine(const Offset(9, 0), const Offset(16, 0), armPaint);

    // C. Satellite Body (Metallic Light Gray)
    final bodyRect = Rect.fromCenter(center: Offset.zero, width: 18, height: 14);
    final bodyPaint = Paint()..color = const Color(0xFFD6DBE5);
    final bodyBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)), bodyBorder);

    // D. SAR Antenna / Downlink Dish (Light Gray)
    const dishCenter = Offset(0, 11);
    final dishPaint = Paint()
      ..color = const Color(0xFFE0E5EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawArc(
      Rect.fromCircle(center: dishCenter, radius: 6.5),
      0,
      math.pi,
      false,
      dishPaint,
    );

    // Feed horn pointing down
    canvas.drawLine(
      dishCenter,
      const Offset(0, 16),
      Paint()
        ..color = const Color(0xFF58E0C9)
        ..strokeWidth = 1.5,
    );

    // E. Navigation Beacon Light (Turquoise #58E0C9 with pulsing flash)
    final beaconGlow = (math.sin(cycleProgress * 8 * math.pi) * 0.5 + 0.5).clamp(0.2, 1.0);
    final beaconPaint = Paint()
      ..color = const Color(0xFF58E0C9).withValues(alpha: beaconGlow);
    canvas.drawCircle(const Offset(0, -8), 2.2, beaconPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ReferenceSatelliteScanPainter oldDelegate) {
    return oldDelegate.cycleProgress != cycleProgress ||
        oldDelegate.highlightOffset != highlightOffset ||
        oldDelegate.selectedRegionIndex != selectedRegionIndex ||
        oldDelegate.language != language;
  }
}
