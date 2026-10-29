import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;

/// Custom network exceptions to handle backend failures cleanly.
class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException(this.message, {this.statusCode});

  @override
  String toString() => 'NetworkException: $message (Status: $statusCode)';
}

class ApiClient {
  static const String baseUrl = 'https://nabhkrishi-backend.onrender.com';
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Helper to perform POST requests with JSON body and proper content headers.
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {'Content-Type': 'application/json'};
    final encodedBody = jsonEncode(body);
    final stopwatch = Stopwatch()..start();

    // === IRRIGATION API REQUEST ===
    developer.log('''
=== IRRIGATION API REQUEST ===
URL: $url
Method: POST
Latitude: ${body['latitude']}
Longitude: ${body['longitude']}
Request body: $encodedBody
''');

    try {
      // 120-second timeout to handle Render cold-start behavior.
      final response = await _client
          .post(url, headers: headers, body: encodedBody)
          .timeout(const Duration(seconds: 120));

      stopwatch.stop();

      // === IRRIGATION API RESPONSE ===
      developer.log('''
=== IRRIGATION API RESPONSE ===
Status code: ${response.statusCode}
Response time: ${stopwatch.elapsedMilliseconds}ms
Response body: ${response.body}
''');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } on FormatException catch (e, stackTrace) {
          _logError(e, stackTrace);
          throw NetworkException('JSON parsing error. Invalid response structure from server.');
        }
      } else {
        String errMsg = 'Request failed with status: ${response.statusCode}';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('detail')) {
            errMsg = decoded['detail'].toString();
          }
        } catch (_) {}
        throw NetworkException(errMsg, statusCode: response.statusCode);
      }
    } on NetworkException {
      // Rethrow to avoid wrapping it in the catch-all block below
      rethrow;
    } on http.ClientException catch (e, stackTrace) {
      stopwatch.stop();
      _logError(e, stackTrace);
      throw NetworkException('Network connection failed. Please check your internet connection.');
    } on SocketException catch (e, stackTrace) {
      stopwatch.stop();
      _logError(e, stackTrace);
      throw NetworkException('No internet connection or server unreachable. Please check your network settings.');
    } on TimeoutException catch (e, stackTrace) {
      stopwatch.stop();
      _logError(e, stackTrace);
      throw NetworkException('Server took too long to respond. The system services may be warming up. Please try again.');
    } on StateError catch (e, stackTrace) {
      stopwatch.stop();
      _logError(e, stackTrace);
      throw NetworkException('Unable to reach the server.');
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logError(e, stackTrace);
      if (e.toString().contains('TimeoutException')) {
        throw NetworkException('Server took too long to respond. The system services may be warming up. Please try again.');
      }
      throw NetworkException('An unexpected network error occurred.');
    }
  }

  void _logError(dynamic e, StackTrace stackTrace) {
    developer.log('''
=== IRRIGATION API ERROR ===
Exception type: ${e.runtimeType}
Error: $e
Stack trace: $stackTrace
''');
  }

  /// Helper to perform GET requests (like health checks).
  Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    developer.log('API GET Request to $url');

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 15));
      developer.log('API GET Response from $url: ${response.statusCode} - ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw NetworkException('Server responded with error status: ${response.statusCode}', statusCode: response.statusCode);
      }
    } catch (e) {
      developer.log('Unexpected GET error: $e');
      throw NetworkException('Failed to connect to NabhKrishi services.');
    }
  }
}
