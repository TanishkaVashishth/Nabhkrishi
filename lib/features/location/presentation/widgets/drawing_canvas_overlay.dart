import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../models/drawing_state.dart';
import '../../services/farm_area_calculator.dart';
import '../../utils/coordinate_converter.dart';

/// Transparent touch overlay placed above the map during [DrawingState.drawing].
/// Captures user finger tracing, converts screen pixels to real geographic coordinates,
/// and renders immediate zero-latency feedback (green stroke, translucent fill, start marker).
class DrawingCanvasOverlay extends StatefulWidget {
  final DrawingState state;
  final MapCamera camera;
  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;
  final ValueChanged<List<LatLng>> onPointsUpdated;
  final ValueChanged<List<LatLng>> onDrawingFinished;
  final List<LatLng> activePoints;

  const DrawingCanvasOverlay({
    super.key,
    required this.state,
    required this.camera,
    this.strokeColor = const Color(0xFF2E7D32),
    this.fillColor = const Color(0x3D2E7D32),
    this.strokeWidth = 3.5,
    required this.onPointsUpdated,
    required this.onDrawingFinished,
    required this.activePoints,
  });

  @override
  State<DrawingCanvasOverlay> createState() => _DrawingCanvasOverlayState();
}

class _DrawingCanvasOverlayState extends State<DrawingCanvasOverlay> {
  // Screen space points captured during current stroke
  final List<Offset> _screenPoints = [];

  @override
  void didUpdateWidget(DrawingCanvasOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If activePoints was cleared externally (e.g. Clear button pressed)
    if (widget.activePoints.isEmpty && _screenPoints.isNotEmpty) {
      setState(() {
        _screenPoints.clear();
      });
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (widget.state != DrawingState.drawing) return;

    final Offset localPos = details.localPosition;
    final LatLng geoPoint = CoordinateConverter.screenOffsetToLatLng(localPos, widget.camera);

    setState(() {
      _screenPoints.clear();
      _screenPoints.add(localPos);
    });

    widget.onPointsUpdated([geoPoint]);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.state != DrawingState.drawing) return;

    final Offset localPos = details.localPosition;

    // Filter high-frequency noise: ignore updates less than 4 screen pixels from previous point
    if (_screenPoints.isNotEmpty) {
      final lastPos = _screenPoints.last;
      final dx = localPos.dx - lastPos.dx;
      final dy = localPos.dy - lastPos.dy;
      if (dx * dx + dy * dy < 16.0) return; // 4px squared
    }

    final LatLng geoPoint = CoordinateConverter.screenOffsetToLatLng(localPos, widget.camera);

    // Verify geographic distance: ignore if less than 1 meter to prevent point bloat
    if (widget.activePoints.isNotEmpty) {
      final double dist = FarmAreaCalculator.distanceMeters(widget.activePoints.last, geoPoint);
      if (dist < 1.0) return;
    }

    setState(() {
      _screenPoints.add(localPos);
    });

    final updated = List<LatLng>.from(widget.activePoints)..add(geoPoint);
    widget.onPointsUpdated(updated);
  }

  void _handlePanEnd(DragEndDetails details) {
    if (widget.state != DrawingState.drawing) return;
    // Clear temporary screen coordinates so painter projects active geoPoints anchored to map
    setState(() {
      _screenPoints.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // When NOT in drawing mode, do NOT mount GestureDetector or capture any touch events
    if (widget.state != DrawingState.drawing) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: CustomPaint(
          size: Size.infinite,
          painter: _DrawingPainter(
            screenPoints: _screenPoints,
            geoPoints: widget.activePoints,
            camera: widget.camera,
            strokeColor: widget.strokeColor,
            fillColor: widget.fillColor,
            strokeWidth: widget.strokeWidth,
            isDrawing: true,
          ),
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Offset> screenPoints;
  final List<LatLng> geoPoints;
  final MapCamera camera;
  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;
  final bool isDrawing;

  _DrawingPainter({
    required this.screenPoints,
    required this.geoPoints,
    required this.camera,
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
    required this.isDrawing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // If active finger stroke is in progress, use screenPoints for zero latency.
    // Otherwise project geoPoints to stay anchored to map coordinates.
    final List<Offset> pointsToRender = screenPoints.isNotEmpty
        ? screenPoints
        : CoordinateConverter.latLngListToScreenOffsets(geoPoints, camera);

    if (pointsToRender.isEmpty) return;

    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    if (pointsToRender.length == 1) {
      // Single tap dot
      canvas.drawCircle(pointsToRender.first, strokeWidth * 1.5, strokePaint);
      return;
    }

    final path = Path()..moveTo(pointsToRender.first.dx, pointsToRender.first.dy);
    for (int i = 1; i < pointsToRender.length; i++) {
      path.lineTo(pointsToRender[i].dx, pointsToRender[i].dy);
    }

    // If 3 or more points, draw translucent fill
    if (pointsToRender.length >= 3) {
      final fillPath = Path.from(path)..close();
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw boundary stroke
    canvas.drawPath(path, strokePaint);

    // Draw start point indicator so user knows where to close the loop
    if (isDrawing && pointsToRender.isNotEmpty) {
      final startPos = pointsToRender.first;

      // Outer halo
      final haloPaint = Paint()
        ..color = strokeColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(startPos, 14, haloPaint);

      // Inner solid dot
      final dotPaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(startPos, 6, dotPaint);

      // White center
      final centerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(startPos, 2.5, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.screenPoints.length != screenPoints.length ||
        oldDelegate.geoPoints.length != geoPoints.length ||
        oldDelegate.camera != camera ||
        oldDelegate.isDrawing != isDrawing;
  }
}
