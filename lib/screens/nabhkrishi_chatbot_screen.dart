import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../features/language/providers/language_provider.dart';
import '../services/chatbot_service.dart';
import '../shared/widgets/tractor_icon.dart';

class NabhKrishiChatbotScreen extends ConsumerStatefulWidget {
  final bool isHindi;
  final String? currentLanguage;
  final String? initialPrompt;
  final double? bottomPadding;

  const NabhKrishiChatbotScreen({
    super.key,
    this.isHindi = false,
    this.currentLanguage,
    this.initialPrompt,
    this.bottomPadding,
  });

  @override
  ConsumerState<NabhKrishiChatbotScreen> createState() =>
      _NabhKrishiChatbotScreenState();
}

class _NabhKrishiChatbotScreenState
    extends ConsumerState<NabhKrishiChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  String? _conversationId;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isVoiceRecording = false;

  @override
  void initState() {
    super.initState();
    final activeLang = widget.currentLanguage ?? (widget.isHindi ? 'Hindi' : 'English');
    _addInitialWelcomeMessage(activeLang);
    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      _textController.text = widget.initialPrompt!;
    }
  }

  void _addInitialWelcomeMessage([String? lang]) {
    final language = (lang ?? widget.currentLanguage ?? (widget.isHindi ? 'Hindi' : 'English')).toLowerCase();
    String welcomeText;
    if (language.contains('punjabi') || language == 'pa') {
      welcomeText = 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ! ਮੈਂ **ਨਾਭਕ੍ਰਿਸ਼ੀ AI** ਖੇਤੀਬਾੜੀ ਸਹਾਇਕ ਹਾਂ।\n\nਮੈਨੂੰ ਕਣਕ ਦੇ ਰੋਗਾਂ, ਪੀਲਾ ਰਤੂਆ, ਕੁੰਗੀ, ਖਾਦਾਂ ਦੀ ਮਾਤਰਾ ਅਤੇ ਫ਼ਸਲ ਸੁਰੱਖਿਆ ਬਾਰੇ ਕੁਝ ਵੀ ਪੁੱਛੋ। ਸਾਰੇ ਜਵਾਬ ICAR ਅਤੇ PAU ਪ੍ਰਮਾਣਿਤ ਦਸਤਾਵੇਜ਼ਾਂ ਤੋਂ ਮਿਲਦੇ ਹਨ।';
    } else if (language.contains('bengali') || language == 'bn') {
      welcomeText = 'নমস্কার! আমি **নভকৃষি AI** কৃষি সহকারী।\n\nগমের রোগ, হলুদ মরিচা, ব্লাস্ট, সার প্রয়োগ এবং ফসল সুরক্ষা সম্পর্কে যেকোনো প্রশ্ন জিজ্ঞাসা করুন। সমস্ত উত্তর ICAR ও PAU পরীক্ষিত তথ্যভাণ্ডার থেকে প্রস্তুত।';
    } else if (language.contains('haryanvi') || language == 'hr') {
      welcomeText = 'राम राम भाई! मैं **नभकृषि AI** सहायक सूं।\n\nगेहूं की बीमारी, पीळा रतुआ, चेपा, खाद-पाणी अर रोकथाम बारे किमे भी पूछ सको सो। सारे जवाब ICAR अर PAU की जांची परखी जानकारी पै आधारित सैं।';
    } else if (language.contains('hinglish') || language == 'hing') {
      welcomeText = 'Namaste! Main **NabhKrishi AI** krishi sahayak hoon.\n\nMujhse gehun ke rogon, peela ratua, patti jhulsa, urvarak maatra aur fasal suraksha ke baare mein kuch bhi poochein. Sabhi uttar ICAR aur PAU satyapik gyan-kosh se prapt kiye jaate hain.';
    } else if (language.contains('hindi') || language == 'hi' || widget.isHindi) {
      welcomeText = 'नमस्ते! मैं **नाभकृषि एआई (GenAI RAG)** सहायक हूँ।\n\nमुझसे गेहूं के रोगों, पीला रतुआ, पत्ती झुलसा, उर्वरक मात्रा और फसल सुरक्षा के बारे में कुछ भी पूछें। सभी उत्तर ICAR व PAU सत्यापित ज्ञानकोष से प्राप्त किए जाते हैं।';
    } else {
      welcomeText = 'Namaste! I am your **NabhKrishi GenAI Agricultural Assistant**.\n\nAsk me anything about wheat diseases, yellow rust, irrigation schedules, or bio-fungicide treatments. Answers are synthesized from ICAR and PAU agricultural knowledge bases.';
    }

    _messages.add(
      ChatMessage(
        id: 'welcome_msg',
        text: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? prefilledText]) async {
    final text = (prefilledText ?? _textController.text).trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();

    try {
      final chatbotService = ref.read(chatbotServiceProvider);
      final activeLang = widget.currentLanguage ?? ref.read(languageProvider);
      final response = await chatbotService.sendMessage(
        message: text,
        conversationId: _conversationId,
        language: activeLang,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _conversationId = response.conversationId;
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: response.answer,
            isUser: false,
            timestamp: DateTime.now(),
            language: response.language,
          ),
        );
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      final String activeLanguage = widget.currentLanguage ?? ref.read(languageProvider);
      final langLower = activeLanguage.toLowerCase();
      String displayError;
      final errorStr = e.toString().toLowerCase();
      if (e is TimeoutException || errorStr.contains('timed out') || errorStr.contains('timeout')) {
        if (langLower.contains('punjabi') || langLower == 'pa') {
          displayError = 'AI ਤੋਂ ਜਵਾਬ ਮਿਲਣ ਵਿੱਚ ਵੱਧ ਸਮਾਂ ਲੱਗਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';
        } else if (langLower.contains('bengali') || langLower == 'bn') {
          displayError = 'AI থেকে উত্তর পেতে অতিরিক্ত সময় লেগেছে। দয়া করে আবার চেষ্টা করুন।';
        } else if (langLower.contains('haryanvi') || langLower == 'hr') {
          displayError = 'उत्तर आणे में घणा टेम लाग ग्या। फेर कोशिश करो।';
        } else if (langLower.contains('hindi') || langLower == 'hi' || widget.isHindi) {
          displayError = 'एआई से उत्तर प्राप्त करने में अधिक समय लग गया। कृपया पुनः प्रयास करें।';
        } else {
          displayError = 'NabhKrishi AI took too long to respond (timeout). Please try again.';
        }
      } else if (e is SocketException || errorStr.contains('connection') || errorStr.contains('socket') || errorStr.contains('unreachable')) {
        if (langLower.contains('punjabi') || langLower == 'pa') {
          displayError = 'ਨਾਭਕ੍ਰਿਸ਼ੀ AI ਸਰਵਰ ਨਾਲ ਸੰਪਰਕ ਨਹੀਂ ਹੋ ਸਕਿਆ। ਕਿਰਪਾ ਕਰਕੇ Wi-Fi ਕੁਨੈਕਸ਼ਨ ਜਾਂਚੋ।';
        } else if (langLower.contains('bengali') || langLower == 'bn') {
          displayError = 'নভকৃষি AI সার্ভারের সাথে সংযোগ করা যায়নি। দয়া করে Wi-Fi পরীক্ষা করুন।';
        } else if (langLower.contains('haryanvi') || langLower == 'hr') {
          displayError = 'नाभकृषि AI सर्वर तै संपर्क कोन्या होया। Wi-Fi चेक करो।';
        } else if (langLower.contains('hindi') || langLower == 'hi' || widget.isHindi) {
          displayError = 'नाभकृषि AI सर्वर से संपर्क नहीं हो सका। कृपया जांचें कि फोन और लैपटॉप एक ही वाई-फाई पर हैं।';
        } else {
          displayError = "Unable to connect to NabhKrishi right now. Please try again.";
        }
      } else {
        displayError = (langLower.contains('hindi') || widget.isHindi)
            ? 'नाभकृषि AI से संपर्क नहीं हो सका। कृपया पुनः प्रयास करें।'
            : 'Unable to connect to NabhKrishi right now. Please try again.';
      }

      setState(() {
        _isLoading = false;
        _errorMessage = displayError;

        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: _errorMessage!,
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _simulateVoiceNote() {
    if (_isVoiceRecording) return;

    setState(() => _isVoiceRecording = true);
    HapticFeedback.heavyImpact();

    final String activeLanguage = widget.currentLanguage ?? ref.read(languageProvider);
    final langLower = activeLanguage.toLowerCase();
    String title = 'Recording Voice Note...';
    String subtitle = 'Speak your wheat query in your language';
    String buttonText = 'Finish & Ask AI';
    String simulatedQuery = 'Provide treatment and prevention measures for wheat yellow rust.';

    if (langLower.contains('punjabi') || langLower == 'pa') {
      title = 'ਆਵਾਜ਼ ਰਿਕਾਰਡ ਹੋ ਰਹੀ ਹੈ...';
      subtitle = 'ਆਪਣੀ ਬੋਲੀ ਵਿੱਚ ਸਵਾਲ ਪੁੱਛੋ';
      buttonText = 'ਰਿਕਾਰਡਿੰਗ ਪੂਰੀ ਕਰੋ';
      simulatedQuery = 'ਕਣਕ ਵਿੱਚ ਪੀਲੇ ਰਤੂਏ ਦੀ ਰੋਕਥਾਮ ਅਤੇ ਉੱਲੀਨਾਸ਼ਕ ਇਲਾਜ ਦੱਸੋ।';
    } else if (langLower.contains('bengali') || langLower == 'bn') {
      title = 'ভয়েস রেকর্ড হচ্ছে...';
      subtitle = 'আপনার ভাষায় প্রশ্ন জিজ্ঞাসা করুন';
      buttonText = 'রেকর্ডিং শেষ করুন';
      simulatedQuery = 'গমে হলুদ মরিচা ও ব্লাস্ট রোগের প্রতিরোধমূলক ব্যবস্থা বলুন।';
    } else if (langLower.contains('haryanvi') || langLower == 'hr') {
      title = 'आवाज रिकॉर्ड हो रही सै...';
      subtitle = 'अपणी बोली में सवाल पूछो';
      buttonText = 'रिकॉर्डिंग पूरी करो';
      simulatedQuery = 'गेहूं में पीळा रतुआ बीमारी का पक्का इलाज अर स्प्रे बताओ।';
    } else if (langLower.contains('hindi') || langLower == 'hi' || widget.isHindi) {
      title = 'आवाज़ रिकॉर्ड हो रही है...';
      subtitle = 'अपनी भाषा में प्रश्न पूछें';
      buttonText = 'रिकॉर्डिंग समाप्त करें';
      simulatedQuery = 'गेहूं की फसल में पीला रतुआ रोग के उपचार और रोकथाम के उपाय बताएं।';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.dangerLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: AppColors.danger, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _isVoiceRecording = false);
                _handleSendMessage(simulatedQuery);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  void _resetConversation() {
    HapticFeedback.mediumImpact();
    setState(() {
      _conversationId = null;
      _messages.clear();
      _errorMessage = null;
      final activeLang = widget.currentLanguage ?? ref.read(languageProvider);
      _addInitialWelcomeMessage(activeLang);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLanguage = ref.watch(languageProvider);
    final String activeLanguage = widget.currentLanguage ?? appLanguage;
    final isHindi = activeLanguage == 'Hindi';
    final langLower = activeLanguage.toLowerCase();

    List<String> quickSuggestions;
    if (langLower.contains('punjabi') || langLower == 'pa') {
      quickSuggestions = [
        'ਪੀਲਾ ਰਤੂਆ ਦੀ ਪਛਾਣ',
        'ਉੱਲੀਨਾਸ਼ਕ ਸਪਰੇਅ ਦਾ ਸਮਾਂ',
        'ਸਿੰਚਾਈ ਕਦੋਂ ਰੋਕੀਏ?',
        'ਫ਼ਸਲ ਦੀ ਰੋਕਥਾਮ ਸੰਭਾਲ'
      ];
    } else if (langLower.contains('bengali') || langLower == 'bn') {
      quickSuggestions = [
        'হলুদ মরিচা চেনার উপায়',
        'ছত্রাকনাশক স্প্রে সময়সূচী',
        'কখন সেচ বন্ধ করবেন?',
        'প্রতিরোধমূলক গমের যত্ন'
      ];
    } else if (langLower.contains('haryanvi') || langLower == 'hr') {
      quickSuggestions = [
        'पीळा रतुआ की पहचान',
        'स्प्रे कदे करणा चाहिए?',
        'पाणी कद रोकना सै?',
        'फसल की सार-संभाल'
      ];
    } else if (langLower.contains('hindi') || langLower == 'hi' || isHindi) {
      quickSuggestions = [
        'पीला रतुआ की पहचान',
        'फफूंदनाशक स्प्रे का समय',
        'सिंचाई कब रोकें?',
        'स्वस्थ फसल देखभाल'
      ];
    } else {
      quickSuggestions = [
        'Yellow rust symptoms',
        'Fungicide spray schedule',
        'When to pause irrigation?',
        'Preventive wheat care'
      ];
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const TractorIcon(size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'NabhKrishi AI',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    (langLower.contains('hinglish') || langLower == 'hing')
                        ? 'Satyapit RAG Gyan-Kosh • Online'
                        : (langLower.contains('punjabi') || langLower == 'pa')
                            ? 'ਪ੍ਰਮਾਣਿਤ RAG ਖੇਤੀਬਾੜੀ • ਆਨਲਾਈਨ'
                            : (langLower.contains('bengali') || langLower == 'bn')
                                ? 'পরীক্ষিত RAG কৃষিজ্ঞান • অনলাইন'
                                : (langLower.contains('haryanvi') || langLower == 'hr')
                                    ? 'जांच्या होया RAG ज्ञान • ऑनलाइन'
                                    : (langLower.contains('hindi') || isHindi)
                                        ? 'सत्यापित RAG ज्ञानकोष • ऑनलाइन'
                                        : 'Verified RAG Agronomy • Online',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isHindi ? 'नई बातचीत' : 'New Chat',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 22),
            onPressed: _resetConversation,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick suggestion chips
            if (_messages.length <= 3)
              Container(
                height: 42,
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  scrollDirection: Axis.horizontal,
                  itemCount: quickSuggestions.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final suggestion = quickSuggestions[index];
                    return ActionChip(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      label: Text(
                        suggestion,
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _handleSendMessage(suggestion);
                      },
                    );
                  },
                ),
              ),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _TypingIndicatorBubble(isHindi: isHindi);
                  }
                  final msg = _messages[index];
                  return _ChatMessageBubble(
                    message: msg,
                    isHindi: isHindi,
                  );
                },
              ),
            ),

            // Input Bar
            _buildInputBar(isHindi),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isHindi) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double bottomPad = keyboardHeight > 0
        ? 12.0
        : ((widget.bottomPadding ?? 0.0) + 12.0);

    final String activeLanguage = widget.currentLanguage ?? ref.read(languageProvider);
    final langLower = activeLanguage.toLowerCase();
    String hintText;
    if (langLower.contains('hinglish') || langLower == 'hing') {
      hintText = 'NabhKrishi se poochein... (Ask NabhKrishi)';
    } else if (langLower.contains('punjabi') || langLower == 'pa') {
      hintText = 'ਨਾਭਕ੍ਰਿਸ਼ੀ ਨੂੰ ਪੁੱਛੋ... (Ask NabhKrishi)';
    } else if (langLower.contains('bengali') || langLower == 'bn') {
      hintText = 'নভকৃষিকে জিজ্ঞাসা করুন... (Ask NabhKrishi)';
    } else if (langLower.contains('haryanvi') || langLower == 'hr') {
      hintText = 'नभकृषि तै पूछो... (Ask NabhKrishi)';
    } else if (langLower.contains('hindi') || langLower == 'hi' || isHindi) {
      hintText = 'नाभकृषि से पूछें... (Ask NabhKrishi)';
    } else {
      hintText = 'Ask NabhKrishi...';
    }

    final bool hasText = _textController.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, bottomPad),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        children: [
          // Voice note simulation button
          InkWell(
            onTap: _simulateVoiceNote,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(Icons.mic, color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 8),

          // Text Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      key: const Key('chatbot_input_field'),
                      controller: _textController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.send,
                      maxLines: 4,
                      minLines: 1,
                      style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 12.5),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  if (hasText)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                      onPressed: () {
                        _textController.clear();
                        setState(() {});
                      },
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('chatbot_send_button'),
              onTap: (_isLoading || !hasText) ? null : () => _handleSendMessage(),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_isLoading || !hasText)
                      ? AppColors.surfaceMuted
                      : AppColors.primary,
                  boxShadow: (_isLoading || !hasText)
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textMuted,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: hasText ? Colors.white : AppColors.textMuted,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isHindi;

  const _ChatMessageBubble({
    required this.message,
    required this.isHindi,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = message.isError;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isError ? AppColors.dangerLight : AppColors.mintBg,
                border: Border.all(
                  color: isError ? AppColors.danger.withValues(alpha: 0.3) : AppColors.primaryLight.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.eco_rounded,
                color: isError ? AppColors.danger : AppColors.primary,
                size: 16,
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryMedium
                    : (isError ? AppColors.dangerLight : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: isUser
                      ? AppColors.primaryMedium
                      : (isError ? AppColors.danger.withValues(alpha: 0.3) : AppColors.borderLight),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser && !isError) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Verified RAG Knowledge',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  if (isUser || isError)
                    SelectableText(
                      message.text,
                      style: GoogleFonts.poppins(
                        color: isUser
                            ? Colors.white
                            : AppColors.dangerDark,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    )
                  else
                    MarkdownBody(
                      data: message.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                        h1: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                        h2: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        h3: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                        strong: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        em: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        listBullet: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        code: GoogleFonts.sourceCodePro(
                          color: AppColors.primaryDark,
                          backgroundColor: AppColors.surfaceSoft,
                          fontSize: 12,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: const Border(
                            left: BorderSide(color: AppColors.primary, width: 3),
                          ),
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        blockSpacing: 8,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      _formatTime(message.timestamp),
                      style: GoogleFonts.poppins(
                        color: isUser ? Colors.white70 : AppColors.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryMedium.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _TypingIndicatorBubble extends StatefulWidget {
  final bool isHindi;

  const _TypingIndicatorBubble({required this.isHindi});

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.mintBg,
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 16),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          final delay = index * 0.2;
                          final progress = (_controller.value + delay) % 1.0;
                          final bounce = math.sin(progress * math.pi);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: 6.5,
                            height: 6.5 + (bounce * 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.4 + (bounce * 0.6)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.isHindi ? 'नाभ एआई उत्तर तैयार कर रहा है...' : 'Nabh is preparing verified guidance...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
