import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../services/farm_area_calculator.dart';

/// Result of polygon geometric validation.
class PolygonValidationResult {
  final bool isValid;
  final String? errorMessage;
  final bool hasSelfIntersection;

  const PolygonValidationResult({
    required this.isValid,
    this.errorMessage,
    this.hasSelfIntersection = false,
  });

  static const valid = PolygonValidationResult(isValid: true);
}

/// Utilities for processing, simplifying, smoothing, and validating geographic farm polygons.
class PolygonUtils {
  const PolygonUtils._();

  /// Removes consecutive points that are closer than [minDistanceMeters]
  /// to eliminate touch jitter and point bloat from slow finger dragging.
  static List<LatLng> removeDuplicates(
    List<LatLng> points, {
    double minDistanceMeters = 1.5,
  }) {
    if (points.length <= 1) return List<LatLng>.from(points);

    final List<LatLng> cleaned = [points.first];
    for (int i = 1; i < points.length; i++) {
      final double dist = FarmAreaCalculator.distanceMeters(cleaned.last, points[i]);
      if (dist >= minDistanceMeters) {
        cleaned.add(points[i]);
      }
    }

    // Retain the last point if it was dropped but needed to preserve the terminal point
    if (cleaned.length > 1 &&
        FarmAreaCalculator.distanceMeters(cleaned.last, points.last) >= minDistanceMeters / 2) {
      cleaned.add(points.last);
    }

    return cleaned;
  }

  /// Ensures that the polygon's first and last coordinate are identical, closing the ring.
  static List<LatLng> ensureClosed(List<LatLng> points) {
    if (points.isEmpty) return [];
    final list = List<LatLng>.from(points);
    if (!_arePointsEqual(list.first, list.last)) {
      list.add(list.first);
    }
    return list;
  }

  /// Simplifies a geographic polygon using the Ramer-Douglas-Peucker (RDP) algorithm.
  ///
  /// [epsilonMeters] controls the tolerance threshold in meters.
  /// A value of ~1.0 - 2.0 meters removes finger tremor without altering the farmer's
  /// intentional field shape.
  static List<LatLng> simplifyRdp(
    List<LatLng> points, {
    double epsilonMeters = 1.2,
  }) {
    if (points.length <= 2) return List<LatLng>.from(points);

    final bool isClosed = _arePointsEqual(points.first, points.last);
    final workingPoints = isClosed ? points.sublist(0, points.length - 1) : List<LatLng>.from(points);

    if (workingPoints.length <= 2) {
      return isClosed ? ensureClosed(workingPoints) : workingPoints;
    }

    // Project points to local Cartesian meters around centroid for high-precision RDP
    final LatLng ref = computeCentroid(workingPoints);
    final List<_Point2D> projected = workingPoints
        .map((p) => _projectToMeters(p, ref))
        .toList();

    final simplifiedIndices = _rdpRecursive(projected, 0, projected.length - 1, epsilonMeters);
    final List<LatLng> result = simplifiedIndices.map((idx) => workingPoints[idx]).toList();

    return isClosed ? ensureClosed(result) : result;
  }

  /// Full processing pipeline for drawn finger input:
  /// 1. Removes micro-jitter and duplicate points.
  /// 2. Simplifies path using Ramer-Douglas-Peucker.
  /// 3. Ensures closed outer ring.
  static List<LatLng> processDrawnPoints(
    List<LatLng> points, {
    double minDistanceMeters = 1.5,
    double epsilonMeters = 1.2,
  }) {
    if (points.length < 3) return points;

    // 1. Remove duplicates / high-frequency jitter
    final deduplicated = removeDuplicates(points, minDistanceMeters: minDistanceMeters);
    if (deduplicated.length < 3) return deduplicated;

    // 2. Ensure closed ring
    final closed = ensureClosed(deduplicated);

    // 3. Simplify with RDP
    final simplified = simplifyRdp(closed, epsilonMeters: epsilonMeters);

    return ensureClosed(simplified);
  }

  /// Validates whether a list of points forms a legitimate farm boundary.
  static PolygonValidationResult validatePolygon(
    List<LatLng> points, {
    double minAreaSqMeters = 10.0,
  }) {
    if (points.isEmpty) {
      return const PolygonValidationResult(
        isValid: false,
        errorMessage: 'Boundary has no points.',
      );
    }

    final uniquePoints = List<LatLng>.from(points);
    if (uniquePoints.length > 2 && _arePointsEqual(uniquePoints.first, uniquePoints.last)) {
      uniquePoints.removeLast();
    }

    if (uniquePoints.length < 3) {
      return const PolygonValidationResult(
        isValid: false,
        errorMessage: 'A farm boundary must have at least 3 distinct corner points.',
      );
    }

    // Check for self-intersections (twisted/bowtie loops) FIRST
    // because twisted loops cause area cancellation in Green's theorem.
    if (_hasSelfIntersection(uniquePoints)) {
      return const PolygonValidationResult(
        isValid: false,
        errorMessage: 'Boundary lines cross over each other. Please trace a single continuous outline.',
        hasSelfIntersection: true,
      );
    }

    final area = FarmAreaCalculator.calculateAreaSqMeters(points);
    if (area < minAreaSqMeters) {
      return PolygonValidationResult(
        isValid: false,
        errorMessage: 'Enclosed area is too small (${area.toStringAsFixed(1)} m²). Please trace around the entire field.',
      );
    }

    return PolygonValidationResult.valid;
  }

  /// Computes the geographic center (centroid) of the polygon vertices.
  static LatLng computeCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);

    double sumLat = 0.0;
    double sumLon = 0.0;
    int count = 0;

    for (final p in points) {
      sumLat += p.latitude;
      sumLon += p.longitude;
      count++;
    }

    return LatLng(sumLat / count, sumLon / count);
  }

  // --- Internal Helpers ---

  static List<int> _rdpRecursive(
    List<_Point2D> pts,
    int start,
    int end,
    double epsilon,
  ) {
    double maxDistance = 0.0;
    int index = start;

    for (int i = start + 1; i < end; i++) {
      final double distance = _perpendicularDistance(pts[i], pts[start], pts[end]);
      if (distance > maxDistance) {
        maxDistance = distance;
        index = i;
      }
    }

    if (maxDistance > epsilon) {
      final left = _rdpRecursive(pts, start, index, epsilon);
      final right = _rdpRecursive(pts, index, end, epsilon);
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [start, end];
    }
  }

  static double _perpendicularDistance(_Point2D p, _Point2D a, _Point2D b) {
    final double dx = b.x - a.x;
    final double dy = b.y - a.y;
    final double segmentLengthSq = dx * dx + dy * dy;

    if (segmentLengthSq == 0) {
      final double px = p.x - a.x;
      final double py = p.y - a.y;
      return math.sqrt(px * px + py * py);
    }

    final double t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / segmentLengthSq;
    final double clampedT = t.clamp(0.0, 1.0);

    final double projX = a.x + clampedT * dx;
    final double projY = a.y + clampedT * dy;

    final double diffX = p.x - projX;
    final double diffY = p.y - projY;

    return math.sqrt(diffX * diffX + diffY * diffY);
  }

  static _Point2D _projectToMeters(LatLng p, LatLng ref) {
    const double radius = FarmAreaCalculator.earthRadiusMeters;
    final double latRad = p.latitude * (math.pi / 180.0);
    final double refLatRad = ref.latitude * (math.pi / 180.0);
    final double lonRad = p.longitude * (math.pi / 180.0);
    final double refLonRad = ref.longitude * (math.pi / 180.0);

    final double x = radius * (lonRad - refLonRad) * math.cos(refLatRad);
    final double y = radius * (latRad - refLatRad);

    return _Point2D(x, y);
  }

  static bool _hasSelfIntersection(List<LatLng> pts) {
    final int n = pts.length;
    if (n < 4) return false;

    // Convert to local 2D projection
    final ref = pts[0];
    final List<_Point2D> projected = pts.map((p) => _projectToMeters(p, ref)).toList();

    for (int i = 0; i < n; i++) {
      final p1 = projected[i];
      final p2 = projected[(i + 1) % n];

      // Test against other non-adjacent edges
      for (int j = i + 2; j < n; j++) {
        if (i == 0 && j == n - 1) continue; // adjacent in closed loop

        final p3 = projected[j];
        final p4 = projected[(j + 1) % n];

        if (_segmentsIntersect(p1, p2, p3, p4)) {
          return true;
        }
      }
    }

    return false;
  }

  static bool _segmentsIntersect(_Point2D a, _Point2D b, _Point2D c, _Point2D d) {
    final double d1 = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    final double d2 = (b.x - a.x) * (d.y - a.y) - (b.y - a.y) * (d.x - a.x);
    final double d3 = (d.x - c.x) * (a.y - c.y) - (d.y - c.y) * (a.x - c.x);
    final double d4 = (d.x - c.x) * (b.y - c.y) - (d.y - c.y) * (b.x - c.x);

    // Strict crossing test: C and D are on opposite sides of AB,
    // AND A and B are on opposite sides of CD.
    return (d1 * d2 < -1e-9) && (d3 * d4 < -1e-9);
  }

  static bool _arePointsEqual(LatLng a, LatLng b, {double epsilon = 1e-7}) {
    return (a.latitude - b.latitude).abs() < epsilon &&
        (a.longitude - b.longitude).abs() < epsilon;
  }
}

class _Point2D {
  final double x;
  final double y;
  const _Point2D(this.x, this.y);
}
