import 'dart:convert';
import 'package:latlong2/latlong.dart';
import '../models/farm_boundary.dart';
import '../utils/polygon_utils.dart';
import 'farm_area_calculator.dart';

/// RFC 7946 compliant GeoJSON serialization and deserialization service
/// for farm boundaries.
///
/// CRITICAL: In GeoJSON, coordinates are ordered [longitude, latitude],
/// never [latitude, longitude]. Rings must also be closed (first == last).
class GeoJsonService {
  const GeoJsonService._();

  /// Converts a [FarmBoundary] into an RFC 7946 GeoJSON Feature Map.
  static Map<String, dynamic> toGeoJsonMap(FarmBoundary boundary) {
    final closedPoints = PolygonUtils.ensureClosed(boundary.points);

    // RFC 7946 specifies coordinates as [longitude, latitude]
    final coordinatesRing = closedPoints
        .map((p) => [
              _roundCoordinate(p.longitude),
              _roundCoordinate(p.latitude),
            ])
        .toList();

    final properties = <String, dynamic>{
      'area': double.parse(boundary.areaAcres.toStringAsFixed(2)),
      'areaUnit': 'acres',
      'areaAcres': double.parse(boundary.areaAcres.toStringAsFixed(4)),
      'areaHectares': double.parse(boundary.areaHectares.toStringAsFixed(4)),
      'areaSqMeters': double.parse(boundary.areaSqMeters.toStringAsFixed(2)),
      'perimeterMeters': double.parse(boundary.perimeterMeters.toStringAsFixed(2)),
      'vertexCount': closedPoints.length,
      'createdAt': boundary.createdAt.toIso8601String(),
      'isConfirmed': boundary.isConfirmed,
      ...boundary.metadata,
    };

    return {
      'type': 'Feature',
      'properties': properties,
      'geometry': {
        'type': 'Polygon',
        'coordinates': [coordinatesRing],
      },
    };
  }

  /// Alias for backward compatibility with existing callers.
  static Map<String, dynamic> toGeoJson(FarmBoundary boundary) => toGeoJsonMap(boundary);

  /// Converts a [FarmBoundary] into a JSON string.
  static String toGeoJsonString(FarmBoundary boundary, {bool pretty = false}) {
    final map = toGeoJsonMap(boundary);
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return json.encode(map);
  }

  /// Parses a GeoJSON string into a [FarmBoundary].
  static FarmBoundary fromGeoJsonString(String jsonString) {
    final decoded = json.decode(jsonString) as Map<String, dynamic>;
    return fromGeoJson(decoded);
  }

  /// Checks whether a GeoJSON map structure is valid according to RFC 7946.
  static bool isValidGeoJson(Map<String, dynamic> json) {
    try {
      final type = json['type'];
      Map<String, dynamic>? geometry;
      if (type == 'Feature') {
        geometry = json['geometry'] as Map<String, dynamic>?;
      } else if (type == 'Polygon') {
        geometry = json;
      }
      if (geometry == null || geometry['type'] != 'Polygon') return false;
      final coords = geometry['coordinates'] as List<dynamic>?;
      if (coords == null || coords.isEmpty) return false;
      final ring = coords[0] as List<dynamic>?;
      if (ring == null || ring.length < 4) return false;
      final first = ring.first as List<dynamic>;
      final last = ring.last as List<dynamic>;
      if (first[0] != last[0] || first[1] != last[1]) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Parses an RFC 7946 GeoJSON [Map] into a [FarmBoundary].
  /// Supports both GeoJSON Feature and direct Geometry (Polygon) objects.
  static FarmBoundary fromGeoJson(Map<String, dynamic> jsonMap) {
    Map<String, dynamic> geometry;
    Map<String, dynamic> properties = {};

    final String type = jsonMap['type'] as String? ?? '';

    if (type == 'Feature') {
      geometry = (jsonMap['geometry'] as Map<String, dynamic>?) ?? {};
      properties = (jsonMap['properties'] as Map<String, dynamic>?) ?? {};
    } else if (type == 'Polygon') {
      geometry = jsonMap;
      properties = {};
    } else {
      throw FormatException('Unsupported GeoJSON type: "$type". Expected "Feature" or "Polygon".');
    }

    final String geomType = geometry['type'] as String? ?? '';
    if (geomType != 'Polygon') {
      throw FormatException('Unsupported geometry type: "$geomType". Expected "Polygon".');
    }

    final rawCoordinates = geometry['coordinates'] as List<dynamic>?;
    if (rawCoordinates == null || rawCoordinates.isEmpty) {
      throw const FormatException('GeoJSON Polygon has no coordinates ring.');
    }

    final outerRing = rawCoordinates[0] as List<dynamic>;
    if (outerRing.isEmpty) {
      throw const FormatException('Outer coordinates ring is empty.');
    }

    final List<LatLng> points = [];
    for (final coord in outerRing) {
      final list = coord as List<dynamic>;
      if (list.length < 2) {
        throw const FormatException('Invalid coordinate pair. Must contain at least [lon, lat].');
      }
      final double lon = (list[0] as num).toDouble();
      final double lat = (list[1] as num).toDouble();
      points.add(LatLng(lat, lon));
    }

    final closed = PolygonUtils.ensureClosed(points);

    // Extract precomputed properties or calculate anew
    final double areaSqMeters = properties['areaSqMeters'] != null
        ? (properties['areaSqMeters'] as num).toDouble()
        : FarmAreaCalculator.calculateAreaSqMeters(closed);

    final double areaAcres = properties['areaAcres'] != null
        ? (properties['areaAcres'] as num).toDouble()
        : (properties['area'] != null
            ? (properties['area'] as num).toDouble()
            : FarmAreaCalculator.calculateAreaAcres(closed));

    final double areaHectares = properties['areaHectares'] != null
        ? (properties['areaHectares'] as num).toDouble()
        : FarmAreaCalculator.calculateAreaHectares(closed);

    final double perimeterMeters = properties['perimeterMeters'] != null
        ? (properties['perimeterMeters'] as num).toDouble()
        : FarmAreaCalculator.calculatePerimeterMeters(closed);

    final bool isConfirmed = properties['isConfirmed'] as bool? ?? false;

    DateTime createdAt;
    if (properties['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(properties['createdAt'] as String);
      } catch (_) {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    // Filter out standard keys to preserve custom metadata
    final metadata = Map<String, dynamic>.from(properties)
      ..remove('area')
      ..remove('areaUnit')
      ..remove('areaAcres')
      ..remove('areaHectares')
      ..remove('areaSqMeters')
      ..remove('perimeterMeters')
      ..remove('vertexCount')
      ..remove('pointCount')
      ..remove('isConfirmed')
      ..remove('createdAt');

    return FarmBoundary(
      points: List.unmodifiable(closed),
      areaAcres: areaAcres,
      areaHectares: areaHectares,
      areaSqMeters: areaSqMeters,
      perimeterMeters: perimeterMeters,
      createdAt: createdAt,
      isConfirmed: isConfirmed,
      metadata: Map.unmodifiable(metadata),
    );
  }

  /// Rounds coordinates to 7 decimal places (~1.1 cm precision) to prevent floating-point bloat.
  static double _roundCoordinate(double val) {
    return double.parse(val.toStringAsFixed(7));
  }
}
