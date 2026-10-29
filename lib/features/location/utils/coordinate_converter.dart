import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Helper for converting between screen pixel offsets and geographic coordinates
/// using the [MapCamera] projection matrix.
class CoordinateConverter {
  const CoordinateConverter._();

  /// Converts a screen [Offset] (relative to the map widget) to geographic [LatLng].
  static LatLng screenOffsetToLatLng(Offset offset, MapCamera camera) {
    return camera.screenOffsetToLatLng(offset);
  }

  /// Converts a geographic [LatLng] to screen [Offset] (relative to the map widget).
  static Offset latLngToScreenOffset(LatLng latLng, MapCamera camera) {
    return camera.latLngToScreenOffset(latLng);
  }

  /// Converts a list of geographic [LatLng] points to screen [Offset]s.
  static List<Offset> latLngListToScreenOffsets(List<LatLng> points, MapCamera camera) {
    return points.map((p) => latLngToScreenOffset(p, camera)).toList();
  }
}
