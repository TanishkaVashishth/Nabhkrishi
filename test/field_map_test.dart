import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nabhkrishi/features/crop_disease/services/crop_disease_service.dart';
import 'package:nabhkrishi/features/field_map/models/satellite_field_data.dart';
import 'package:nabhkrishi/features/field_map/presentation/pages/field_map_page.dart';
import 'package:nabhkrishi/features/field_map/presentation/widgets/field_ai_status_card.dart';
import 'package:nabhkrishi/features/field_map/presentation/widgets/field_quick_actions.dart';
import 'package:nabhkrishi/features/field_map/presentation/widgets/satellite_radar_scanner_widget.dart';
import 'package:nabhkrishi/features/field_map/presentation/widgets/satellite_region_selector.dart';
import 'package:nabhkrishi/features/field_map/presentation/widgets/satellite_telemetry_card.dart';
import 'package:nabhkrishi/features/location/farm_boundary_map.dart';
import 'package:nabhkrishi/features/location/presentation/widgets/farm_location_details_card.dart';
import 'package:nabhkrishi/features/location/presentation/widgets/farm_map_widget.dart';
import 'package:nabhkrishi/features/location/presentation/widgets/manual_coordinates_input.dart';
import 'package:nabhkrishi/features/location/providers/location_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Satellite Field & SAR Model Tests', () {
    test('Prototype regions contain exactly 4 sectors (R1-R4) matching NabhKrishi-Web', () {
      expect(kPrototypeSatelliteRegions.length, equals(4));
      final labels = kPrototypeSatelliteRegions.map((r) => r.label).toList();
      expect(labels, equals(['R1', 'R2', 'R3', 'R4']));
    });

    test('All prototype SAR indicators are explicitly flagged as demo/prototype data', () {
      for (final region in kPrototypeSatelliteRegions) {
        expect(region.isDemoData, isTrue,
            reason: 'Region ${region.label} must be flagged as demo data for authentic transparency');
      }
    });

    test('Region measurements and formatters match web prototype specifications', () {
      final r1 = kPrototypeSatelliteRegions[0];
      expect(r1.label, equals('R1'));
      expect(r1.vvMean, closeTo(-11.2, 0.01));
      expect(r1.vvChange, closeTo(0.8, 0.01));
      expect(r1.ageDays, equals(2));
      expect(r1.vvMeanString, equals('-11.2 dB'));
      expect(r1.vvChangeString, equals('+0.8 dB'));
      expect(r1.ageString(false), equals('2 days ago'));
      expect(r1.ageString(true), contains('2 दिन'));

      final r2 = kPrototypeSatelliteRegions[1];
      expect(r2.label, equals('R2'));
      expect(r2.vvMean, closeTo(-12.6, 0.01));
      expect(r2.vvChange, closeTo(-1.4, 0.01));
      expect(r2.ageDays, equals(4));
      expect(r2.vvChangeString, equals('-1.4 dB'));
      expect(r2.status, equals('needs_check'));
    });

    test('Region names provide 5-language multilingual representations', () {
      final r3 = kPrototypeSatelliteRegions[2];
      expect(r3.getLocalizedName('en'), equals('South-East Sector'));
      expect(r3.getLocalizedName('hi'), equals('दक्षिण-पूर्वी भाग'));
      expect(r3.getLocalizedName('pa'), contains('ਦੱਖਣ-ਪੂਰਬੀ'));
      expect(r3.getLocalizedName('bn'), contains('দক্ষিণ-পূর্ব'));
      expect(r3.getLocalizedName('hr'), contains('दक्षिण-पूर्वी'));

      final r4 = kPrototypeSatelliteRegions[3];
      expect(r4.getLocalizedName('en'), equals('South-West Sector'));
      expect(r4.getLocalizedName('hi'), equals('दक्षिण-पश्चिमी भाग'));
    });
  });

  group('Field Map UI Component Tests', () {
    testWidgets('SatelliteRegionSelector renders R1-R4 buttons and fires callback on tap', (tester) async {
      int selectedIdx = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SatelliteRegionSelector(
              selectedIndex: selectedIdx,
              onRegionSelected: (idx) => selectedIdx = idx,
              language: 'en',
            ),
          ),
        ),
      );

      expect(find.text('R1'), findsOneWidget);
      expect(find.text('R2'), findsOneWidget);
      expect(find.text('R3'), findsOneWidget);
      expect(find.text('R4'), findsOneWidget);
      expect(find.text('R1 ACTIVE'), findsOneWidget);

      await tester.tap(find.text('R2'));
      expect(selectedIdx, equals(1));
    });

    testWidgets('SatelliteTelemetryCard renders VV Mean, VV Change, Satellite Age, and Demo label', (tester) async {
      final r1 = kPrototypeSatelliteRegions[0];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SatelliteTelemetryCard(
              region: r1,
              language: 'en',
            ),
          ),
        ),
      );

      expect(find.text('VV Mean'), findsOneWidget);
      expect(find.text('-11.2 dB'), findsOneWidget);
      expect(find.text('VV Change'), findsOneWidget);
      expect(find.text('+0.8 dB'), findsOneWidget);
      expect(find.text('Satellite Age'), findsOneWidget);
      expect(find.text('2 days ago'), findsOneWidget);
      expect(find.text('Prototype Satellite View'), findsOneWidget);
    });

    testWidgets('FieldAiStatusCard renders fallback states when no recent scan or recommendation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FieldAiStatusCard(
              latestResult: null,
              onScanLeaf: () {},
              onAskChatbot: () {},
              language: 'en',
            ),
          ),
        ),
      );

      expect(find.text('No recent AI scan'), findsOneWidget);
      expect(find.text('No recent AI recommendation'), findsOneWidget);
    });

    testWidgets('FieldAiStatusCard renders real Swin-T result and confidence disclaimer when scan exists', (tester) async {
      const result = CropDiseaseResult(
        diseaseName: 'Yellow Rust',
        classId: 14,
        confidence: 0.91,
        imagePath: 'test_path.jpg',
        description: 'Yellow rust symptoms on wheat leaf',
        decision: PpoDecision(
          actionId: 3,
          actionName: 'Disease Management Review',
          descriptionEn: 'Disease management review recommended.',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FieldAiStatusCard(
                latestResult: result,
                onScanLeaf: () {},
                onAskChatbot: () {},
                language: 'en',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Yellow Rust'), findsOneWidget);
      expect(find.text('Confidence: 91%'), findsOneWidget);
      expect(find.text('Confidence indicates AI model probability, not disease severity.'), findsOneWidget);
      expect(find.text('Action 3'), findsOneWidget);
    });

    testWidgets('FieldQuickActions renders all three quick action buttons and fires callbacks', (tester) async {
      bool scanClicked = false;
      bool askClicked = false;
      bool insightsClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FieldQuickActions(
              onScanWheat: () => scanClicked = true,
              onAskNabh: () => askClicked = true,
              onViewInsights: () => insightsClicked = true,
              language: 'en',
            ),
          ),
        ),
      );

      expect(find.text('Scan Wheat'), findsOneWidget);
      expect(find.text('Ask Nabh'), findsOneWidget);
      expect(find.text('View Insights'), findsOneWidget);

      await tester.tap(find.text('Scan Wheat'));
      expect(scanClicked, isTrue);

      await tester.tap(find.text('Ask Nabh'));
      expect(askClicked, isTrue);

      await tester.tap(find.text('View Insights'));
      expect(insightsClicked, isTrue);
    });

    testWidgets('SatelliteRadarScannerWidget renders and allows region selection', (tester) async {
      int selectedIdx = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SatelliteRadarScannerWidget(
              selectedRegionIndex: selectedIdx,
              onRegionSelected: (idx) => selectedIdx = idx,
              language: 'en',
            ),
          ),
        ),
      );

      expect(find.byType(SatelliteRadarScannerWidget), findsOneWidget);
      expect(find.text('SENTINEL-1 SAR 5.4GHz'), findsOneWidget);
      expect(find.text('VV POLARIZATION'), findsOneWidget);
      expect(find.text('Field Sectors: R1-R4 (Tap to select)'), findsOneWidget);
    });

    testWidgets('FieldMapPage renders complete dual experience layout without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FieldMapPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify Page & Dual Architecture
      expect(find.byType(FieldMapPage), findsOneWidget);

      // 2. Verify Existing Farm Location Map Components (Kept 100% Intact)
      expect(find.byType(FarmMapWidget), findsOneWidget);
      expect(find.byType(ManualCoordinatesInput), findsOneWidget);
      expect(find.byType(FarmLocationDetailsCard), findsOneWidget);
      expect(find.text('Select Farm Area'), findsOneWidget);

      // 3. Verify Field Selected Banner
      expect(find.text('FIELD SELECTED'), findsOneWidget);
      expect(find.text('My Wheat Field (Block A)'), findsOneWidget);

      // 4. Verify New Reference-Style Satellite Monitoring Components
      expect(find.byType(SatelliteRadarScannerWidget), findsOneWidget);
      expect(find.byType(SatelliteRegionSelector), findsOneWidget);
      expect(find.byType(SatelliteTelemetryCard), findsOneWidget);
      expect(find.text('R1 ACTIVE'), findsOneWidget);
      expect(find.text('VV Mean'), findsOneWidget);

      // 5. Verify Real AI & Quick Action Components
      expect(find.byType(FieldAiStatusCard), findsOneWidget);
      expect(find.byType(FieldQuickActions), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });

  group('Farm Map Hand-Draw Boundary Tests (Team Specification)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('State 1 (Normal): Renders Draw Farm Boundary and My Location control', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: FarmMapWidget(onLocationConfirmed: _dummyCallback),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Draw Farm Boundary'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byType(FarmBoundaryMap), findsOneWidget);
    });

    testWidgets('State 2 (Drawing): Tapping Draw Farm Boundary enters drawing mode and displays Trace instruction', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: FarmMapWidget(onLocationConfirmed: _dummyCallback),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Draw Farm Boundary'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Trace around your farm boundary'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('State 3 (Reviewing): Displays Confirm Farm with calculated area, Redraw and Confirm Farm', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sampleBoundary = FarmBoundary.fromPoints([
        const LatLng(30.900, 75.850),
        const LatLng(30.905, 75.850),
        const LatLng(30.905, 75.855),
        const LatLng(30.900, 75.855),
      ]);

      container.read(locationProvider.notifier).setBoundary(sampleBoundary.points);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: FarmMapWidget(onLocationConfirmed: _dummyCallback),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Confirm Farm'), findsOneWidget);
      expect(find.text('Redraw'), findsOneWidget);
      expect(find.textContaining('Acres'), findsOneWidget);
    });

    testWidgets('State 4 (Confirmed): Tapping Confirm Farm confirms boundary and triggers callback', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sampleBoundary = FarmBoundary.fromPoints([
        const LatLng(30.900, 75.850),
        const LatLng(30.905, 75.850),
        const LatLng(30.905, 75.855),
        const LatLng(30.900, 75.855),
      ]);

      container.read(locationProvider.notifier).setBoundary(sampleBoundary.points);

      bool callbackCalled = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: FarmMapWidget(
                  onLocationConfirmed: () {
                    callbackCalled = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Confirm Farm
      await tester.tap(find.text('Confirm Farm'));
      await tester.pumpAndSettle();

      expect(find.text('Farm Boundary Confirmed'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(callbackCalled, isTrue);
    });
  });
}

void _dummyCallback() {}

