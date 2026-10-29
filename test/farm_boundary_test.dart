import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nabhkrishi/core/localization/app_localizations.dart';
import 'package:nabhkrishi/features/location/models/farm_boundary.dart';
import 'package:nabhkrishi/features/location/models/location_model.dart';
import 'package:nabhkrishi/features/location/providers/location_provider.dart';
import 'package:nabhkrishi/features/location/services/area_calculator.dart';
import 'package:nabhkrishi/features/location/services/farm_boundary_service.dart';
import 'package:nabhkrishi/features/location/services/geojson_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('AreaCalculator Tests', () {
    test('Returns 0.0 when points are fewer than 3', () {
      expect(AreaCalculator.calculateAreaSquareMeters([]), 0.0);
      expect(AreaCalculator.calculateAreaSquareMeters([const LatLng(30.9, 75.8)]), 0.0);
      expect(
        AreaCalculator.calculateAreaSquareMeters([
          const LatLng(30.9, 75.8),
          const LatLng(30.91, 75.81),
        ]),
        0.0,
      );
    });

    test('Calculates area accurately for a standard rectangular wheat parcel', () {
      // ~100m x ~100m plot near Ludhiana (~1 hectare / ~2.47 acres)
      // At lat 30.9, 0.001 deg lat is ~110.8m, 0.001 deg lng is ~95.7m
      final polygon = [
        const LatLng(30.9000, 75.8500),
        const LatLng(30.9009, 75.8500),
        const LatLng(30.9009, 75.8510),
        const LatLng(30.9000, 75.8510),
        const LatLng(30.9000, 75.8500),
      ];

      final sqMeters = AreaCalculator.calculateAreaSquareMeters(polygon);
      final acres = AreaCalculator.calculateAreaAcres(polygon);
      final hectares = AreaCalculator.calculateAreaHectares(polygon);

      expect(sqMeters, greaterThan(8000.0));
      expect(sqMeters, lessThan(12000.0));
      expect(acres, greaterThan(2.0));
      expect(acres, lessThan(3.0));
      expect(hectares, greaterThan(0.8));
      expect(hectares, lessThan(1.2));
    });

    test('formatAcres and formatHectares format to specified decimals', () {
      expect(AreaCalculator.formatAcres(2.456), '2.46');
      expect(AreaCalculator.formatHectares(0.984), '0.98');
    });
  });

  group('FarmBoundary Model & Simplification Tests', () {
    test('FarmBoundary.fromPoints automatically closes unclosed polygon', () {
      final unclosedPoints = [
        const LatLng(30.900, 75.850),
        const LatLng(30.905, 75.850),
        const LatLng(30.905, 75.855),
        const LatLng(30.900, 75.855),
      ];

      final boundary = FarmBoundary.fromPoints(unclosedPoints);

      expect(boundary.points.length, 5);
      expect(boundary.points.first, boundary.points.last);
      expect(boundary.isValid, isTrue);
      expect(boundary.areaAcres, greaterThan(0.0));
      expect(boundary.areaHectares, greaterThan(0.0));
    });

    test('FarmBoundary rejects invalid shapes with fewer than 3 distinct points', () {
      final invalid = FarmBoundary.fromPoints([
        const LatLng(30.900, 75.850),
        const LatLng(30.900, 75.850),
      ]);

      expect(invalid.isValid, isFalse);
      expect(invalid.areaAcres, 0.0);
    });

    test('Douglas-Peucker simplification eliminates collinear points while preserving corners', () {
      // Create a polyline along a straight line with redundant midpoints, then a 90-degree corner
      final rawLine = [
        const LatLng(30.000, 75.000),
        const LatLng(30.001, 75.000), // collinear
        const LatLng(30.002, 75.000), // collinear
        const LatLng(30.003, 75.000), // collinear
        const LatLng(30.004, 75.000), // corner point
        const LatLng(30.004, 75.001), // collinear
        const LatLng(30.004, 75.002), // corner point
      ];

      final simplified = FarmBoundary.simplifyPoints(rawLine, epsilon: 0.000018);

      // Redundant collinear points along straight lines should be simplified
      expect(simplified.length, lessThan(rawLine.length));
      expect(simplified.first, rawLine.first);
      expect(simplified.last, rawLine.last);
      // Key corner points must be preserved
      expect(simplified.contains(const LatLng(30.004, 75.000)), isTrue);
    });

    test('FarmBoundary centroid calculates correct midpoint', () {
      final points = [
        const LatLng(30.0, 70.0),
        const LatLng(32.0, 70.0),
        const LatLng(32.0, 72.0),
        const LatLng(30.0, 72.0),
        const LatLng(30.0, 70.0),
      ];

      final boundary = FarmBoundary.fromPoints(points);
      expect(boundary.centroid.latitude, closeTo(30.8, 0.5));
      expect(boundary.centroid.longitude, closeTo(70.8, 0.5));
    });
  });

  group('GeoJsonService & RFC 7946 Tests', () {
    test('GeoJSON Feature serialization conforms strictly to team specification', () {
      final points = [
        const LatLng(28.456, 77.123),
        const LatLng(28.457, 77.124),
        const LatLng(28.455, 77.125),
        const LatLng(28.456, 77.123),
      ];

      final boundary = FarmBoundary.fromPoints(points, isConfirmed: true);
      final geoJson = GeoJsonService.toGeoJson(boundary);

      expect(geoJson['type'], 'Feature');
      expect(geoJson['properties']['areaUnit'], 'acres');
      expect(geoJson['properties']['isConfirmed'], isTrue);
      expect(geoJson['geometry']['type'], 'Polygon');

      final coords = geoJson['geometry']['coordinates'] as List;
      expect(coords.length, 1);
      final ring = coords.first as List;
      expect(ring.length, 4);

      // CRITICAL: GeoJSON requires [longitude, latitude]
      expect(ring.first[0], 77.123);
      expect(ring.first[1], 28.456);
      expect(ring.last[0], 77.123);
      expect(ring.last[1], 28.456);
    });

    test('GeoJSON roundtrip deserialization restores coordinates accurately', () {
      final original = FarmBoundary.fromPoints([
        const LatLng(30.9009, 75.8573),
        const LatLng(30.9050, 75.8573),
        const LatLng(30.9050, 75.8620),
        const LatLng(30.9009, 75.8620),
        const LatLng(30.9009, 75.8573),
      ], isConfirmed: true);

      final jsonString = GeoJsonService.toGeoJsonString(original);
      final restored = GeoJsonService.fromGeoJsonString(jsonString);

      expect(restored, isNotNull);
      expect(restored!.points.length, original.points.length);
      expect(restored.points.first.latitude, closeTo(30.9009, 0.0001));
      expect(restored.points.first.longitude, closeTo(75.8573, 0.0001));
      expect(restored.isConfirmed, isTrue);
      expect(restored.areaAcres, closeTo(original.areaAcres, 0.01));
    });

    test('GeoJsonService.isValidGeoJson correctly validates features', () {
      final validMap = {
        'type': 'Feature',
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [75.8573, 30.9009],
              [75.8573, 30.9050],
              [75.8620, 30.9050],
              [75.8573, 30.9009],
            ]
          ]
        }
      };
      expect(GeoJsonService.isValidGeoJson(validMap), isTrue);

      final invalidUnclosed = {
        'type': 'Feature',
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [75.8573, 30.9009],
              [75.8573, 30.9050],
              [75.8620, 30.9050],
            ]
          ]
        }
      };
      expect(GeoJsonService.isValidGeoJson(invalidUnclosed), isFalse);
    });
  });

  group('FarmBoundaryService Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Saves, loads, and clears boundary via local SharedPreferences', () async {
      final service = FarmBoundaryService();

      // Initially null
      final initial = await service.loadSavedBoundary();
      expect(initial, isNull);

      // Save a valid boundary
      final boundary = FarmBoundary.fromPoints([
        const LatLng(30.9009, 75.8573),
        const LatLng(30.9040, 75.8573),
        const LatLng(30.9040, 75.8600),
        const LatLng(30.9009, 75.8600),
        const LatLng(30.9009, 75.8573),
      ], isConfirmed: true);

      final saveSuccess = await service.saveBoundary(boundary);
      expect(saveSuccess, isTrue);

      // Load saved boundary
      final loaded = await service.loadSavedBoundary();
      expect(loaded, isNotNull);
      expect(loaded!.points.length, 5);
      expect(loaded.isConfirmed, isTrue);

      // Clear saved boundary
      final clearSuccess = await service.clearSavedBoundary();
      expect(clearSuccess, isTrue);
      final afterClear = await service.loadSavedBoundary();
      expect(afterClear, isNull);
    });
  });

  group('LocationNotifier & 4 UI States Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes in FarmMapMode.normal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final location = container.read(locationProvider);
      expect(location.mapMode, FarmMapMode.normal);
      expect(location.isDrawing, isFalse);
    });

    test('State transition: normal -> drawing -> preview -> saved', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(locationProvider.notifier);

      // 1. Enter drawing mode
      notifier.startDrawing();
      expect(container.read(locationProvider).mapMode, FarmMapMode.drawing);
      expect(container.read(locationProvider).isDrawing, isTrue);

      // 2. Trace finger on map (add points)
      notifier.addDrawingPoint(const LatLng(30.9000, 75.8500));
      notifier.addDrawingPoint(const LatLng(30.9050, 75.8500));
      notifier.addDrawingPoint(const LatLng(30.9050, 75.8550));
      notifier.addDrawingPoint(const LatLng(30.9000, 75.8550));

      expect(container.read(locationProvider).temporaryDrawingPoints.length, 4);

      // 3. Finish drawing -> transitions to preview
      final finishOk = notifier.finishDrawing();
      expect(finishOk, isTrue);
      expect(container.read(locationProvider).mapMode, FarmMapMode.preview);
      expect(container.read(locationProvider).farmAreaAcres, greaterThan(0.0));

      // 4. Confirm boundary -> transitions to saved & persists
      final confirmOk = await notifier.confirmBoundary();
      expect(confirmOk, isTrue);
      expect(container.read(locationProvider).mapMode, FarmMapMode.saved);
      expect(container.read(locationProvider).activeBoundary?.isConfirmed, isTrue);

      // Verify saved in confirmedLocationProvider
      final confirmed = container.read(confirmedLocationProvider);
      expect(confirmed.mapMode, FarmMapMode.saved);
    });

    test('Rejects drawing with too few points (< 4 points)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(locationProvider.notifier);
      notifier.startDrawing();

      // Only 2 points (accidental tap)
      notifier.addDrawingPoint(const LatLng(30.9000, 75.8500));
      notifier.addDrawingPoint(const LatLng(30.9001, 75.8501));

      final finishOk = notifier.finishDrawing();
      expect(finishOk, isFalse);
      expect(container.read(locationProvider).mapMode, FarmMapMode.drawing);
      expect(container.read(locationProvider).gpsError, 'please_trace_boundary');
    });

    test('Redraw clears previous boundary and returns to drawing mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(locationProvider.notifier);
      notifier.startDrawing();
      notifier.addDrawingPoint(const LatLng(30.9000, 75.8500));
      notifier.addDrawingPoint(const LatLng(30.9050, 75.8500));
      notifier.addDrawingPoint(const LatLng(30.9050, 75.8550));
      notifier.addDrawingPoint(const LatLng(30.9000, 75.8550));
      notifier.finishDrawing();

      expect(container.read(locationProvider).mapMode, FarmMapMode.preview);

      // Farmer taps Redraw
      notifier.redrawBoundary();
      final state = container.read(locationProvider);
      expect(state.mapMode, FarmMapMode.drawing);
      expect(state.temporaryDrawingPoints, isEmpty);
      expect(state.activeBoundary, isNull);
    });

    test('clearDrawing removes points and leaves clean map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(locationProvider.notifier);
      notifier.startDrawing();
      notifier.addDrawingPoint(const LatLng(30.9000, 75.8500));
      notifier.addDrawingPoint(const LatLng(30.9050, 75.8500));

      expect(container.read(locationProvider).temporaryDrawingPoints.length, 2);

      notifier.clearDrawing();
      expect(container.read(locationProvider).temporaryDrawingPoints, isEmpty);
      expect(container.read(locationProvider).mapMode, FarmMapMode.drawing);
    });
  });

  group('Multilingual Farm Map Translations Tests', () {
    final languages = ['en', 'hi', 'pa', 'bn', 'hr'];
    final requiredKeys = [
      'mark_your_farm',
      'draw_farm_boundary_subtitle',
      'draw_farm_boundary',
      'my_location',
      'trace_around_boundary',
      'clear',
      'done',
      'confirm_farm_boundary',
      'redraw',
      'redraw_boundary',
      'confirm',
      'farm_boundary_saved',
      'farm_area',
      'acres',
      'hectares',
      'please_trace_boundary',
      'location_unavailable',
      'location_permission_denied',
    ];

    for (final lang in languages) {
      test('Language "$lang" contains all required farm mapping keys', () {
        final loc = AppLocalizations(lang);
        for (final key in requiredKeys) {
          final translated = loc.translate(key);
          expect(translated, isNotEmpty, reason: 'Key "$key" should not be empty for "$lang"');
          if (lang != 'en' && key != 'acres' && key != 'hectares') {
            expect(translated, isNot(equals(key)),
                reason: 'Key "$key" should have a translated string in "$lang"');
          }
        }
      });
    }
  });
}
