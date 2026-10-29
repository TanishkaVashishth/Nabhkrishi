import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/drawing_state.dart';
import '../models/farm_boundary.dart';

/// Controller providing programmatic control over the [FarmBoundaryMap].
/// Allows parent widgets to clear boundaries, load existing boundaries,
/// animate the map camera, or inspect the current drawing state.
class FarmBoundaryController extends ChangeNotifier {
  DrawingState _state = DrawingState.idle;
  FarmBoundary? _boundary;
  bool _isSatellite = true;

  MapController? _mapController;

  /// Internal hook called by the widget to bind the internal [MapController].
  void attachMapController(MapController mapController) {
    _mapController = mapController;
  }

  /// Internal hook called by the widget to unbind the internal [MapController].
  void detachMapController() {
    _mapController = null;
  }

  /// The active drawing state.
  DrawingState get state => _state;

  /// The active farm boundary, or `null` if none drawn/loaded.
  FarmBoundary? get boundary => _boundary;

  /// Whether satellite imagery layer is currently active.
  bool get isSatellite => _isSatellite;

  /// Internal method to update state from within the widget.
  void updateInternalState({
    DrawingState? state,
    FarmBoundary? boundary,
    bool? isSatellite,
  }) {
    bool changed = false;
    if (state != null && state != _state) {
      _state = state;
      changed = true;
    }
    if (boundary != null && boundary != _boundary) {
      _boundary = boundary;
      changed = true;
    }
    if (isSatellite != null && isSatellite != _isSatellite) {
      _isSatellite = isSatellite;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Clears any currently drawn or loaded boundary and returns to [DrawingState.idle].
  void clear() {
    _boundary = null;
    _state = DrawingState.idle;
    notifyListeners();
  }

  /// Enters finger drawing mode.
  void startDrawing() {
    _boundary = null;
    _state = DrawingState.drawing;
    notifyListeners();
  }

  /// Loads an existing [FarmBoundary] onto the map and transitions to [DrawingState.reviewing].
  void loadBoundary(FarmBoundary boundary, {bool fitCamera = true}) {
    _boundary = boundary;
    _state = DrawingState.reviewing;
    notifyListeners();

    if (fitCamera && _mapController != null && boundary.points.length >= 3) {
      _fitBounds(boundary.points);
    }
  }

  /// Toggles satellite layer mode.
  void setSatelliteMode(bool enable) {
    if (_isSatellite != enable) {
      _isSatellite = enable;
      notifyListeners();
    }
  }

  /// Centers the camera on the specified [location].
  void moveTo(LatLng location, {double zoom = 16.0}) {
    _mapController?.move(location, zoom);
  }

  /// Fits the camera to contain all given [points].
  void fitPoints(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;
    _fitBounds(points);
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon));
    _mapController?.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48.0),
      ),
    );
  }
}
