import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../data/repositories/irrigation_repository.dart';
import '../models/irrigation_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/firestore_service.dart';

class IrrigationState {
  final bool isLoading;
  final String loadingStage; // key for localization e.g. 'loading_weather'
  final LocationPredictionResponse? data;
  final String? errorMessage;
  final bool isColdStart;

  IrrigationState({
    this.isLoading = false,
    this.loadingStage = '',
    this.data,
    this.errorMessage,
    this.isColdStart = false,
  });

  IrrigationState copyWith({
    bool? isLoading,
    String? loadingStage,
    LocationPredictionResponse? data,
    String? errorMessage,
    bool? isColdStart,
  }) {
    return IrrigationState(
      isLoading: isLoading ?? this.isLoading,
      loadingStage: loadingStage ?? this.loadingStage,
      data: data ?? this.data,
      errorMessage: errorMessage, // We clear error message if not explicitly passed
      isColdStart: isColdStart ?? this.isColdStart,
    );
  }
}

class IrrigationNotifier extends FamilyNotifier<IrrigationState, String> {
  late final IrrigationRepository _repository;
  bool _isFetching = false;

  @override
  IrrigationState build(String arg) {
    _repository = IrrigationRepository();
    
    // Parse the coordinate key 'latitude,longitude'
    final parts = arg.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat != null && lng != null) {
        // Trigger fetch asynchronously to avoid modifying state during the build phase
        Future.microtask(() => fetchRecommendation(lat, lng));
        return IrrigationState(
          isLoading: true,
          loadingStage: 'connecting_to_nabhkrishi',
        );
      }
    }
    
    return IrrigationState();
  }

  Future<void> fetchRecommendation(double latitude, double longitude) async {
    if (_isFetching) return;
    _isFetching = true;

    if (!state.isLoading) {
      state = IrrigationState(
        isLoading: true,
        loadingStage: 'connecting_to_nabhkrishi',
      );
    }

    // Setup a timer to simulate loading stages to the farmer,
    // since the backend /predict-location endpoint aggregates all data in a single call.
    int stage = 0;
    final List<String> stages = [
      'connecting_to_nabhkrishi',
      'fetching_weather_satellite',
      'loading_analysis',
      'loading_recommendation'
    ];

    Timer? stageTimer;
    stageTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (stage < stages.length - 1) {
        stage++;
        if (state.isLoading) {
          state = state.copyWith(loadingStage: stages[stage]);
        }
      } else {
        timer.cancel();
      }
    });

    // Also handle Render cold starts. If the API takes more than 5 seconds,
    // show "Starting NabhKrishi services..." instead of immediately failing or showing a generic loading message.
    final coldStartTimer = Timer(const Duration(seconds: 5), () {
      if (state.isLoading) {
        state = state.copyWith(loadingStage: 'loading_cold_start', isColdStart: true);
      }
    });

    try {
      final response = await _repository.predictLocation(latitude, longitude);
      
      stageTimer.cancel();
      coldStartTimer.cancel();
      _isFetching = false;
      
      state = IrrigationState(
        isLoading: false,
        data: response,
      );

      _saveHistoryInBackground(latitude, longitude, response);
    } catch (e, stackTrace) {
      stageTimer.cancel();
      coldStartTimer.cancel();
      _isFetching = false;
      
      developer.log('Irrigation prediction flow error: $e\n$stackTrace');
      
      String userError = 'error_generic';
      if (e is NetworkException) {
        if (e.statusCode == 502) {
          userError = 'error_502';
        } else if (e.message.contains('warming up') || e.message.contains('timed out') || e.message.contains('took too long')) {
          userError = 'loading_cold_start';
        } else {
          userError = e.message;
        }
      } else {
        userError = e.toString();
      }
      
      state = IrrigationState(
        isLoading: false,
        errorMessage: userError,
      );
    }
  }

  Future<void> _saveHistoryInBackground(
    double latitude,
    double longitude,
    LocationPredictionResponse response,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log('Warning: No authenticated user. Cannot save prediction history.');
        return;
      }
      
      final firestoreService = ref.read(firestoreServiceProvider);
      
      // 1. Find closest farm matching the coordinates
      final farmId = await firestoreService.findClosestFarm(user.uid, latitude, longitude);
      if (farmId == null) {
        developer.log('Warning: No matching saved farm found for coordinates ($latitude, $longitude). History not saved.');
        return;
      }
      
      // 2. Save prediction history
      await firestoreService.savePredictionHistory(
        userId: user.uid,
        farmId: farmId,
        irrigationAmount: response.recommendation.irrigationMm,
        rainfall: response.weatherFeatures.rain7d,
        temperature: response.weatherFeatures.tempMean,
        humidity: response.weatherFeatures.humidityMean,
        et0: response.weatherFeatures.et07d,
        deficit: response.weatherFeatures.deficit7d,
      );
      developer.log('Successfully saved prediction history for farm $farmId.');
    } catch (e, stackTrace) {
      developer.log('Warning: Failed to save prediction history to Firestore: $e\n$stackTrace');
    }
  }
}

final irrigationProvider = NotifierProviderFamily<IrrigationNotifier, IrrigationState, String>(() {
  return IrrigationNotifier();
});
