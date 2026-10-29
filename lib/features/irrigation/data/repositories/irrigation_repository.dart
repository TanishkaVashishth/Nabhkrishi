import '../../../../core/network/api_client.dart';
import '../../models/irrigation_models.dart';

class IrrigationRepository {
  final ApiClient _apiClient;

  IrrigationRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Requests weather, satellite telemetry, and DQN recommendations for the given coordinates.
  Future<LocationPredictionResponse> predictLocation(double latitude, double longitude) async {
    final Map<String, dynamic> body = {
      'latitude': latitude,
      'longitude': longitude,
    };
    
    final responseJson = await _apiClient.post('/predict-location', body);
    return LocationPredictionResponse.fromJson(responseJson);
  }
  
  /// Requests weather telemetry only (debug/fallback).
  Future<WeatherFeatures> getWeatherFeatures(double latitude, double longitude) async {
    final Map<String, dynamic> body = {
      'latitude': latitude,
      'longitude': longitude,
    };
    
    final responseJson = await _apiClient.post('/weather-features', body);
    return WeatherFeatures.fromJson(responseJson);
  }

  /// Requests satellite telemetry only (debug/fallback).
  Future<SentinelFeatures> getSentinelFeatures(double latitude, double longitude) async {
    final Map<String, dynamic> body = {
      'latitude': latitude,
      'longitude': longitude,
    };
    
    final responseJson = await _apiClient.post('/sentinel-features', body);
    return SentinelFeatures.fromJson(responseJson);
  }

  /// Verification health check of the backend.
  Future<bool> checkBackendHealth() async {
    try {
      final responseJson = await _apiClient.get('/health');
      return responseJson['status'] == 'healthy';
    } catch (_) {
      return false;
    }
  }
}
