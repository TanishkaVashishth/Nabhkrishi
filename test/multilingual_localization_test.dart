import 'package:flutter_test/flutter_test.dart';
import 'package:nabhkrishi/core/localization/app_localizations.dart';
import 'package:nabhkrishi/features/crop_disease/services/crop_disease_service.dart';
import 'package:nabhkrishi/features/language/providers/language_provider.dart';

void main() {
  group('Multilingual Localization Unit Tests (6 Languages)', () {
    const supportedLangs = ['English', 'Hindi', 'Punjabi', 'Bengali', 'Haryanvi', 'Hinglish'];

    test('LanguageNotifier contains all 6 supported languages', () {
      expect(LanguageNotifier.supportedLanguages, containsAll(supportedLangs));
      expect(LanguageNotifier.supportedLanguages.length, equals(6));
      for (final lang in supportedLangs) {
        expect(LanguageNotifier.displayNames[lang], isNotNull);
        expect(LanguageNotifier.shortLabels[lang], isNotNull);
        expect(LanguageNotifier.languageCodes[lang], isNotNull);
      }
    });

    test('AppLocalizations normalizeCode normalizes all 6 languages correctly', () {
      expect(AppLocalizations.normalizeCode('English'), equals('en'));
      expect(AppLocalizations.normalizeCode('Hindi'), equals('hi'));
      expect(AppLocalizations.normalizeCode('Punjabi'), equals('pa'));
      expect(AppLocalizations.normalizeCode('Bengali'), equals('bn'));
      expect(AppLocalizations.normalizeCode('Haryanvi'), equals('hr'));
      expect(AppLocalizations.normalizeCode('Hinglish'), equals('hinglish'));
      expect(AppLocalizations.normalizeCode('hing'), equals('hinglish'));
    });

    test('AppLocalizations.get returns non-empty strings for key UI strings in all 6 languages', () {
      final keyStrings = [
        'field_crop_summary',
        'satellite_weather_favorable',
        'current_status',
        'wheat_optimal',
        'water_demand',
        'rainfall_7d_short',
        'radar_backscatter',
        'avg_temp',
        'quick_actions',
        'scan_leaf',
        'ask_nabh',
        'field_map',
        'trace_boundary_instruction',
        'draw_farm_boundary',
        'confirm_farm',
        'boundary_confirmed',
        'edit',
        'clear',
        'done',
        'redraw',
        'acres',
        'insights_analytics',
        'insights_subtitle',
        'filter_7d',
        'filter_30d',
        'filter_all',
        'weather_modal_title',
        'weather_modal_subtitle',
        'temperature',
        'humidity',
        'wind_speed',
        'rain_chance',
        'agronomic_advisory_title',
        'agronomic_advisory_subtitle',
        'farmer_profile',
        'account_settings',
        'verified_farmer',
        'active_farm_location',
        'save_farm',
        'logout_button',
        'sign_out_confirm_title',
      ];

      for (final lang in supportedLangs) {
        for (final key in keyStrings) {
          final text = AppLocalizations.get(key, lang);
          expect(text, isNotEmpty, reason: 'Key $key was empty for language $lang');
          expect(text, isNot(equals(key)), reason: 'Key $key was not localized for language $lang (fell back to key name)');
        }
      }
    });

    test('AppLocalizations.get handles parameter substitution', () {
      for (final lang in supportedLangs) {
        final text = AppLocalizations.get('days_together', lang, {'days': '42'});
        expect(text, contains('42'), reason: 'Days placeholder was not replaced in $lang');
      }
    });

    test('CropDiseaseResult getLocalizedDiseaseName works across all 6 languages', () {
      const result = CropDiseaseResult(
        diseaseName: 'yellow rust',
        confidence: 0.95,
        imagePath: '',
        description: '',
      );

      // Hindi native
      expect(result.getLocalizedDiseaseName('Hindi'), contains('पीला'));
      // Punjabi native
      expect(result.getLocalizedDiseaseName('Punjabi'), contains('ਪੀਲਾ'));
      // Bengali native
      expect(result.getLocalizedDiseaseName('Bengali'), contains('হলুদ'));
      // Haryanvi native
      expect(result.getLocalizedDiseaseName('Haryanvi'), contains('पीळा'));
      // Hinglish Romanized
      expect(result.getLocalizedDiseaseName('Hinglish'), contains('Peela'));
      // English
      expect(result.getLocalizedDiseaseName('English'), contains('Yellow Rust'));
    });

    test('PpoDecision getLocalizedActionName and getLocalizedDescription work across all 6 languages', () {
      const decision = PpoDecision(
        actionId: 1,
        actionName: 'Apply Propiconazole 25% EC',
        descriptionEn: 'Foliar spray of Propiconazole 25% EC @ 0.1% (1ml/L) recommended immediately.',
        descriptionHi: 'प्रोपिकोनाज़ोल 25% ईसी @ 0.1% (1 मिली/लीटर) का छिड़काव तुरंत करें।',
      );

      for (final lang in supportedLangs) {
        final actionName = decision.getLocalizedActionName(lang);
        final desc = decision.getLocalizedDescription(lang);
        expect(actionName, isNotEmpty, reason: 'Action name empty for $lang');
        expect(desc, isNotEmpty, reason: 'Description empty for $lang');
      }
    });

    test('AppLocalizations.getStatusName translates status badges across all 6 languages', () {
      const statuses = ['optimal', 'good', 'fair', 'moderate', 'alert'];
      for (final lang in supportedLangs) {
        for (final status in statuses) {
          final translated = AppLocalizations.getStatusName(status, lang);
          expect(translated, isNotEmpty, reason: 'Status $status empty for $lang');
        }
      }
    });
  });
}
