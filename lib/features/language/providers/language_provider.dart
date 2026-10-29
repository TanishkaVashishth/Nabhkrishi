import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageNotifier extends Notifier<String> {
  static const String _key = 'selected_language';

  static const List<String> supportedLanguages = [
    'English',
    'Hindi',
    'Punjabi',
    'Bengali',
    'Haryanvi',
    'Hinglish',
  ];

  static const Map<String, String> displayNames = {
    'English': 'English',
    'Hindi': 'हिन्दी',
    'Punjabi': 'ਪੰਜਾਬੀ',
    'Bengali': 'বাংলা',
    'Haryanvi': 'हरियाणवी',
    'Hinglish': 'Hinglish (रोमन हिन्दी)',
  };

  static const Map<String, String> shortLabels = {
    'English': 'EN',
    'Hindi': 'हि',
    'Punjabi': 'ਪੰ',
    'Bengali': 'বা',
    'Haryanvi': 'हरि',
    'Hinglish': 'Hing',
  };

  static const Map<String, String> languageCodes = {
    'English': 'en',
    'Hindi': 'hi',
    'Punjabi': 'pa',
    'Bengali': 'bn',
    'Haryanvi': 'hr',
    'Hinglish': 'hinglish',
  };

  @override
  String build() {
    _loadLanguage();
    return 'English';
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString(_key);
      if (lang != null && supportedLanguages.contains(lang)) {
        state = lang;
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String language) async {
    if (!supportedLanguages.contains(language)) return;
    state = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, language);
    } catch (_) {}
  }

  Future<void> cycleNextLanguage() async {
    final currentIndex = supportedLanguages.indexOf(state);
    final nextIndex = (currentIndex + 1) % supportedLanguages.length;
    await setLanguage(supportedLanguages[nextIndex]);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(() {
  return LanguageNotifier();
});
