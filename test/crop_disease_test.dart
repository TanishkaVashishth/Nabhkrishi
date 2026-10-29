import 'package:flutter_test/flutter_test.dart';
import 'package:nabhkrishi/features/crop_disease/services/crop_disease_service.dart';

void main() {
  group('CropDiseaseResult Model & Localization Tests', () {
    test('Correctly identifies Healthy leaf state', () {
      const healthyResult = CropDiseaseResult(
        diseaseName: 'Healthy',
        classId: 6,
        confidence: 0.92,
        imagePath: '/path/to/healthy.jpg',
        description: 'Healthy wheat foliage',
      );

      expect(healthyResult.isHealthy, isTrue);
      expect(healthyResult.isUncertain, isFalse);
      expect(healthyResult.confidencePercent, equals(92));
      expect(healthyResult.getLocalizedDiseaseName(false), equals('Healthy'));
      expect(healthyResult.getLocalizedDiseaseName(true), contains('स्वस्थ'));
    });

    test('Correctly handles Yellow Rust disease state and Hindi localization', () {
      const rustResult = CropDiseaseResult(
        diseaseName: 'Yellow Rust',
        classId: 14,
        confidence: 0.88,
        imagePath: '/path/to/rust.jpg',
        description: 'Yellow rust detected',
        topPredictions: [
          DiseasePredictionItem(classId: 14, className: 'Yellow Rust', confidence: 0.88),
          DiseasePredictionItem(classId: 3, className: 'Brown Rust', confidence: 0.08),
        ],
      );

      expect(rustResult.isHealthy, isFalse);
      expect(rustResult.isUncertain, isFalse);
      expect(rustResult.confidencePercent, equals(88));
      expect(rustResult.getLocalizedDiseaseName(false), equals('Yellow Rust'));
      expect(rustResult.getLocalizedDiseaseName(true), contains('पीला रतुआ'));
      expect(rustResult.topPredictions.length, equals(2));
    });

    test('Flags low confidence predictions as uncertain', () {
      const uncertainResult = CropDiseaseResult(
        diseaseName: 'Blast',
        classId: 2,
        confidence: 0.38,
        imagePath: '/path/to/unclear.jpg',
        description: 'Uncertain analysis',
      );

      expect(uncertainResult.isUncertain, isTrue);
      expect(uncertainResult.confidencePercent, equals(38));
    });

    test('Parses PpoDecision model from JSON and supports localization', () {
      final json = {
        'action_id': 3,
        'action_name': 'Disease Management Review',
        'description_en': 'Review disease severity and consult NabhKrishi chatbot.',
        'description_hi': 'रोग की गंभीरता की जांच करें और नभकृषि चैटबॉट से सलाह लें।'
      };

      final decision = PpoDecision.fromJson(json);
      expect(decision.actionId, equals(3));
      expect(decision.actionName, equals('Disease Management Review'));
      expect(decision.getLocalizedDescription(false), contains('Review disease severity'));
      expect(decision.getLocalizedDescription(true), contains('रोग की गंभीरता'));
    });

    test('Constructs CropDiseaseResult with PpoDecision and validates accessors', () {
      final decision = PpoDecision(
        actionId: 3,
        actionName: 'Disease Management Review',
        descriptionEn: 'Review disease severity and consult NabhKrishi chatbot for guidance.',
        descriptionHi: 'रोग की गंभीरता की जांच करें और नभकृषि चैटबॉट से उचित समाधान हेतु सलाह लें।',
      );

      final result = CropDiseaseResult(
        diseaseName: 'Yellow Rust',
        classId: 14,
        confidence: 0.91,
        imagePath: '/path/to/test.jpg',
        description: 'Yellow rust detected on foliage.',
        decision: decision,
      );

      expect(result.classId, equals(14));
      expect(result.diseaseName, equals('Yellow Rust'));
      expect(result.confidencePercent, equals(91));
      expect(result.decision, isNotNull);
      expect(result.decision!.actionId, equals(3));
      expect(result.decision!.actionName, equals('Disease Management Review'));
      expect(result.decision!.getLocalizedDescription(false), contains('consult NabhKrishi chatbot'));
      expect(result.decision!.getLocalizedDescription(true), contains('नभकृषि चैटबॉट'));
    });
  });
}
