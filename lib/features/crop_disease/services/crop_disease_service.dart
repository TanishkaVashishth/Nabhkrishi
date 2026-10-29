import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../services/chatbot_service.dart';

/// Top prediction item from the Swin-T model.
class DiseasePredictionItem {
  final int classId;
  final String className;
  final double confidence;

  const DiseasePredictionItem({
    required this.classId,
    required this.className,
    required this.confidence,
  });

  factory DiseasePredictionItem.fromJson(Map<String, dynamic> json) {
    return DiseasePredictionItem(
      classId: (json['class_id'] as num?)?.toInt() ?? -1,
      className: json['class_name']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Model representing the PPO V3 reinforcement learning decision-support output.
class PpoDecision {
  final int actionId;
  final String actionName;
  final String? descriptionEn;
  final String? descriptionHi;

  const PpoDecision({
    required this.actionId,
    required this.actionName,
    this.descriptionEn,
    this.descriptionHi,
  });

  factory PpoDecision.fromJson(Map<String, dynamic> json) {
    return PpoDecision(
      actionId: (json['action_id'] as num?)?.toInt() ?? 0,
      actionName: json['action_name']?.toString() ?? 'Monitor',
      descriptionEn: json['description_en']?.toString(),
      descriptionHi: json['description_hi']?.toString(),
    );
  }

  /// Whether this decision recommends active guidance/review via the RAG chatbot
  bool get needsChatbotGuidance => actionId == 3 || actionId == 5;

  /// Whether this decision asks to recheck the leaf photo
  bool get isRecheck => actionId == 4;

  /// Localized farmer description
  String getLocalizedDescription([dynamic languageOrIsHindi]) {
    String lang = 'en';
    if (languageOrIsHindi is bool) {
      lang = languageOrIsHindi ? 'hi' : 'en';
    } else if (languageOrIsHindi is String) {
      lang = languageOrIsHindi.toLowerCase().trim();
    }
    final isHi = lang == 'hi' || lang == 'hindi';
    if (isHi && descriptionHi != null && descriptionHi!.isNotEmpty) {
      return descriptionHi!;
    }
    return _defaultDescriptionByLang(actionId, lang, descriptionEn);
  }

  static String _defaultDescriptionByLang(int id, String lang, String? defaultEn) {
    if (lang == 'pa' || lang == 'punjabi') {
      switch (id) {
        case 0: return 'ਆਪਣੀ ਫ਼ਸਲ ਦੀ ਆਮ ਵਾਂਗ ਨਿਯਮਿਤ ਨਿਗਰਾਨੀ ਜਾਰੀ ਰੱਖੋ।';
        case 1: return 'ਰੋਗ ਤੋਂ ਬਚਾਅ ਲਈ ਸ਼ੁਰੂਆਤੀ ਫ਼ਸਲ ਪ੍ਰਬੰਧਨ ਦੀ ਸਮੀਖਿਆ ਕਰੋ।';
        case 2: return 'ਸਿੰਚਾਈ ਜਾਂ ਖ਼ੁਰਾਕੀ ਤੱਤਾਂ ਦੀ ਸਮੀਖਿਆ ਜ਼ਰੂਰੀ ਹੈ।';
        case 3: return 'ਰੋਗ ਪ੍ਰਬੰਧਨ ਅਤੇ ਕੀਟਨਾਸ਼ਕ/ਉੱਲੀਨਾਸ਼ਕ ਉਪਾਵਾਂ ਦੀ ਸਲਾਹ ਦਿੱਤੀ ਜਾਂਦੀ ਹੈ।';
        case 4: return 'ਸਹੀ ਨਤੀਜੇ ਲਈ ਕਿਰਪਾ ਕਰਕੇ ਕਣਕ ਦੇ ਪੱਤੇ ਦੀ ਇੱਕ ਹੋਰ ਸਾਫ਼ ਫੋਟੋ ਲਓ।';
        case 5: return 'ਇਸ ਵਿਸ਼ੇ ਤੇ ਨਾਭਕ੍ਰਿਸ਼ੀ AI ਤੋਂ ਸਲਾਹ ਲਵੋ।';
        default: return 'ਫ਼ਸਲ ਦੀ ਨਿਗਰਾਨੀ ਜਾਰੀ ਰੱਖੋ।';
      }
    }
    if (lang == 'bn' || lang == 'bengali') {
      switch (id) {
        case 0: return 'আপনার ফসলের স্বাভাবিক নিয়মিত পর্যবেক্ষণ চালিয়ে যান।';
        case 1: return 'রোগ প্রতিরোধের জন্য প্রাথমিক ফসল ব্যবস্থাপনার পর্যালোচনা করুন।';
        case 2: return 'সেচ অথবা পুষ্টি উপাদান ব্যবস্থাপনা পর্যালোচনা করা প্রয়োজন।';
        case 3: return 'রোগ ব্যবস্থাপনা ও প্রতিরক্ষামূলক ব্যবস্থা পর্যালোচনা করুন।';
        case 4: return 'সঠিক ফলাফলের জন্য গমের পাতার আরও একটি স্পষ্ট ছবি তুলুন।';
        case 5: return 'এই বিষয়ে নভকৃষি AI-এর সাথে পরামর্শ করুন।';
        default: return 'ফসলের পর্যবেক্ষণ চালিয়ে যান।';
      }
    }
    if (lang == 'hr' || lang == 'haryanvi') {
      switch (id) {
        case 0: return 'फसल की रोज बरती निगरानी जारी राखो।';
        case 1: return 'बीमारी तै बचाव खातर खेत की सुरुआती सार संभाल देखो।';
        case 2: return 'पाणी अर खाद की मात्रा की जांच जरूरी सै।';
        case 3: return 'बीमारी तै बचाव के छिड़काव की सलाह दी जावै सै।';
        case 4: return 'सटीक नतीजे खातर गेहूं के पत्ते की एक अर साफ फोटो खींचो।';
        case 5: return 'इस बारे में नभ AI तै बातचीत करो।';
        default: return 'फसल की देखरेख जारी राखो।';
      }
    }
    if (lang == 'hi' || lang == 'hindi') {
      switch (id) {
        case 0: return 'अपनी फसल की सामान्य रूप से नियमित निगरानी जारी रखें।';
        case 1: return 'रोग से बचाव हेतु प्रारंभिक फसल प्रबंधन की समीक्षा करें।';
        case 2: return 'सिंचाई अथवा पोषक तत्व प्रबंधन की समीक्षा आवश्यक है।';
        case 3: return 'रोग प्रबंधन और सुरक्षात्मक उपायों की समीक्षा की सलाह दी जाती है।';
        case 4: return 'सटीक परिणाम हेतु कृपया गेहूं पत्ती की एक और स्पष्ट फोटो लें।';
        case 5: return 'इस विषय पर नाभकृषि एआई से परामर्श करें।';
        default: return 'फसल की निगरानी जारी रखें।';
      }
    }
    if (lang == 'hinglish' || lang.contains('hinglish')) {
      switch (id) {
        case 0: return 'Apni fasal ki regular nigrani jari rakhein.';
        case 1: return 'Rog se bachav ke shuruati prabandhan ki samiksha karein.';
        case 2: return 'Sinchai ya poshak tatva prabandhan ki samiksha zaroori hai.';
        case 3: return 'Rog prabandhan aur bachav upayo ki salah di jaati hai.';
        case 4: return 'Sahi result ke liye kripya patti ki ek aur saaf photo lein.';
        case 5: return 'Is vishay par NabhKrishi AI se salah lein.';
        default: return 'Fasal ki nigrani jari rakhein.';
      }
    }
    return defaultEn ?? _defaultDescriptionEn(id);
  }

  static String _defaultDescriptionEn(int id) {
    switch (id) {
      case 0: return 'Continue monitoring your crop under standard management.';
      case 1: return 'Preventive crop-management review is recommended.';
      case 2: return 'Irrigation or nutrient management needs review.';
      case 3: return 'Disease-management review is recommended.';
      case 4: return 'Please capture another clear image for rechecking.';
      case 5: return "Let's discuss this with NabhKrishi AI.";
      default: return 'Continue monitoring your crop.';
    }
  }

  /// Localized action title
  String getLocalizedActionName([dynamic languageOrIsHindi]) {
    String lang = 'en';
    if (languageOrIsHindi is bool) {
      lang = languageOrIsHindi ? 'hi' : 'en';
    } else if (languageOrIsHindi is String) {
      lang = languageOrIsHindi.toLowerCase().trim();
    }
    if (lang == 'pa' || lang == 'punjabi') {
      switch (actionId) {
        case 0: return 'ਫ਼ਸਲ ਨਿਗਰਾਨੀ (Monitor)';
        case 1: return 'ਬਚਾਅ ਪ੍ਰਬੰਧਨ ਸਮੀਖਿਆ (Preventive)';
        case 2: return 'ਸਿੰਚਾਈ / ਖ਼ੁਰਾਕ ਸਮੀਖਿਆ (Irrigation/Nutrient)';
        case 3: return 'ਰੋਗ ਪ੍ਰਬੰਧਨ ਸਮੀਖਿਆ (Disease Management)';
        case 4: return 'ਦੁਬਾਰਾ ਫੋਟੋ ਲਓ (Recheck Photo)';
        case 5: return 'ਨਾਭਕ੍ਰਿਸ਼ੀ AI ਤੋਂ ਪੁੱਛੋ (Ask AI)';
        default: return actionName;
      }
    }
    if (lang == 'bn' || lang == 'bengali') {
      switch (actionId) {
        case 0: return 'ফসল পর্যবেক্ষণ (Monitor)';
        case 1: return 'প্রতিরোধমূলক ব্যবস্থা (Preventive)';
        case 2: return 'সেচ ও পুষ্টি পর্যালোচনা (Irrigation/Nutrient)';
        case 3: return 'রোগ ব্যবস্থাপনা পর্যালোচনা (Disease Management)';
        case 4: return 'পুনরায় ছবি তুলুন (Recheck Photo)';
        case 5: return 'নভকৃষি AI-কে জিজ্ঞাসা করুন (Ask AI)';
        default: return actionName;
      }
    }
    if (lang == 'hr' || lang == 'haryanvi') {
      switch (actionId) {
        case 0: return 'फसल देखरेख (Monitor)';
        case 1: return 'बचाव जांच (Preventive)';
        case 2: return 'पाणी / खाद पड़ताल (Irrigation/Nutrient)';
        case 3: return 'बीमारी रोकथाम (Disease Management)';
        case 4: return 'दोबारा फोटो खींचो (Recheck Photo)';
        case 5: return 'नभ AI तै पूछो (Ask AI)';
        default: return actionName;
      }
    }
    if (lang == 'hi' || lang == 'hindi') {
      switch (actionId) {
        case 0: return 'फसल निगरानी (Monitor)';
        case 1: return 'बचाव प्रबंधन समीक्षा (Preventive)';
        case 2: return 'सिंचाई / पोषण समीक्षा (Irrigation/Nutrient)';
        case 3: return 'रोग प्रबंधन समीक्षा (Disease Management)';
        case 4: return 'पुनः जांच (Recheck Photo)';
        case 5: return 'नाभकृषि चैटबॉट से पूछें (Ask AI)';
        default: return actionName;
      }
    }
    if (lang == 'hinglish' || lang.contains('hinglish')) {
      switch (actionId) {
        case 0: return 'Fasal Nigrani (Monitor)';
        case 1: return 'Bachav Prabandhan (Preventive)';
        case 2: return 'Sinchai / Poshan Review';
        case 3: return 'Rog Prabandhan Review';
        case 4: return 'Dobara Photo Lein (Recheck)';
        case 5: return 'NabhKrishi Chatbot se Poochhein (Ask AI)';
        default: return actionName;
      }
    }
    return actionName;
  }
}

/// Model representing the disease prediction result for wheat leaves.
class CropDiseaseResult {
  final String diseaseName;
  final int classId;
  final double confidence;
  final String imagePath;
  final String description;
  final List<DiseasePredictionItem> topPredictions;
  final PpoDecision? decision;

  const CropDiseaseResult({
    required this.diseaseName,
    required this.confidence,
    required this.imagePath,
    required this.description,
    this.classId = -1,
    this.topPredictions = const [],
    this.decision,
  });

  bool get isHealthy => classId == 6 || diseaseName.toLowerCase().trim() == 'healthy';
  bool get isUncertain => confidence < 0.50;
  int get confidencePercent => (confidence * 100).toInt();

  /// Map English class names to Hindi representations for the farmer UI.
  static const Map<String, String> _hindiDiseaseMap = {
    'aphid': 'माहू / एफिड (Aphid)',
    'black rust': 'काला रतुआ / तना रतुआ (Black Rust)',
    'blast': 'गेहूं का झुलसा / ब्लास्ट (Blast)',
    'brown rust': 'भूरा रतुआ (Brown Rust)',
    'common root rot': 'जड़ सड़न (Common Root Rot)',
    'fusarium head blight': 'फ्यूजेरियम हेड ब्लाइट (Fusarium Head Blight)',
    'healthy': 'स्वस्थ पत्ती (Healthy)',
    'leaf blight': 'पत्ती झुलसा रोग (Leaf Blight)',
    'mildew': 'चूर्णिल आसिता / पाउडरी मिल्ड्यू (Mildew)',
    'mite': 'मकड़ी / माइट (Mite)',
    'septoria': 'सेप्टोरिया लीफ ब्लॉच (Septoria)',
    'smut': 'कंडुआ रोग / स्मट (Smut)',
    'stem fly': 'तना मक्खी (Stem Fly)',
    'tan spot': 'टैन स्पॉट (Tan Spot)',
    'yellow rust': 'पीला रतुआ (Yellow Rust)',
  };

  /// Map English class names to Punjabi representations.
  static const Map<String, String> _punjabiDiseaseMap = {
    'aphid': 'ਤੇਲਾ / ਚੇਪਾ (Aphid)',
    'black rust': 'ਕਾਲਾ ਰਤੂਆ / ਤਣਾ ਰਤੂਆ (Black Rust)',
    'blast': 'ਕਣਕ ਦਾ ਝੁਲਸਾ / ਬਲਾਸਟ (Blast)',
    'brown rust': 'ਭੂਰਾ ਰਤੂਆ (Brown Rust)',
    'common root rot': 'ਜੜ੍ਹ ਗਲਣ (Common Root Rot)',
    'fusarium head blight': 'ਫਿਊਜ਼ੇਰੀਅਮ ਸਿੱਟਾ ਝੁਲਸਾ (Head Blight)',
    'healthy': 'ਸਿਹਤਮੰਦ ਪੱਤਾ (Healthy)',
    'leaf blight': 'ਪੱਤਾ ਝੁਲਸਾ ਰੋਗ (Leaf Blight)',
    'mildew': 'ਚੂਰਨਿਲ ਉੱਲੀ / ਪਾਊਡਰੀ ਮਿਲਡਿਊ (Mildew)',
    'mite': 'ਜੂੰ / ਮਾਈਟ (Mite)',
    'septoria': 'ਸੈਪਟੋਰੀਆ ਪੱਤਾ ਧੱਬਾ (Septoria)',
    'smut': 'ਕਾਂਗਿਆਰੀ / ਸਮੱਟ (Smut)',
    'stem fly': 'ਤਣਾ ਮੱਖੀ (Stem Fly)',
    'tan spot': 'ਟੈਨ ਸਪੌਟ (Tan Spot)',
    'yellow rust': 'ਪੀਲਾ ਰਤੂਆ / ਕੁੰਗੀ (Yellow Rust)',
  };

  /// Map English class names to Bengali representations.
  static const Map<String, String> _bengaliDiseaseMap = {
    'aphid': 'জাব পোকা (Aphid)',
    'black rust': 'কালো মরিচা রোগ (Black Rust)',
    'blast': 'গমের ব্লাস্ট রোগ (Wheat Blast)',
    'brown rust': 'বাদামী মরিচা রোগ (Brown Rust)',
    'common root rot': 'শিকড় পচা রোগ (Root Rot)',
    'fusarium head blight': 'ফিউজেরিয়াম হেড ব্লাইট (Head Blight)',
    'healthy': 'সুস্থ পাতা (Healthy)',
    'leaf blight': 'পাতা ঝলসানো রোগ (Leaf Blight)',
    'mildew': 'পাউডারি মিলডিউ (Mildew)',
    'mite': 'মাকড় (Mite)',
    'septoria': 'সেপ্টোরিয়া দাগ (Septoria)',
    'smut': 'আলগা স্মাট / ঝুল রোগ (Smut)',
    'stem fly': 'কাণ্ড মাছি (Stem Fly)',
    'tan spot': 'ট্যান স্পট (Tan Spot)',
    'yellow rust': 'হলুদ মরিচা রোগ (Yellow Rust)',
  };

  /// Map English class names to Haryanvi representations.
  static const Map<String, String> _haryanviDiseaseMap = {
    'aphid': 'माहू / चेपा (Aphid)',
    'black rust': 'काळा रतुआ (Black Rust)',
    'blast': 'गेहूं का झुलसा (Blast)',
    'brown rust': 'भूरा रतुआ (Brown Rust)',
    'common root rot': 'जड़ गलन (Root Rot)',
    'fusarium head blight': 'हेड ब्लाइट (Head Blight)',
    'healthy': 'नीरोगी पत्ता (Healthy)',
    'leaf blight': 'पत्ता झुलसा (Leaf Blight)',
    'mildew': 'पाउडरी मिल्ड्यू (Mildew)',
    'mite': 'मकड़ी / माइट (Mite)',
    'septoria': 'सेप्टोरिया चित्ती (Septoria)',
    'smut': 'कंडुआ / कांगियारी (Smut)',
    'stem fly': 'तना माखी (Stem Fly)',
    'tan spot': 'टैन चित्ती (Tan Spot)',
    'yellow rust': 'पीळा रतुआ (Yellow Rust)',
  };

  /// Map English class names to Hinglish / Romanized Hindi representations.
  static const Map<String, String> _hinglishDiseaseMap = {
    'aphid': 'Maahu / Aphid',
    'black rust': 'Kaala Ratua (Black Rust)',
    'blast': 'Gehun ka Jhulsa / Blast',
    'brown rust': 'Bhoora Ratua (Brown Rust)',
    'common root rot': 'Jadd Sadhan (Common Root Rot)',
    'fusarium head blight': 'Fusarium Head Blight',
    'healthy': 'Swasth Patti (Healthy)',
    'leaf blight': 'Patti Jhulsa Rog (Leaf Blight)',
    'mildew': 'Powdery Mildew',
    'mite': 'Makdi / Mite',
    'septoria': 'Septoria Leaf Blotch',
    'smut': 'Kandua Rog / Smut',
    'stem fly': 'Tana Makkhi (Stem Fly)',
    'tan spot': 'Tan Spot',
    'yellow rust': 'Peela Ratua (Yellow Rust)',
  };

  /// Returns localized disease name depending on language preference.
  String getLocalizedDiseaseName([dynamic languageOrIsHindi]) {
    String lang = 'en';
    if (languageOrIsHindi is bool) {
      lang = languageOrIsHindi ? 'hi' : 'en';
    } else if (languageOrIsHindi is String) {
      lang = languageOrIsHindi.toLowerCase().trim();
    }

    final key = diseaseName.toLowerCase().trim();
    if (lang == 'pa' || lang == 'punjabi') {
      return _punjabiDiseaseMap[key] ?? _hindiDiseaseMap[key] ?? diseaseName;
    }
    if (lang == 'bn' || lang == 'bengali') {
      return _bengaliDiseaseMap[key] ?? _hindiDiseaseMap[key] ?? diseaseName;
    }
    if (lang == 'hr' || lang == 'haryanvi') {
      return _haryanviDiseaseMap[key] ?? _hindiDiseaseMap[key] ?? diseaseName;
    }
    if (lang == 'hi' || lang == 'hindi') {
      return _hindiDiseaseMap[key] ?? diseaseName;
    }
    if (lang == 'hinglish' || lang.contains('hinglish')) {
      return _hinglishDiseaseMap[key] ?? _hindiDiseaseMap[key] ?? diseaseName;
    }
    return _formatTitle(diseaseName);
  }
}

/// Helper function to format raw snake/lowercase class names to Title Case.
String _formatTitle(String raw) {
  if (raw.isEmpty) return 'Unknown';
  return raw
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
      .join(' ');
}

/// Asynchronous service to send wheat leaf image to the FastAPI Swin-T backend.
Future<CropDiseaseResult> predictCropDisease(String imagePath) async {
  final file = File(imagePath);
  if (!await file.exists()) {
    throw Exception('Selected image file was not found on device.');
  }

  final fileSize = await file.length();
  if (fileSize == 0) {
    throw Exception('Selected image is empty. Please select a valid photo.');
  }
  if (fileSize > 15 * 1024 * 1024) {
    throw Exception('Image exceeds 15MB size limit. Please select a smaller photo.');
  }

  if (!ApiConstants.isConfigured &&
      !ChatbotConfig.activeBaseUrl.contains('http://10.') &&
      !ChatbotConfig.activeBaseUrl.contains('http://192.168.')) {
    throw Exception(
      'Laptop IP not configured. Please set your laptop Wi-Fi IPv4 address in '
      'lib/core/constants/api_constants.dart (e.g. const String apiBaseUrl = \'http://<YOUR_IP>:8000\';) '
      'or run with --dart-define=BACKEND_URL=http://<YOUR_IP>:8000',
    );
  }

  final targetUri = Uri.parse('${ApiConstants.resolvedBaseUrl}/predict');
  debugPrint('CropDisease [UPLOAD] Sending image to $targetUri');

  try {
    final request = http.MultipartRequest('POST', targetUri);
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 35));
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('CropDisease [RESPONSE] Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      final prediction = (decoded['prediction'] as Map<String, dynamic>?) ?? {};
      final classId = (prediction['class_id'] as num?)?.toInt() ?? -1;
      final rawClassName = prediction['class_name']?.toString() ?? 'Unknown';
      final confidence = (prediction['confidence'] as num?)?.toDouble() ?? 0.0;

      final formattedName = _formatTitle(rawClassName);

      final topPredsList = (decoded['top_predictions'] as List<dynamic>?) ?? [];
      final topPredictions = topPredsList.map((item) {
        final m = item as Map<String, dynamic>;
        return DiseasePredictionItem(
          classId: (m['class_id'] as num?)?.toInt() ?? -1,
          className: _formatTitle(m['class_name']?.toString() ?? ''),
          confidence: (m['confidence'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      String defaultDescription;
      if (classId == 6 || formattedName.toLowerCase() == 'healthy') {
        defaultDescription = 'Wheat leaf appears healthy without prominent fungal or pest lesions.';
      } else {
        defaultDescription = 'Swin-T classification identified features consistent with $formattedName.';
      }

      PpoDecision? ppoDecision;
      if (decoded.containsKey('decision') && decoded['decision'] != null) {
        try {
          ppoDecision = PpoDecision.fromJson(decoded['decision'] as Map<String, dynamic>);
          debugPrint('CropDisease [PPO] Action: ${ppoDecision.actionId} (${ppoDecision.actionName})');
        } catch (e) {
          debugPrint('CropDisease [WARN] Failed to parse PPO decision: $e');
        }
      }

      return CropDiseaseResult(
        diseaseName: formattedName,
        classId: classId,
        confidence: confidence,
        imagePath: imagePath,
        description: defaultDescription,
        topPredictions: topPredictions,
        decision: ppoDecision,
      );
    } else {
      String errDetail = 'Server error (${response.statusCode})';
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded.containsKey('detail')) {
          errDetail = decoded['detail'].toString();
        }
      } catch (_) {}
      debugPrint('CropDisease [ERROR] HTTP ${response.statusCode}: $errDetail');
      throw Exception(errDetail);
    }
  } on SocketException catch (e) {
    debugPrint('CropDisease [WARN] Host $targetUri unreachable: $e');
    throw Exception(
      "Could not connect to NabhKrishi AI server at ${ApiConstants.resolvedBaseUrl}. "
      "Please ensure your phone and laptop are on the same Wi-Fi and FastAPI is running with --host 0.0.0.0.",
    );
  } on TimeoutException catch (e) {
    debugPrint('CropDisease [WARN] Host $targetUri timed out: $e');
    throw Exception("Image analysis timed out. The server may be processing or warming up. Please try again.");
  } catch (e) {
    debugPrint('CropDisease [UNEXPECTED ERROR]: $e');
    if (e is Exception) {
      rethrow;
    }
    throw Exception("Failed to analyze wheat leaf image. Please try again.");
  }
}
