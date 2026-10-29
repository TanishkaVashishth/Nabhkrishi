import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../controllers/farm_boundary_controller.dart';
import '../../models/drawing_state.dart';
import '../../models/farm_boundary.dart';
import '../../models/location_model.dart';
import '../../providers/location_provider.dart';
import '../../../language/providers/language_provider.dart';
import 'farm_boundary_map.dart';

/// FarmMapWidget: Hosts the EXACT 2D Interactive Farm Boundary Map
/// ported from ChascalX/New_Nabhkrishi_Map.
///
/// Features:
/// - Real 2D interactive OpenStreetMap & Esri Satellite imagery layers.
/// - Floating top-right controls (Satellite toggle, GPS My Location with spinner, Zoom +/-).
/// - Transparent gesture canvas overlay with green halo start point indicator and zero-latency tracing.
/// - Floating Heads-Up Display (HUD) with 4 states:
///     1. Idle ("Draw Farm Boundary")
///     2. Drawing ("Trace around your farm boundary", live acreage, Clear, Done)
///     3. Reviewing (Acreage in Acres & Ha, perimeter, vertices, Redraw, Confirm Farm)
///     4. Confirmed ("Farm Boundary Confirmed", acreage, Edit)
/// - Geodesic area calculation on WGS-84 sphere in international acres.
/// - Full RFC 7946 GeoJSON output and local persistence.
class FarmMapWidget extends ConsumerStatefulWidget {
  final VoidCallback onLocationConfirmed;

  const FarmMapWidget({
    super.key,
    required this.onLocationConfirmed,
  });

  @override
  ConsumerState<FarmMapWidget> createState() => _FarmMapWidgetState();
}

class _FarmMapWidgetState extends ConsumerState<FarmMapWidget> {
  late final FarmBoundaryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FarmBoundaryController();
    _controller.addListener(_onControllerStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerStateChanged() {
    final mode = _controller.state == DrawingState.drawing
        ? FarmMapMode.drawing
        : (_controller.boundary != null ? FarmMapMode.saved : FarmMapMode.normal);
    final currentMode = ref.read(locationProvider).mapMode;
    if (currentMode != mode) {
      ref.read(locationProvider.notifier).setMapMode(mode);
    }
  }

  Future<void> _handleBoundaryConfirmed(FarmBoundary boundary) async {
    // 1. Update Riverpod location state & local persistence
    await ref.read(locationProvider.notifier).setConfirmedBoundary(boundary);

    // 2. Fire parent callback
    widget.onLocationConfirmed();
  }

  void _handleBoundaryChanged(FarmBoundary? boundary) {
    if (boundary != null) {
      ref.read(locationProvider.notifier).setBoundary(boundary.points);
    } else {
      ref.read(locationProvider.notifier).clearDrawing();
      ref.read(locationProvider.notifier).setMapMode(FarmMapMode.normal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationData = ref.watch(locationProvider);
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage.toLowerCase() == 'hindi' || currentLanguage.toLowerCase() == 'hi';

    // Listen to external coordinate updates (e.g. from GPS or Manual Input)
    ref.listen(locationProvider, (previous, next) {
      if (previous == null ||
          previous.latitude != next.latitude ||
          previous.longitude != next.longitude) {
        if (_controller.state != DrawingState.drawing) {
          _controller.moveTo(LatLng(next.latitude, next.longitude), zoom: 16.0);
        }
      }
    });

    return Container(
      height: 520,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FarmBoundaryMap(
          controller: _controller,
          initialLocation: LatLng(locationData.latitude, locationData.longitude),
          initialBoundary: locationData.activeBoundary,
          onBoundaryConfirmed: _handleBoundaryConfirmed,
          onBoundaryChanged: _handleBoundaryChanged,
          isHindi: isHindi,
          currentLanguage: currentLanguage,
          onCancel: () {
            _controller.clear();
            ref.read(locationProvider.notifier).clearBoundary();
          },
        ),
      ),
    );
  }
}
