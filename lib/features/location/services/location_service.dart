import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Modular, resilient location service for obtaining the device GPS position.
/// Handles permission denied, permanently denied, disabled GPS, and timeouts
/// gracefully without crashing the application.
class LocationService {
  const LocationService._();

  /// Default fallback coordinates (Geographic center of India: 20.5937° N, 78.9629° E),
  /// suitable for NabhKrishi agricultural contexts if GPS is unavailable.
  static const LatLng defaultFallbackLocation = LatLng(20.5937, 78.9629);

  /// Requests device location with graceful fallbacks.
  /// Returns `null` if permission is denied, GPS is disabled, or timed out.
  static Future<LatLng?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 7),
  }) async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services are disabled on the device.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permission denied by user.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permissions are permanently denied.');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 7),
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('[LocationService] Failed to acquire current location: $e');
      return null;
    }
  }

  /// Checks whether location services are available and permitted.
  static Future<bool> hasPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }
}
