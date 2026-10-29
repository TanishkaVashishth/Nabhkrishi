import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/farm_boundary.dart';
import '../models/location_model.dart';
import '../services/farm_boundary_service.dart';

class LocationNotifier extends Notifier<LocationData> {
  @override
  LocationData build() {
    // Attempt to load persisted boundary on startup asynchronously
    Future.microtask(() => _loadPersistedBoundary());

    // Default location: Ludhiana agricultural zone (30.9009, 75.8573)
    return LocationData(
      latitude: 30.9009,
      longitude: 75.8573,
      boundary: const [],
      temporaryDrawingPoints: const [],
      mapMode: FarmMapMode.normal,
      isLocating: false,
    );
  }

  Future<void> _loadPersistedBoundary() async {
    try {
      final boundaryService = ref.read(farmBoundaryServiceProvider);
      final savedBoundary = await boundaryService.loadSavedBoundary();
      if (savedBoundary != null && savedBoundary.isValid) {
        state = state.copyWith(
          activeBoundary: savedBoundary,
          boundary: savedBoundary.points,
          latitude: savedBoundary.centroid.latitude,
          longitude: savedBoundary.centroid.longitude,
          mapMode: FarmMapMode.saved,
        );
      }
    } catch (_) {
      // Gracefully ignore local read failure
    }
  }

  void updateCoordinate(double latitude, double longitude) {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Switches to Drawing Mode (State 2)
  void startDrawing() {
    state = state.copyWith(
      mapMode: FarmMapMode.drawing,
      temporaryDrawingPoints: const [],
      gpsError: null,
    );
  }

  /// Appends a touch point during live finger drag on the map.
  /// Ignores duplicate points closer than threshold distance for optimal performance.
  void addDrawingPoint(LatLng point) {
    if (state.mapMode != FarmMapMode.drawing) return;

    final currentPoints = state.temporaryDrawingPoints;
    if (currentPoints.isNotEmpty) {
      final lastPoint = currentPoints.last;
      final latDiff = (point.latitude - lastPoint.latitude).abs();
      final lngDiff = (point.longitude - lastPoint.longitude).abs();
      // Minimum delta (~1.5 meters) to avoid bloating coordinates
      if (latDiff < 0.000015 && lngDiff < 0.000015) {
        return;
      }
    }

    final updated = List<LatLng>.from(currentPoints)..add(point);
    state = state.copyWith(temporaryDrawingPoints: updated);
  }

  /// Finishes active drawing: validates point count (minimum 4 points),
  /// creates closed polygon, calculates geodesic area, and transitions to Preview Mode (State 3).
  bool finishDrawing() {
    final raw = state.temporaryDrawingPoints;
    if (raw.length < 4) {
      state = state.copyWith(
        gpsError: 'please_trace_boundary',
      );
      return false;
    }

    final boundary = FarmBoundary.fromPoints(raw);
    if (!boundary.isValid) {
      state = state.copyWith(
        gpsError: 'please_trace_boundary',
      );
      return false;
    }

    state = state.copyWith(
      activeBoundary: boundary,
      boundary: boundary.points,
      latitude: boundary.centroid.latitude,
      longitude: boundary.centroid.longitude,
      mapMode: FarmMapMode.preview,
      gpsError: null,
    );
    return true;
  }

  /// Confirms the drawn boundary: persists locally as GeoJSON and transitions to Saved Mode (State 4).
  Future<bool> confirmBoundary() async {
    FarmBoundary? boundary = state.activeBoundary;
    if (boundary == null || !boundary.isValid) {
      if (state.temporaryDrawingPoints.length >= 4) {
        boundary = FarmBoundary.fromPoints(state.temporaryDrawingPoints);
      } else if (state.boundary.length >= 4) {
        boundary = FarmBoundary.fromPoints(state.boundary);
      }
    }

    if (boundary == null || !boundary.isValid) {
      state = state.copyWith(gpsError: 'please_trace_boundary');
      return false;
    }

    final confirmed = boundary.copyWith(isConfirmed: true);
    final boundaryService = ref.read(farmBoundaryServiceProvider);
    await boundaryService.saveBoundary(confirmed);

    state = state.copyWith(
      activeBoundary: confirmed,
      boundary: confirmed.points,
      latitude: confirmed.centroid.latitude,
      longitude: confirmed.centroid.longitude,
      mapMode: FarmMapMode.saved,
      temporaryDrawingPoints: const [],
      gpsError: null,
    );

    // Synchronize confirmedLocationProvider
    ref.read(confirmedLocationProvider.notifier).state = state;
    return true;
  }

  /// Sets and saves an externally confirmed boundary (from FarmBoundaryMap).
  Future<void> setConfirmedBoundary(FarmBoundary boundary) async {
    final confirmed = boundary.copyWith(isConfirmed: true);
    final boundaryService = ref.read(farmBoundaryServiceProvider);
    await boundaryService.saveBoundary(confirmed);

    state = state.copyWith(
      activeBoundary: confirmed,
      boundary: confirmed.points,
      latitude: confirmed.centroid.latitude,
      longitude: confirmed.centroid.longitude,
      mapMode: FarmMapMode.saved,
      temporaryDrawingPoints: const [],
      gpsError: null,
    );

    ref.read(confirmedLocationProvider.notifier).state = state;
  }

  /// Re-enters Drawing Mode to redraw the boundary from scratch.
  void redrawBoundary() {
    state = state.copyWith(
      mapMode: FarmMapMode.drawing,
      clearActiveBoundary: true,
      boundary: const [],
      temporaryDrawingPoints: const [],
      gpsError: null,
    );
  }

  /// Clears active drawing: removes drawing points and returns to a clean map.
  void clearDrawing() {
    if (state.temporaryDrawingPoints.isNotEmpty) {
      state = state.copyWith(
        temporaryDrawingPoints: const [],
        gpsError: null,
      );
    } else {
      state = state.copyWith(
        temporaryDrawingPoints: const [],
        mapMode: state.activeBoundary != null ? FarmMapMode.saved : FarmMapMode.normal,
        gpsError: null,
      );
    }
  }

  /// Sets map mode explicitly
  void setMapMode(FarmMapMode mode) {
    state = state.copyWith(mapMode: mode);
  }

  // --- Legacy / Compatibility Helpers for Existing Components ---

  void addBoundaryPoint(LatLng point) {
    final updatedBoundary = List<LatLng>.from(state.boundary)..add(point);
    double newLat = state.latitude;
    double newLng = state.longitude;
    if (updatedBoundary.isNotEmpty) {
      double latSum = 0;
      double lngSum = 0;
      for (final pt in updatedBoundary) {
        latSum += pt.latitude;
        lngSum += pt.longitude;
      }
      newLat = latSum / updatedBoundary.length;
      newLng = lngSum / updatedBoundary.length;
    }
    state = state.copyWith(
      boundary: updatedBoundary,
      latitude: newLat,
      longitude: newLng,
    );
  }

  void undoLastBoundaryPoint() {
    if (state.temporaryDrawingPoints.isNotEmpty) {
      final updated = List<LatLng>.from(state.temporaryDrawingPoints)..removeLast();
      state = state.copyWith(temporaryDrawingPoints: updated);
      return;
    }
    if (state.boundary.isEmpty) return;
    final updatedBoundary = List<LatLng>.from(state.boundary)..removeLast();
    double newLat = state.latitude;
    double newLng = state.longitude;
    if (updatedBoundary.isNotEmpty) {
      double latSum = 0;
      double lngSum = 0;
      for (final pt in updatedBoundary) {
        latSum += pt.latitude;
        lngSum += pt.longitude;
      }
      newLat = latSum / updatedBoundary.length;
      newLng = lngSum / updatedBoundary.length;
    }
    state = state.copyWith(
      boundary: updatedBoundary,
      latitude: newLat,
      longitude: newLng,
    );
  }

  void clearBoundary() {
    ref.read(farmBoundaryServiceProvider).clearSavedBoundary();
    state = state.copyWith(
      boundary: const [],
      clearActiveBoundary: true,
      temporaryDrawingPoints: const [],
      mapMode: FarmMapMode.normal,
    );
  }

  void setBoundary(List<LatLng> points) {
    if (points.length >= 3) {
      final b = FarmBoundary.fromPoints(points);
      state = state.copyWith(
        boundary: b.points,
        activeBoundary: b,
        latitude: b.centroid.latitude,
        longitude: b.centroid.longitude,
      );
    } else {
      state = state.copyWith(boundary: points);
    }
  }

  void toggleDrawing(bool drawing) {
    if (drawing) {
      startDrawing();
    } else {
      state = state.copyWith(
        mapMode: state.activeBoundary != null ? FarmMapMode.saved : FarmMapMode.normal,
      );
    }
  }

  void clearGpsError() {
    state = state.copyWith(gpsError: null);
  }

  /// Triggers device geolocation.
  Future<void> fetchDeviceLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    state = state.copyWith(isLocating: true, gpsError: null);

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(isLocating: false, gpsError: 'error_gps_unavailable');
        throw 'error_gps_unavailable';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(isLocating: false, gpsError: 'error_gps_denied');
          throw 'error_gps_denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(isLocating: false, gpsError: 'error_gps_denied');
        throw 'error_gps_denied';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        isLocating: false,
        gpsError: null,
      );
    } catch (e) {
      String err = 'error_generic';
      if (e == 'error_gps_unavailable' || e == 'error_gps_denied') {
        err = e.toString();
      }
      state = state.copyWith(isLocating: false, gpsError: err);
      rethrow;
    }
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationData>(() {
  return LocationNotifier();
});

final confirmedLocationProvider = StateProvider<LocationData>((ref) {
  return LocationData(
    latitude: 30.9009,
    longitude: 75.8573,
    boundary: const [],
    temporaryDrawingPoints: const [],
    mapMode: FarmMapMode.normal,
    isLocating: false,
  );
});
