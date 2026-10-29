import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Service for calculating true geodesic farm area and perimeter
/// on the WGS-84 Earth sphere directly from geographic coordinates.
class FarmAreaCalculator {
  const FarmAreaCalculator._();

  /// WGS-84 equatorial Earth radius in meters.
  static const double earthRadiusMeters = 6378137.0;

  /// Conversion factor: 1 Hectare = 10,000 square meters.
  static const double sqMetersPerHectare = 10000.0;

  /// Conversion factor: 1 International Acre = 4046.8564224 square meters.
  static const double sqMetersPerAcre = 4046.8564224;

  /// Computes the true geodesic surface area in square meters for a geographic polygon.
  ///
  /// Uses the spherical excess / surveyor's formula on the Earth sphere:
  /// Area = (R^2 / 2) * | Σ (λ_{i+1} - λ_{i-1}) * sin(φ_i) |
  ///
  /// Works directly on [LatLng] coordinates and is immune to map projection,
  /// zoom level, or screen resolution distortion.
  static double calculateAreaSqMeters(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    // Filter out redundant closing point if present
    final vertices = List<LatLng>.from(points);
    if (vertices.length > 3 &&
        _arePointsEqual(vertices.first, vertices.last)) {
      vertices.removeLast();
    }

    if (vertices.length < 3) return 0.0;

    double total = 0.0;
    final int count = vertices.length;

    for (int i = 0; i < count; i++) {
      final prev = vertices[(i - 1 + count) % count];
      final curr = vertices[i];
      final next = vertices[(i + 1) % count];

      final double phi = _degToRad(curr.latitude);
      double deltaLambda = _degToRad(next.longitude) - _degToRad(prev.longitude);

      // Normalize delta longitude to [-π, π] to handle antimeridian crossing
      while (deltaLambda > math.pi) {
        deltaLambda -= 2 * math.pi;
      }
      while (deltaLambda < -math.pi) {
        deltaLambda += 2 * math.pi;
      }

      total += deltaLambda * math.sin(phi);
    }

    final double area = (earthRadiusMeters * earthRadiusMeters * total.abs()) / 2.0;
    return area;
  }

  /// Computes the farm area in Acres from geographic polygon [points].
  static double calculateAreaAcres(List<LatLng> points) {
    final sqMeters = calculateAreaSqMeters(points);
    return sqMeters / sqMetersPerAcre;
  }

  /// Computes the farm area in Hectares from geographic polygon [points].
  static double calculateAreaHectares(List<LatLng> points) {
    final sqMeters = calculateAreaSqMeters(points);
    return sqMeters / sqMetersPerHectare;
  }

  /// Computes the perimeter of the closed polygon in meters using the Haversine formula.
  static double calculatePerimeterMeters(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    final vertices = List<LatLng>.from(points);
    if (vertices.length > 2 && !_arePointsEqual(vertices.first, vertices.last)) {
      vertices.add(vertices.first);
    }

    double totalPerimeter = 0.0;
    for (int i = 0; i < vertices.length - 1; i++) {
      totalPerimeter += distanceMeters(vertices[i], vertices[i + 1]);
    }

    return totalPerimeter;
  }

  /// Computes the great-circle distance between two [LatLng] coordinates using the Haversine formula.
  static double distanceMeters(LatLng p1, LatLng p2) {
    final double lat1Rad = _degToRad(p1.latitude);
    final double lon1Rad = _degToRad(p1.longitude);
    final double lat2Rad = _degToRad(p2.latitude);
    final double lon2Rad = _degToRad(p2.longitude);

    final double deltaLat = lat2Rad - lat1Rad;
    final double deltaLon = lon2Rad - lon1Rad;

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLon / 2) * math.sin(deltaLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    return earthRadiusMeters * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  static bool _arePointsEqual(LatLng a, LatLng b, {double epsilon = 1e-7}) {
    return (a.latitude - b.latitude).abs() < epsilon &&
        (a.longitude - b.longitude).abs() < epsilon;
  }
}
