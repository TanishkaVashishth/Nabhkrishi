import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../controllers/farm_boundary_controller.dart';
import '../../models/drawing_state.dart';
import '../../models/farm_boundary.dart';
import '../../services/farm_area_calculator.dart';
import '../../services/location_service.dart';
import '../../utils/polygon_utils.dart';
import 'drawing_canvas_overlay.dart';
import 'drawing_hud.dart';
import 'map_controls.dart';
import 'map_view.dart';

/// Complete, self-contained, embeddable Flutter farm boundary mapping widget.
///
/// Designed to be embedded directly into any parent Flutter layout (e.g. [Column],
/// [Expanded], [Container], [SizedBox], bottom sheet, or dialog) without owning
/// the screen or interfering with parent navigation.
class FarmBoundaryMap extends StatefulWidget {
  /// Initial geographic center of the map.
  /// If null and no [initialBoundary] is provided, uses current device GPS or default agricultural center.
  final LatLng? initialLocation;

  /// Initial zoom level (default is 16.0, ideal for field-level viewing).
  final double initialZoom;

  /// Optional pre-existing farm boundary to load and review.
  final FarmBoundary? initialBoundary;

  /// Callback fired when the farmer confirms their drawn boundary.
  final ValueChanged<FarmBoundary> onBoundaryConfirmed;

  /// Callback fired whenever the boundary changes during review/clearing.
  final ValueChanged<FarmBoundary?>? onBoundaryChanged;

  /// Optional callback if the farmer cancels drawing.
  final VoidCallback? onCancel;

  /// Optional programmatic controller.
  final FarmBoundaryController? controller;

  /// Whether to show the Map / Satellite toggle button (default: true).
  final bool enableSatelliteSwitch;

  /// Whether to show the GPS My Location button (default: true).
  final bool enableLocationButton;

  /// Primary boundary border color (default: Agricultural Green #2E7D32).
  final Color boundaryColor;

  /// Polygon fill color (default: Translucent Green 24% opacity).
  final Color fillColor;

  /// Stroke width of the boundary line in logical pixels.
  final double strokeWidth;

  /// Optional custom street map tile URL template.
  final String? customTileUrl;

  /// Optional custom satellite tile URL template.
  final String? customSatelliteUrl;

  /// Whether to automatically zoom and center to fit [initialBoundary] if provided.
  final bool autoCenterInitialBoundary;

  final bool isHindi;
  final String? currentLanguage;

  const FarmBoundaryMap({
    super.key,
    this.initialLocation,
    this.initialZoom = 16.0,
    this.initialBoundary,
    required this.onBoundaryConfirmed,
    this.onBoundaryChanged,
    this.onCancel,
    this.controller,
    this.enableSatelliteSwitch = true,
    this.enableLocationButton = true,
    this.boundaryColor = const Color(0xFF2E7D32),
    this.fillColor = const Color(0x3D2E7D32),
    this.strokeWidth = 3.5,
    this.customTileUrl,
    this.customSatelliteUrl,
    this.autoCenterInitialBoundary = true,
    this.isHindi = false,
    this.currentLanguage,
  });

  @override
  State<FarmBoundaryMap> createState() => _FarmBoundaryMapState();
}

class _FarmBoundaryMapState extends State<FarmBoundaryMap> {
  late final MapController _mapController;
  DrawingState _state = DrawingState.idle;
  bool _isSatellite = true;
  bool _isLocating = false;

  FarmBoundary? _currentBoundary;
  List<LatLng> _liveDrawnPoints = [];
  double? _liveAreaAcres;
  String? _errorMessage;
  LatLng? _userLocation;

  // Track map camera for projection in drawing overlay
  MapCamera? _currentCamera;

  MapCamera? get _camera {
    if (_currentCamera != null) return _currentCamera;
    try {
      return _mapController.camera;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Attach external controller if provided
    widget.controller?.attachMapController(_mapController);
    widget.controller?.addListener(_handleControllerNotification);

    // If an initial boundary is provided, load it
    if (widget.initialBoundary != null) {
      _currentBoundary = widget.initialBoundary;
      _state = widget.initialBoundary!.isConfirmed
          ? DrawingState.confirmed
          : DrawingState.reviewing;
    }

    // Try to acquire device location in background if no initial location specified
    if (widget.initialLocation == null && widget.initialBoundary == null) {
      _acquireInitialLocation();
    }
  }

  @override
  void didUpdateWidget(FarmBoundaryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detachMapController();
      oldWidget.controller?.removeListener(_handleControllerNotification);
      widget.controller?.attachMapController(_mapController);
      widget.controller?.addListener(_handleControllerNotification);
    }

    if (widget.initialBoundary != oldWidget.initialBoundary &&
        widget.initialBoundary != null) {
      setState(() {
        _currentBoundary = widget.initialBoundary;
        _state = (widget.initialBoundary!.isConfirmed || _state == DrawingState.confirmed)
            ? DrawingState.confirmed
            : DrawingState.reviewing;
      });
      if (widget.autoCenterInitialBoundary) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitBoundaryCamera(widget.initialBoundary!);
        });
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.detachMapController();
    widget.controller?.removeListener(_handleControllerNotification);
    _mapController.dispose();
    super.dispose();
  }

  void _handleControllerNotification() {
    if (!mounted || widget.controller == null) return;
    final ctrl = widget.controller!;
    if (ctrl.state != _state ||
        ctrl.boundary != _currentBoundary ||
        ctrl.isSatellite != _isSatellite) {
      setState(() {
        _state = ctrl.state;
        _currentBoundary = ctrl.boundary;
        _isSatellite = ctrl.isSatellite;
      });
    }
  }

  Future<void> _acquireInitialLocation() async {
    final location = await LocationService.getCurrentLocation();
    if (mounted && location != null) {
      setState(() {
        _userLocation = location;
      });
      _mapController.move(location, widget.initialZoom);
    }
  }

  void _syncStateToController() {
    widget.controller?.updateInternalState(
      state: _state,
      boundary: _currentBoundary,
      isSatellite: _isSatellite,
    );
  }

  // --- Map Controls Handlers ---

  void _toggleSatellite() {
    setState(() {
      _isSatellite = !_isSatellite;
    });
    _syncStateToController();
  }

  Future<void> _handleLocateMe() async {
    setState(() {
      _isLocating = true;
      _errorMessage = null;
    });

    final location = await LocationService.getCurrentLocation();

    if (mounted) {
      setState(() {
        _isLocating = false;
        if (location != null) {
          _userLocation = location;
          _mapController.move(location, 16.5);
        } else {
          _errorMessage = 'Could not acquire GPS location. Please check device location settings.';
        }
      });
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom + 1.0).clamp(3.0, 19.0));
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom - 1.0).clamp(3.0, 19.0));
  }

  // --- Drawing Workflow Handlers ---

  void _startDrawing() {
    setState(() {
      _state = DrawingState.drawing;
      _currentBoundary = null;
      _liveDrawnPoints = [];
      _liveAreaAcres = null;
      _errorMessage = null;
    });
    widget.onBoundaryChanged?.call(null);
    _syncStateToController();
  }

  void _clearDrawing() {
    setState(() {
      _state = DrawingState.idle;
      _currentBoundary = null;
      _liveDrawnPoints = [];
      _liveAreaAcres = null;
      _errorMessage = null;
    });
    widget.onBoundaryChanged?.call(null);
    _syncStateToController();
  }

  void _handlePointsUpdated(List<LatLng> points) {
    double? acres;
    if (points.length >= 3) {
      acres = FarmAreaCalculator.calculateAreaAcres(points);
    }

    setState(() {
      _liveDrawnPoints = points;
      _liveAreaAcres = acres;
      _errorMessage = null;
    });
  }

  void _finishDrawing(List<LatLng> rawPoints) {
    if (rawPoints.length < 3) {
      setState(() {
        _errorMessage = 'Please trace around the farm boundary with at least 3 corner points.';
      });
      return;
    }

    // Process through simplification, deduplication, and closure pipeline
    final processedPoints = PolygonUtils.processDrawnPoints(rawPoints);

    // Validate geometry
    final validation = PolygonUtils.validatePolygon(processedPoints);
    if (!validation.isValid) {
      setState(() {
        _errorMessage = validation.errorMessage ?? 'Invalid farm boundary shape. Please try again.';
      });
      return;
    }

    final boundary = FarmBoundary.fromPoints(processedPoints);

    setState(() {
      _currentBoundary = boundary;
      _state = DrawingState.reviewing;
      _liveDrawnPoints = [];
      _liveAreaAcres = null;
      _errorMessage = null;
    });

    widget.onBoundaryChanged?.call(boundary);
    _syncStateToController();
  }

  void _confirmBoundary() {
    if (_currentBoundary == null) return;

    setState(() {
      _state = DrawingState.confirmed;
      _errorMessage = null;
    });

    _syncStateToController();
    widget.onBoundaryConfirmed(_currentBoundary!);
  }

  void _fitBoundaryCamera(FarmBoundary boundary) {
    if (boundary.points.isEmpty) return;

    double minLat = boundary.points.first.latitude;
    double maxLat = boundary.points.first.latitude;
    double minLon = boundary.points.first.longitude;
    double maxLon = boundary.points.first.longitude;

    for (final p in boundary.points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon));
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = widget.initialBoundary != null && widget.initialBoundary!.points.isNotEmpty
        ? widget.initialBoundary!.center
        : (widget.initialLocation ?? LocationService.defaultFallbackLocation);

    return ClipRRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Interactive FlutterMap
          MapView(
            mapController: _mapController,
            initialCenter: center,
            initialZoom: widget.initialZoom,
            state: _state,
            isSatellite: _isSatellite,
            boundary: _currentBoundary,
            userLocation: _userLocation,
            boundaryColor: widget.boundaryColor,
            fillColor: widget.fillColor,
            strokeWidth: widget.strokeWidth,
            customTileUrl: widget.customTileUrl,
            customSatelliteUrl: widget.customSatelliteUrl,
            onCameraChanged: (camera) {
              if (mounted && _currentCamera != camera) {
                setState(() {
                  _currentCamera = camera;
                });
              }
            },
          ),

          // 2. Gesture Canvas Overlay for finger drawing (only active during drawing mode)
          if (_state == DrawingState.drawing && _camera != null)
            DrawingCanvasOverlay(
              state: _state,
              camera: _camera!,
              strokeColor: widget.boundaryColor,
              fillColor: widget.fillColor,
              strokeWidth: widget.strokeWidth,
              activePoints: _liveDrawnPoints,
              onPointsUpdated: _handlePointsUpdated,
              onDrawingFinished: _finishDrawing,
            ),

          // 3. Floating Map Controls (Satellite, Location, Zoom)
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: MapControls(
                isSatellite: _isSatellite,
                isLocating: _isLocating,
                enableSatelliteSwitch: widget.enableSatelliteSwitch,
                enableLocationButton: widget.enableLocationButton,
                onToggleSatellite: _toggleSatellite,
                onLocateMe: _handleLocateMe,
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
              ),
            ),
          ),

          // 4. Heads-Up Display (HUD) with instructions, live stats, and actions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DrawingHud(
              state: _state,
              currentBoundary: _currentBoundary,
              liveAreaAcres: _liveAreaAcres,
              errorMessage: _errorMessage,
              onStartDrawing: _startDrawing,
              onClearDrawing: _clearDrawing,
              onDoneDrawing: () => _finishDrawing(_liveDrawnPoints),
              onRedraw: _startDrawing,
              onConfirm: _confirmBoundary,
              onCancel: widget.onCancel,
              isHindi: widget.isHindi,
              currentLanguage: widget.currentLanguage,
            ),
          ),
        ],
      ),
    );
  }
}
