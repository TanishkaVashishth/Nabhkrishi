import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../services/farm_area_calculator.dart';
import '../services/geojson_service.dart';
import '../utils/polygon_utils.dart';

/// Represents a validated geographic farm boundary with accurate
/// real-world area (Acres & Hectares) and perimeter calculations.
@immutable
class FarmBoundary {
  /// Ordered list of closed geographic coordinates forming the outer boundary.
  /// First and last points are identical.
  final List<LatLng> points;

  /// Calculated farm area in international acres.
  final double areaAcres;

  /// Calculated farm area in hectares.
  final double areaHectares;

  /// Calculated farm area in square meters.
  final double areaSqMeters;

  /// Total perimeter length of the farm boundary in meters.
  final double perimeterMeters;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Whether this boundary has been officially confirmed by the farmer.
  final bool isConfirmed;

  /// Optional parent application metadata (e.g. farmName, cropType, notes).
  final Map<String, dynamic> metadata;

  const FarmBoundary({
    required this.points,
    required this.areaAcres,
    required this.areaHectares,
    required this.areaSqMeters,
    required this.perimeterMeters,
    required this.createdAt,
    this.isConfirmed = false,
    this.metadata = const {},
  });

  /// Factory constructor that automatically ensures polygon closure and
  /// calculates geodesic area and perimeter from raw [points].
  factory FarmBoundary.fromPoints(
    List<LatLng> points, {
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    bool isConfirmed = false,
  }) {
    final closed = PolygonUtils.ensureClosed(points);
    final sqMeters = FarmAreaCalculator.calculateAreaSqMeters(closed);
    final acres = FarmAreaCalculator.calculateAreaAcres(closed);
    final hectares = FarmAreaCalculator.calculateAreaHectares(closed);
    final perimeter = FarmAreaCalculator.calculatePerimeterMeters(closed);

    return FarmBoundary(
      points: List.unmodifiable(closed),
      areaAcres: acres,
      areaHectares: hectares,
      areaSqMeters: sqMeters,
      perimeterMeters: perimeter,
      createdAt: createdAt ?? DateTime.now(),
      isConfirmed: isConfirmed,
      metadata: metadata != null ? Map.unmodifiable(metadata) : const {},
    );
  }

  /// Backward-compatible simplification helper using RDP algorithm.
  static List<LatLng> simplifyPoints(List<LatLng> points, {double epsilon = 0.000018}) {
    return PolygonUtils.simplifyRdp(points, epsilonMeters: epsilon * 111320.0);
  }

  /// Reconstructs a [FarmBoundary] from an RFC 7946 GeoJSON [Map].
  factory FarmBoundary.fromGeoJson(Map<String, dynamic> json) {
    return GeoJsonService.fromGeoJson(json);
  }

  /// Parses a [FarmBoundary] from a GeoJSON [String].
  factory FarmBoundary.fromGeoJsonString(String jsonString) {
    final decoded = json.decode(jsonString) as Map<String, dynamic>;
    return FarmBoundary.fromGeoJson(decoded);
  }

  /// Converts this boundary to an RFC 7946 compliant GeoJSON Feature [Map].
  /// Coordinates are strictly formatted as `[longitude, latitude]`.
  Map<String, dynamic> toGeoJson() {
    return GeoJsonService.toGeoJsonMap(this);
  }

  /// Encodes this boundary to an RFC 7946 GeoJSON [String].
  String toGeoJsonString({bool pretty = false}) {
    return GeoJsonService.toGeoJsonString(this, pretty: pretty);
  }

  /// Geographic center (centroid) of the boundary.
  LatLng get center => PolygonUtils.computeCentroid(points);

  /// Backward-compatible alias for centroid.
  LatLng get centroid => center;

  /// Number of coordinate vertices.
  int get vertexCount => points.length;

  /// Whether this boundary has valid geometry (at least 3 coordinates).
  bool get isValid => points.length >= 3;

  /// Formatted area string for UI display (e.g. "2.45 Acres (0.99 Ha)").
  String get formattedArea {
    return '${areaAcres.toStringAsFixed(2)} Acres (${areaHectares.toStringAsFixed(2)} Ha)';
  }

  /// Converts to standard Map representation for generic serialization.
  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'areaAcres': areaAcres,
      'areaHectares': areaHectares,
      'areaSqMeters': areaSqMeters,
      'perimeterMeters': perimeterMeters,
      'createdAt': createdAt.toIso8601String(),
      'isConfirmed': isConfirmed,
      'metadata': metadata,
    };
  }

  /// Constructs from standard Map representation.
  factory FarmBoundary.fromMap(Map<String, dynamic> map) {
    final rawPoints = (map['points'] as List<dynamic>).map((item) {
      final p = item as Map<String, dynamic>;
      return LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble());
    }).toList();

    return FarmBoundary(
      points: List.unmodifiable(rawPoints),
      areaAcres: (map['areaAcres'] as num).toDouble(),
      areaHectares: (map['areaHectares'] as num).toDouble(),
      areaSqMeters: (map['areaSqMeters'] as num?)?.toDouble() ?? 0.0,
      perimeterMeters: (map['perimeterMeters'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isConfirmed: map['isConfirmed'] as bool? ?? false,
      metadata: map['metadata'] != null
          ? Map.unmodifiable(map['metadata'] as Map<String, dynamic>)
          : const {},
    );
  }

  FarmBoundary copyWith({
    List<LatLng>? points,
    double? areaAcres,
    double? areaHectares,
    double? areaSqMeters,
    double? perimeterMeters,
    DateTime? createdAt,
    bool? isConfirmed,
    Map<String, dynamic>? metadata,
  }) {
    return FarmBoundary(
      points: points != null ? List.unmodifiable(points) : this.points,
      areaAcres: areaAcres ?? this.areaAcres,
      areaHectares: areaHectares ?? this.areaHectares,
      areaSqMeters: areaSqMeters ?? this.areaSqMeters,
      perimeterMeters: perimeterMeters ?? this.perimeterMeters,
      createdAt: createdAt ?? this.createdAt,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      metadata: metadata != null ? Map.unmodifiable(metadata) : this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FarmBoundary &&
        listEquals(other.points, points) &&
        other.areaAcres == areaAcres &&
        other.areaHectares == areaHectares &&
        other.areaSqMeters == areaSqMeters &&
        other.perimeterMeters == perimeterMeters &&
        other.createdAt == createdAt &&
        other.isConfirmed == isConfirmed &&
        mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(points),
        areaAcres,
        areaHectares,
        areaSqMeters,
        perimeterMeters,
        createdAt,
        isConfirmed,
        Object.hashAll(metadata.entries),
      );

  @override
  String toString() {
    return 'FarmBoundary(vertices: ${points.length}, area: $formattedArea, perimeter: ${perimeterMeters.toStringAsFixed(1)}m)';
  }
}
