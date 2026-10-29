import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

/// Configuration adapter for Chatbot and Vision API endpoints.
/// Points directly to the central LAN configuration in [ApiConstants].
class ChatbotConfig {
  ChatbotConfig._();

  /// Default base URL resolved from [ApiConstants].
  static String get defaultBaseUrl => ApiConstants.resolvedBaseUrl;

  /// Active base URL.
  static String activeBaseUrl = ApiConstants.resolvedBaseUrl;
}

/// Response returned from the Python Chatbot API.
class ChatbotResponse {
  final String conversationId;
  final String answer;
  final String language;

  const ChatbotResponse({
    required this.conversationId,
    required this.answer,
    required this.language,
  });

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotResponse(
      conversationId: json['conversation_id']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      language: json['language']?.toString() ?? 'English',
    );
  }
}

/// Chat message model for the UI.
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final String? language;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.language,
  });
}

/// Chatbot Service handling HTTP communication with the Python RAG backend over LAN.
class ChatbotService {
  final http.Client _client;
  String baseUrl;

  ChatbotService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConstants.resolvedBaseUrl;

  /// Send a question to the NabhKrishi AI RAG backend via FastAPI over LAN.
  Future<ChatbotResponse> sendMessage({
    required String message,
    String? conversationId,
    String? userId,
    String? language,
  }) async {
    // Check if the IP has been configured
    if (!ApiConstants.isConfigured && !baseUrl.contains('http://10.') && !baseUrl.contains('http://192.168.')) {
      throw Exception(
        'Laptop IP not configured. Please set your laptop Wi-Fi IPv4 address in '
        'lib/core/constants/api_constants.dart (e.g. const String apiBaseUrl = \'http://<YOUR_IP>:8000\';) '
        'or run with --dart-define=BACKEND_URL=http://<YOUR_IP>:8000',
      );
    }

    final payload = <String, dynamic>{
      'message': message,
    };
    if (conversationId != null && conversationId.trim().isNotEmpty) {
      payload['conversation_id'] = conversationId;
    }
    if (userId != null && userId.trim().isNotEmpty) {
      payload['user_id'] = userId;
    }
    if (language != null && language.trim().isNotEmpty) {
      payload['language'] = language;
    }
    final body = jsonEncode(payload);

    final targetUri = Uri.parse('$baseUrl/chat');
    debugPrint('CHAT URL: $targetUri');
    final headers = {'Content-Type': 'application/json; charset=utf-8'};

    try {
      final response = await _client
          .post(targetUri, headers: headers, body: body)
          .timeout(const Duration(seconds: 120));

      final responseBody = utf8.decode(response.bodyBytes);
      debugPrint('CHAT URL: $targetUri');
      debugPrint('HTTP STATUS: ${response.statusCode}');
      debugPrint('RESPONSE BODY: $responseBody');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        return ChatbotResponse.fromJson(decoded);
      } else {
        String errDetail = 'Server error (${response.statusCode})';
        try {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map && decoded.containsKey('detail')) {
            errDetail = decoded['detail'].toString();
          }
        } catch (_) {}
        debugPrint('Chatbot [ERROR] HTTP ${response.statusCode}: $errDetail');
        throw Exception(errDetail);
      }
    } on SocketException catch (e) {
      debugPrint('CHAT URL: $targetUri');
      debugPrint('CHATBOT SOCKET ERROR: Connection failed: $e');
      throw SocketException(
        "Could not connect to NabhKrishi AI at $baseUrl. "
        "Please ensure your phone and laptop are on the same Wi-Fi network and FastAPI is running with --host 0.0.0.0.",
      );
    } on TimeoutException catch (e) {
      debugPrint('CHAT URL: $targetUri');
      debugPrint('CHATBOT TIMEOUT: Request timed out after 120 seconds: $e');
      throw TimeoutException(
        "AI response timed out after 120 seconds. The server may be processing a complex query. Please try again.",
      );
    } catch (e) {
      debugPrint('CHAT URL: $targetUri');
      debugPrint('Chatbot [ERROR] Exception during chat request: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception("Failed to communicate with NabhKrishi AI backend.");
    }
  }

  /// Check if the backend API is online.
  Future<bool> checkHealth() async {
    try {
      final targetUri = Uri.parse('$baseUrl/health');
      debugPrint('Chatbot [HEALTH CHECK] Testing $targetUri ...');
      final response = await _client.get(targetUri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Chatbot [HEALTH CHECK] Failed: $e');
      return false;
    }
  }
}

/// Riverpod provider for ChatbotService.
final chatbotServiceProvider = Provider<ChatbotService>((ref) {
  return ChatbotService();
});
