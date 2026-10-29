import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nabhkrishi/features/location/farm_boundary_map.dart';

void main() {
  group('Reference FarmAreaCalculator Tests', () {
    test('Returns 0 for fewer than 3 points', () {
      expect(FarmAreaCalculator.calculateAreaSqMeters([]), 0.0);
      expect(FarmAreaCalculator.calculateAreaSqMeters([const LatLng(0, 0)]), 0.0);
      expect(
        FarmAreaCalculator.calculateAreaSqMeters([
          const LatLng(0, 0),
          const LatLng(1, 1),
        ]),
        0.0,
      );
    });

    test('Calculates area accurately for a 100m x 100m field at equator (1 Hectare)', () {
      // 100m at equator is approx 0.000898315 degrees
      const double delta = 0.000898315;
      final square = [
        const LatLng(0, 0),
        const LatLng(0, delta),
        const LatLng(delta, delta),
        const LatLng(delta, 0),
        const LatLng(0, 0),
      ];

      final double areaSqM = FarmAreaCalculator.calculateAreaSqMeters(square);
      final double areaHectares = FarmAreaCalculator.calculateAreaHectares(square);
      final double areaAcres = FarmAreaCalculator.calculateAreaAcres(square);

      // 100m x 100m = 10,000 m² ± 0.5% due to spherical geometry
      expect(areaSqM, closeTo(10000.0, 50.0));
      expect(areaHectares, closeTo(1.0, 0.01));
      expect(areaAcres, closeTo(2.471, 0.02));
    });

    test('Produces identical area whether unclosed or explicitly closed', () {
      final unclosed = [
        const LatLng(18.5204, 73.8567),
        const LatLng(18.5204, 73.8587),
        const LatLng(18.5224, 73.8587),
        const LatLng(18.5224, 73.8567),
      ];

      final closed = [
        ...unclosed,
        const LatLng(18.5204, 73.8567),
      ];

      final areaUnclosed = FarmAreaCalculator.calculateAreaSqMeters(unclosed);
      final areaClosed = FarmAreaCalculator.calculateAreaSqMeters(closed);

      expect(areaUnclosed, equals(areaClosed));
      expect(areaUnclosed, greaterThan(10000.0));
    });

    test('Calculates Haversine distance and perimeter correctly', () {
      const p1 = LatLng(0, 0);
      const p2 = LatLng(1.0, 0);

      final distance = FarmAreaCalculator.distanceMeters(p1, p2);
      expect(distance, closeTo(111319.5, 50.0));

      const double delta = 0.000898315;
      final square = [
        const LatLng(0, 0),
        const LatLng(0, delta),
        const LatLng(delta, delta),
        const LatLng(delta, 0),
      ];

      final perimeter = FarmAreaCalculator.calculatePerimeterMeters(square);
      expect(perimeter, closeTo(400.0, 5.0));
    });
  });

  group('Reference GeoJsonService Tests', () {
    final samplePoints = [
      const LatLng(20.5937, 78.9629),
      const LatLng(20.5937, 78.9649),
      const LatLng(20.5957, 78.9649),
      const LatLng(20.5957, 78.9629),
      const LatLng(20.5937, 78.9629),
    ];

    test('toGeoJson formats coordinates strictly as [longitude, latitude]', () {
      final boundary = FarmBoundary.fromPoints(
        samplePoints,
        metadata: {'farmerId': 'FK-101', 'crop': 'Wheat'},
      );

      final geoJson = GeoJsonService.toGeoJsonMap(boundary);

      expect(geoJson['type'], 'Feature');
      expect(geoJson['geometry']['type'], 'Polygon');

      final coordinatesRing = geoJson['geometry']['coordinates'][0] as List<dynamic>;
      expect(coordinatesRing.length, samplePoints.length);

      // Check first coordinate: MUST be [78.9629, 20.5937] ([longitude, latitude])
      final firstCoord = coordinatesRing[0] as List<dynamic>;
      expect(firstCoord[0], closeTo(78.9629, 0.0001)); // Longitude
      expect(firstCoord[1], closeTo(20.5937, 0.0001)); // Latitude

      // First and last coordinates must match (closed ring)
      final lastCoord = coordinatesRing.last as List<dynamic>;
      expect(firstCoord[0], lastCoord[0]);
      expect(firstCoord[1], lastCoord[1]);

      // Check properties
      final properties = geoJson['properties'] as Map<String, dynamic>;
      expect(properties['areaAcres'], greaterThan(0));
      expect(properties['areaHectares'], greaterThan(0));
      expect(properties['farmerId'], 'FK-101');
      expect(properties['crop'], 'Wheat');
    });

    test('Roundtrip serialization fromGeoJson reconstructs FarmBoundary accurately', () {
      final original = FarmBoundary.fromPoints(
        samplePoints,
        metadata: {'farmName': 'Green Acres'},
      );

      final geoJsonString = original.toGeoJsonString(pretty: true);
      final decodedMap = json.decode(geoJsonString) as Map<String, dynamic>;
      final reconstructed = FarmBoundary.fromGeoJson(decodedMap);

      expect(reconstructed.points.length, original.points.length);
      expect(reconstructed.points.first.latitude, closeTo(original.points.first.latitude, 1e-5));
      expect(reconstructed.points.first.longitude, closeTo(original.points.first.longitude, 1e-5));
      expect(reconstructed.areaAcres, closeTo(original.areaAcres, 0.01));
      expect(reconstructed.areaHectares, closeTo(original.areaHectares, 0.01));
      expect(reconstructed.metadata['farmName'], 'Green Acres');
    });
  });

  group('Reference PolygonUtils Tests', () {
    test('ensureClosed adds first point to end if missing', () {
      final points = [
        const LatLng(10, 20),
        const LatLng(10, 21),
        const LatLng(11, 21),
      ];

      final closed = PolygonUtils.ensureClosed(points);
      expect(closed.length, 4);
      expect(closed.first, closed.last);
    });

    test('ensureClosed does not duplicate when already closed', () {
      final points = [
        const LatLng(10, 20),
        const LatLng(10, 21),
        const LatLng(11, 21),
        const LatLng(10, 20),
      ];

      final closed = PolygonUtils.ensureClosed(points);
      expect(closed.length, 4);
    });

    test('removeDuplicates eliminates consecutive points within threshold', () {
      final points = [
        const LatLng(18.5204, 73.8567),
        const LatLng(18.52040001, 73.85670001),
        const LatLng(18.52040002, 73.85670002),
        const LatLng(18.52049, 73.8567),
      ];

      final cleaned = PolygonUtils.removeDuplicates(points, minDistanceMeters: 2.0);
      expect(cleaned.length, 2);
    });

    test('simplifyRdp reduces collinear intermediate points while keeping vertices', () {
      final List<LatLng> points = [
        const LatLng(0, 0),
      ];

      for (double lat = 0.0001; lat < 0.001; lat += 0.0001) {
        points.add(LatLng(lat, 0));
      }
      points.add(const LatLng(0.001, 0));
      points.add(const LatLng(0.001, 0.001));
      points.add(const LatLng(0, 0.001));
      points.add(const LatLng(0, 0));

      final simplified = PolygonUtils.simplifyRdp(points, epsilonMeters: 1.0);
      expect(simplified.length, lessThan(points.length));
      expect(simplified.first, simplified.last);
    });

    test('validatePolygon rejects empty, tiny, or self-intersecting polygons', () {
      expect(PolygonUtils.validatePolygon([]).isValid, isFalse);

      expect(
        PolygonUtils.validatePolygon([
          const LatLng(10, 10),
          const LatLng(10, 11),
        ]).isValid,
        isFalse,
      );

      // Self-intersecting bowtie loop
      final bowtie = [
        const LatLng(18.520, 73.850),
        const LatLng(18.522, 73.852),
        const LatLng(18.522, 73.850),
        const LatLng(18.520, 73.852),
        const LatLng(18.520, 73.850),
      ];
      final bowtieValidation = PolygonUtils.validatePolygon(bowtie);
      expect(bowtieValidation.isValid, isFalse);
      expect(bowtieValidation.hasSelfIntersection, isTrue);

      // Valid regular field
      final validField = [
        const LatLng(18.520, 73.850),
        const LatLng(18.520, 73.852),
        const LatLng(18.522, 73.852),
        const LatLng(18.522, 73.850),
        const LatLng(18.520, 73.850),
      ];
      expect(PolygonUtils.validatePolygon(validField).isValid, isTrue);
    });
  });

  group('Reference FarmBoundaryMap Widget Tests', () {
    final sampleBoundary = FarmBoundary.fromPoints([
      const LatLng(20.5937, 78.9629),
      const LatLng(20.5937, 78.9649),
      const LatLng(20.5957, 78.9649),
      const LatLng(20.5957, 78.9629),
    ]);

    testWidgets('Renders properly embedded inside a SizedBox without owning the screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 500,
                child: FarmBoundaryMap(
                  initialLocation: const LatLng(20.5937, 78.9629),
                  onBoundaryConfirmed: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Draw Farm Boundary'), findsOneWidget);
      expect(find.byType(FarmBoundaryMap), findsOneWidget);
      expect(find.byType(MapControls), findsOneWidget);
    });

    testWidgets('Tapping Draw Farm Boundary transitions to drawing mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 600,
              child: FarmBoundaryMap(
                initialLocation: const LatLng(20.5937, 78.9629),
                onBoundaryConfirmed: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Draw Farm Boundary'), findsOneWidget);

      await tester.tap(find.text('Draw Farm Boundary'));
      await tester.pumpAndSettle();

      expect(find.text('Trace around your farm boundary'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('Loads initialBoundary in reviewing state and confirms on tap', (tester) async {
      FarmBoundary? confirmedBoundary;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 600,
              child: FarmBoundaryMap(
                initialBoundary: sampleBoundary,
                onBoundaryConfirmed: (boundary) {
                  confirmedBoundary = boundary;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Confirm Farm'), findsOneWidget);
      expect(find.text('Redraw'), findsOneWidget);
      expect(find.textContaining('Acres'), findsOneWidget);

      await tester.tap(find.text('Confirm Farm'));
      await tester.pumpAndSettle();

      expect(confirmedBoundary, isNotNull);
      expect(confirmedBoundary!.points.length, sampleBoundary.points.length);
      expect(confirmedBoundary!.areaAcres, closeTo(sampleBoundary.areaAcres, 0.001));
    });
  });
}
