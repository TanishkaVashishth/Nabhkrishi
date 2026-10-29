import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/farm_boundary.dart';
import 'geojson_service.dart';

/// Service abstraction for persisting and retrieving farm boundary polygons.
/// Currently persists GeoJSON locally via SharedPreferences.
/// Cleanly abstracted so it can be swapped or extended with a future
/// backend endpoint (e.g., POST /farm/boundary) without UI modifications.
class FarmBoundaryService {
  static const String _storageKey = 'nabhkrishi_saved_farm_boundary_geojson';

  final SharedPreferences? _prefs;

  FarmBoundaryService([this._prefs]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Saves the confirmed farm boundary locally as a GeoJSON Feature string.
  Future<bool> saveBoundary(FarmBoundary boundary) async {
    try {
      final prefs = await _getPrefs();
      final geoJsonString = GeoJsonService.toGeoJsonString(boundary);
      return await prefs.setString(_storageKey, geoJsonString);
    } catch (_) {
      return false;
    }
  }

  /// Loads the previously saved farm boundary if one exists.
  Future<FarmBoundary?> loadSavedBoundary() async {
    try {
      final prefs = await _getPrefs();
      final geoJsonString = prefs.getString(_storageKey);
      if (geoJsonString == null || geoJsonString.trim().isEmpty) {
        return null;
      }
      return GeoJsonService.fromGeoJsonString(geoJsonString);
    } catch (_) {
      return null;
    }
  }

  /// Clears the saved farm boundary.
  Future<bool> clearSavedBoundary() async {
    try {
      final prefs = await _getPrefs();
      return await prefs.remove(_storageKey);
    } catch (_) {
      return false;
    }
  }
}

/// Riverpod provider for FarmBoundaryService
final farmBoundaryServiceProvider = Provider<FarmBoundaryService>((ref) {
  return FarmBoundaryService();
});
