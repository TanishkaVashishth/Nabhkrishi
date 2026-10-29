import 'package:cloud_firestore/cloud_firestore.dart';

class FarmModel {
  final String farmId;
  final String userId;
  final double latitude;
  final double longitude;
  final double? farmArea;
  final String? areaUnit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FarmModel({
    required this.farmId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.farmArea,
    this.areaUnit,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to create a FarmModel from a Firestore document snapshot.
  factory FarmModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FarmModel(
      farmId: doc.id,
      userId: data['userId'] ?? '',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      farmArea: data['farmArea'] != null ? (data['farmArea'] as num).toDouble() : null,
      areaUnit: data['areaUnit'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  /// Converts the FarmModel to a map structure suitable for storing in Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'farmId': farmId,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'farmArea': farmArea,
      'areaUnit': areaUnit,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Creates a copy of the FarmModel with updated fields.
  FarmModel copyWith({
    String? farmId,
    String? userId,
    double? latitude,
    double? longitude,
    double? farmArea,
    String? areaUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmModel(
      farmId: farmId ?? this.farmId,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      farmArea: farmArea ?? this.farmArea,
      areaUnit: areaUnit ?? this.areaUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
