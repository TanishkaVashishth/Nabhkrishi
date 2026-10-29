import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/drawing_state.dart';
import '../../models/farm_boundary.dart';

/// The interactive map view powered by [FlutterMap].
/// Displays OpenStreetMap (Streets) or Esri World Imagery (Satellite) tiles,
/// along with geographic polygon layers and GPS user location marker.
class MapView extends StatelessWidget {
  final MapController mapController;
  final LatLng initialCenter;
  final double initialZoom;
  final DrawingState state;
  final bool isSatellite;
  final FarmBoundary? boundary;
  final LatLng? userLocation;
  final Color boundaryColor;
  final Color fillColor;
  final double strokeWidth;
  final String? customTileUrl;
  final String? customSatelliteUrl;
  final ValueChanged<MapCamera>? onCameraChanged;

  const MapView({
    super.key,
    required this.mapController,
    required this.initialCenter,
    required this.initialZoom,
    required this.state,
    required this.isSatellite,
    this.boundary,
    this.userLocation,
    required this.boundaryColor,
    required this.fillColor,
    required this.strokeWidth,
    this.customTileUrl,
    this.customSatelliteUrl,
    this.onCameraChanged,
  });

  static const String defaultOsmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String defaultSatelliteUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  @override
  Widget build(BuildContext context) {
    // When drawing, disable map pan/zoom/rotate to allow finger tracing without moving the map
    final int interactiveFlags = state == DrawingState.drawing
        ? InteractiveFlag.none
        : InteractiveFlag.all;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        minZoom: 3.0,
        maxZoom: 19.0,
        interactionOptions: InteractionOptions(
          flags: interactiveFlags,
        ),
        onPositionChanged: (camera, hasGesture) {
          onCameraChanged?.call(camera);
        },
      ),
      children: [
        // 1. Tile Layer (Street or Satellite)
        TileLayer(
          key: ValueKey('tile_layer_${isSatellite ? "sat" : "street"}'),
          urlTemplate: isSatellite
              ? (customSatelliteUrl ?? defaultSatelliteUrl)
              : (customTileUrl ?? defaultOsmUrl),
          userAgentPackageName: 'in.nabhkrishi.farm_boundary_map',
          maxNativeZoom: isSatellite ? 19 : 19,
          maxZoom: 20,
        ),

        // 2. Geographic Polygon Layer for Confirmed or Reviewing boundaries
        if (boundary != null && boundary!.points.length >= 3)
          PolygonLayer(
            polygons: [
              Polygon(
                points: boundary!.points,
                color: fillColor,
                borderColor: boundaryColor,
                borderStrokeWidth: strokeWidth,
              ),
            ],
          ),

        // 3. User GPS Location Marker (if available)
        if (userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: userLocation!,
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.navigation,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
