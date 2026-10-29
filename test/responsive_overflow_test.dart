import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabhkrishi/features/crop_disease/presentation/widgets/crop_disease_result_dialog.dart';
import 'package:nabhkrishi/features/crop_disease/services/crop_disease_service.dart';
import 'package:nabhkrishi/features/location/models/drawing_state.dart';
import 'package:nabhkrishi/features/location/models/farm_boundary.dart';
import 'package:nabhkrishi/features/location/presentation/widgets/drawing_hud.dart';
import 'package:nabhkrishi/screens/nabhkrishi_chatbot_screen.dart';
import 'package:nabhkrishi/shared/widgets/circular_health_gauge.dart';
import 'package:nabhkrishi/shared/widgets/floating_bottom_nav_bar.dart';
import 'package:nabhkrishi/shared/widgets/modals/agronomic_advisory_modal.dart';
import 'package:nabhkrishi/shared/widgets/modals/weather_telemetry_modal.dart';
import 'package:nabhkrishi/shared/widgets/ppo_decision_card.dart';
import 'package:nabhkrishi/shared/widgets/top_farmer_app_bar.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const testWidths = [320.0, 360.0, 375.0, 390.0, 412.0];
  const allLanguages = ['English', 'Hindi', 'Punjabi', 'Bengali', 'Haryanvi', 'Hinglish'];

  group('Responsive Layout Tests (Zero RenderFlex Overflows Across 6 Languages)', () {
    for (final width in testWidths) {
      testWidgets('TopFarmerAppBar does not overflow at width ${width}px across all 6 languages', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final lang in allLanguages) {
          final isHindi = lang == 'Hindi';
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: SafeArea(
                    child: TopFarmerAppBar(
                      activeFieldName: isHindi ? 'मेरा गेहूं का खेत (उत्तर)' : 'North Wheat Field Block A',
                      isHindi: isHindi,
                      currentLanguage: lang,
                      onLanguageChanged: (_) {},
                      onOpenWeather: () {},
                      onOpenProfile: () {},
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'Overflow in TopFarmerAppBar at width $width (lang: $lang)');
        }
      });

      testWidgets('PPODecisionCard does not overflow at width ${width}px across all 6 languages', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const testDecision = PpoDecision(
          actionId: 1,
          actionName: 'Apply Propiconazole 25% EC',
          descriptionEn: 'Foliar spray of Propiconazole 25% EC @ 0.1% (1ml/L) recommended immediately.',
          descriptionHi: 'प्रोपिकोनाज़ोल 25% ईसी @ 0.1% (1 मिली/लीटर) का छिड़काव तुरंत करें।',
        );

        for (final lang in allLanguages) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: PPODecisionCard(
                      decision: testDecision,
                      isHindi: lang == 'Hindi',
                      currentLanguage: lang,
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'Overflow in PPODecisionCard at width $width (lang: $lang)');
        }
      });

      testWidgets('FloatingBottomNavBar does not overflow at width ${width}px across all 6 languages', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final lang in allLanguages) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: FloatingBottomNavBar(
                  selectedIndex: 0,
                  onTabSelected: (_) {},
                  isHindi: lang == 'Hindi',
                  currentLanguage: lang,
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'Overflow in FloatingBottomNavBar at width $width (lang: $lang)');
        }
      });

      testWidgets('WeatherTelemetryModal does not overflow at width ${width}px across all 6 languages', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final lang in allLanguages) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: WeatherTelemetryModal(
                  isHindi: lang == 'Hindi',
                  currentLanguage: lang,
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'Overflow in WeatherTelemetryModal at width $width (lang: $lang)');
        }
      });

      testWidgets('AgronomicAdvisoryModal does not overflow at width ${width}px across all 6 languages', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final lang in allLanguages) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AgronomicAdvisoryModal(
                  isHindi: lang == 'Hindi',
                  currentLanguage: lang,
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'Overflow in AgronomicAdvisoryModal at width $width (lang: $lang)');
        }
      });

      testWidgets('DrawingHud does not overflow at width ${width}px across all states and languages', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final sampleBoundary = FarmBoundary.fromPoints(
          const [
            LatLng(28.6139, 77.2090),
            LatLng(28.6145, 77.2095),
            LatLng(28.6140, 77.2105),
          ],
        );

        for (final lang in allLanguages) {
          for (final state in DrawingState.values) {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.bottomCenter,
                    child: DrawingHud(
                      state: state,
                      currentBoundary: sampleBoundary,
                      liveAreaAcres: 2.45,
                      onStartDrawing: () {},
                      onClearDrawing: () {},
                      onDoneDrawing: () {},
                      onRedraw: () {},
                      onConfirm: () {},
                      isHindi: lang == 'Hindi',
                      currentLanguage: lang,
                    ),
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull,
                reason: 'Overflow in DrawingHud at width $width (state: $state, lang: $lang)');
          }
        }
      });

      testWidgets('CropDiseaseResultDialog does not overflow at width ${width}px across languages', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final testResult = CropDiseaseResult(
          diseaseName: 'yellow rust',
          confidence: 0.94,
          imagePath: '',
          description: 'Fungicide spray needed.',
          decision: const PpoDecision(
            actionId: 3,
            actionName: 'Disease Management Review',
            descriptionEn: 'Fungicide spray needed.',
            descriptionHi: 'कवकनाशी छिड़काव की सिफारिश की जाती है।',
          ),
          topPredictions: const [
            DiseasePredictionItem(classId: 3, className: 'brown rust', confidence: 0.04),
            DiseasePredictionItem(classId: 9, className: 'septoria', confidence: 0.02),
          ],
        );

        for (final lang in allLanguages) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CropDiseaseResultDialog(
                  result: testResult,
                  isHindi: lang == 'Hindi',
                  currentLanguage: lang,
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'Overflow in CropDiseaseResultDialog at width $width (lang: $lang)');
        }
      });

      testWidgets('CircularHealthGauge does not overflow at width ${width}px', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final lang in allLanguages) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CircularHealthGauge(
                    score: 84,
                    isHindi: lang == 'Hindi',
                    currentLanguage: lang,
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'Overflow in CircularHealthGauge at width $width (lang: $lang)');
        }
      });

      testWidgets('NabhKrishiChatbotScreen UI renders without overflow at width ${width}px', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final lang in allLanguages) {
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: NabhKrishiChatbotScreen(
                    isHindi: lang == 'Hindi',
                    currentLanguage: lang,
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'Overflow in NabhKrishiChatbotScreen at width $width (lang: $lang)');
        }
      });
    }
  });
}
