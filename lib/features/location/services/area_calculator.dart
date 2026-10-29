import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Geodesic geographic area calculator for polygon boundaries on the Earth's surface.
/// Uses the spherical excess surveyor's formula on ellipsoidal coordinates
/// rather than planar screen pixels.
class AreaCalculator {
  static const double earthRadiusMeters = 6378137.0; // WGS84 mean equatorial radius
  static const double squareMetersPerAcre = 4046.8564224;
  static const double squareMetersPerHectare = 10000.0;

  /// Calculates geodesic polygon area in square meters.
  /// Points can be clockwise or counter-clockwise; returns absolute area.
  static double calculateAreaSquareMeters(List<LatLng> polygonPoints) {
    if (polygonPoints.length < 3) return 0.0;

    // Remove consecutive duplicates or closing point if duplicated at the end
    final List<LatLng> cleanPoints = [];
    for (int i = 0; i < polygonPoints.length; i++) {
      final current = polygonPoints[i];
      if (cleanPoints.isEmpty) {
        cleanPoints.add(current);
      } else {
        final last = cleanPoints.last;
        if (current.latitude != last.latitude || current.longitude != last.longitude) {
          // If the point is identical to first point and is at the end, don't duplicate
          if (i == polygonPoints.length - 1 &&
              current.latitude == cleanPoints.first.latitude &&
              current.longitude == cleanPoints.first.longitude) {
            continue;
          }
          cleanPoints.add(current);
        }
      }
    }

    if (cleanPoints.length < 3) return 0.0;

    double total = 0.0;
    final int n = cleanPoints.length;

    for (int i = 0; i < n; i++) {
      final pPrev = cleanPoints[(i - 1 + n) % n];
      final pCurr = cleanPoints[i];
      final pNext = cleanPoints[(i + 1) % n];

      final lambdaPrev = pPrev.longitude * math.pi / 180.0;
      final lambdaNext = pNext.longitude * math.pi / 180.0;
      final phiCurr = pCurr.latitude * math.pi / 180.0;

      total += (lambdaNext - lambdaPrev) * math.sin(phiCurr);
    }

    final double areaSquareMeters = (total.abs() * earthRadiusMeters * earthRadiusMeters) / 2.0;
    return areaSquareMeters;
  }

  /// Calculates geodesic area in Acres.
  static double calculateAreaAcres(List<LatLng> polygonPoints) {
    final sqMeters = calculateAreaSquareMeters(polygonPoints);
    return sqMeters / squareMetersPerAcre;
  }

  /// Calculates geodesic area in Hectares.
  static double calculateAreaHectares(List<LatLng> polygonPoints) {
    final sqMeters = calculateAreaSquareMeters(polygonPoints);
    return sqMeters / squareMetersPerHectare;
  }

  /// Format area in acres with specified decimal places (defaults to 2).
  static String formatAcres(double acres, {int decimals = 2}) {
    return acres.toStringAsFixed(decimals);
  }

  /// Format area in hectares with specified decimal places (defaults to 2).
  static String formatHectares(double hectares, {int decimals = 2}) {
    return hectares.toStringAsFixed(decimals);
  }
}
