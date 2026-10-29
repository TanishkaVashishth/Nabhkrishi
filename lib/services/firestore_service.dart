import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/farm_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Saves a farm to users/{userId}/farms/{farmId}.
  /// If farmModel.farmId is empty or is a new farm, Firestore will generate an ID.
  Future<String> saveFarm(String userId, FarmModel farm) async {
    final collectionRef = _db.collection('users').doc(userId).collection('farms');
    
    // If farmId is empty, we let Firestore generate one
    DocumentReference docRef;
    if (farm.farmId.isEmpty) {
      docRef = collectionRef.doc();
    } else {
      docRef = collectionRef.doc(farm.farmId);
    }
    
    final updatedFarm = farm.copyWith(
      farmId: docRef.id,
      userId: userId,
      createdAt: farm.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await docRef.set(updatedFarm.toFirestore());
    return docRef.id;
  }

  /// Retrieves all farms for a specific user, ordered by createdAt descending.
  Future<List<FarmModel>> getUserFarms(String userId) async {
    final querySnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('farms')
        .orderBy('createdAt', descending: true)
        .get();
        
    return querySnapshot.docs.map((doc) => FarmModel.fromFirestore(doc)).toList();
  }

  /// Retrieves a specific farm document.
  Future<FarmModel?> getFarm(String userId, String farmId) async {
    final docSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('farms')
        .doc(farmId)
        .get();
        
    if (docSnapshot.exists) {
      return FarmModel.fromFirestore(docSnapshot);
    }
    return null;
  }

  /// Updates an existing farm document.
  Future<void> updateFarm(String userId, FarmModel farm) async {
    if (farm.farmId.isEmpty) {
      throw ArgumentError('Farm ID cannot be empty for updates');
    }
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('farms')
        .doc(farm.farmId);
        
    final updatedData = farm.copyWith(updatedAt: DateTime.now()).toFirestore();
    // We don't want to update createdAt if it's already set
    updatedData.remove('createdAt');
    
    await docRef.update(updatedData);
  }

  /// Deletes a specific farm document.
  Future<void> deleteFarm(String userId, String farmId) async {
    if (farmId.isEmpty) {
      throw ArgumentError('Farm ID cannot be empty for deletion');
    }
    await _db
        .collection('users')
        .doc(userId)
        .collection('farms')
        .doc(farmId)
        .delete();
  }

  /// Finds the farm closest to the given coordinates (within a threshold of 0.05 degrees, approx. 5.5km).
  Future<String?> findClosestFarm(String userId, double latitude, double longitude) async {
    final farms = await getUserFarms(userId);
    if (farms.isEmpty) return null;
    
    FarmModel? closest;
    double minDiff = 999.0;
    
    for (final farm in farms) {
      final diff = (farm.latitude - latitude).abs() + (farm.longitude - longitude).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = farm;
      }
    }
    
    // Check if closest farm is within 0.05 degrees
    if (minDiff < 0.05) {
      return closest?.farmId;
    }
    return null;
  }

  /// Saves a prediction record to users/{userId}/farms/{farmId}/predictions/{predictionId}.
  Future<void> savePredictionHistory({
    required String userId,
    required String farmId,
    required double irrigationAmount,
    required double rainfall,
    required double temperature,
    required double humidity,
    required double et0,
    required double deficit,
  }) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('farms')
        .doc(farmId)
        .collection('predictions')
        .doc();
        
    await docRef.set({
      'predictionId': docRef.id,
      'date': FieldValue.serverTimestamp(),
      'irrigationAmount': irrigationAmount,
      'rainfall': rainfall,
      'temperature': temperature,
      'humidity': humidity,
      'et0': et0,
      'deficit': deficit,
    });
  }

  /// Retrieves prediction records for a specific farm, optionally filtering by recent days.
  Future<List<Map<String, dynamic>>> getPredictionHistory(
    String userId,
    String farmId, {
    int? daysLimit,
  }) async {
    Query query = _db
        .collection('users')
        .doc(userId)
        .collection('farms')
        .doc(farmId)
        .collection('predictions')
        .orderBy('date', descending: false);
        
    if (daysLimit != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysLimit));
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate));
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data;
    }).toList();
  }

  /// Saves feedback under users/{userId}/feedback/{feedbackId}.
  Future<void> saveFeedback({
    required String userId,
    required int rating,
    required String feedback,
  }) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('feedback')
        .doc();
        
    await docRef.set({
      'feedbackId': docRef.id,
      'userId': userId,
      'rating': rating,
      'feedback': feedback,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
