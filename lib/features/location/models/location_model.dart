import 'package:latlong2/latlong.dart';
import '../services/area_calculator.dart';
import 'farm_boundary.dart';

/// The 4 distinct interactive states of the farm map as specified by the team:
/// 1. [normal]: Standard interactive map with GPS and "Draw Farm Boundary" button.
/// 2. [drawing]: Active finger-tracing mode. Map gestures are locked; green line follows touch.
/// 3. [preview]: Drawing finished. Auto-closed translucent polygon with calculated area; [Redraw] or [Confirm].
/// 4. [saved]: Boundary confirmed and persisted locally; displays area and saved polygon.
enum FarmMapMode {
  normal,
  drawing,
  preview,
  saved,
}

class LocationData {
  final double latitude;
  final double longitude;
  final List<LatLng> boundary;
  final List<LatLng> temporaryDrawingPoints;
  final FarmMapMode mapMode;
  final FarmBoundary? activeBoundary;
  final bool isLocating;
  final String? gpsError;

  bool get isDrawing => mapMode == FarmMapMode.drawing;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.boundary,
    this.temporaryDrawingPoints = const [],
    this.mapMode = FarmMapMode.normal,
    this.activeBoundary,
    bool? isDrawing,
    this.isLocating = false,
    this.gpsError,
  });

  LocationData copyWith({
    double? latitude,
    double? longitude,
    List<LatLng>? boundary,
    List<LatLng>? temporaryDrawingPoints,
    FarmMapMode? mapMode,
    FarmBoundary? activeBoundary,
    bool clearActiveBoundary = false,
    bool? isDrawing,
    bool? isLocating,
    String? gpsError,
  }) {
    FarmMapMode resolvedMode = mapMode ?? this.mapMode;
    if (isDrawing != null && mapMode == null) {
      resolvedMode = isDrawing ? FarmMapMode.drawing : FarmMapMode.normal;
    }

    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      boundary: boundary ?? this.boundary,
      temporaryDrawingPoints: temporaryDrawingPoints ?? this.temporaryDrawingPoints,
      mapMode: resolvedMode,
      activeBoundary: clearActiveBoundary ? null : (activeBoundary ?? this.activeBoundary),
      isLocating: isLocating ?? this.isLocating,
      gpsError: gpsError, // cleared if not explicitly passed
    );
  }

  /// Calculates the centroid of the farm boundary polygon.
  /// If boundary is empty, returns current latitude and longitude.
  LatLng get centroid {
    if (activeBoundary != null && activeBoundary!.points.isNotEmpty) {
      return activeBoundary!.centroid;
    }
    if (boundary.isEmpty) {
      return LatLng(latitude, longitude);
    }

    double latSum = 0;
    double lngSum = 0;
    for (final point in boundary) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }

    return LatLng(latSum / boundary.length, lngSum / boundary.length);
  }

  /// Calculates the geographic area of the farm boundary in hectares.
  double get farmAreaHectares {
    if (activeBoundary != null) {
      return activeBoundary!.areaHectares;
    }
    if (boundary.length < 3) return 0.0;
    return AreaCalculator.calculateAreaHectares(boundary);
  }

  /// Calculates the geographic area of the farm boundary in acres.
  double get farmAreaAcres {
    if (activeBoundary != null) {
      return activeBoundary!.areaAcres;
    }
    if (boundary.length < 3) return 0.0;
    return AreaCalculator.calculateAreaAcres(boundary);
  }
}
