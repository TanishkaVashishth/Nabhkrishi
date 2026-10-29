/// Reusable farm-boundary mapping feature for Flutter applications (NabhKrishi).
///
/// Provides finger-drawn field boundary tracing directly over high-resolution
/// satellite/street imagery, real geographic coordinate conversion, geodesic
/// area and perimeter calculations, polygon processing and validation,
/// and RFC 7946 GeoJSON export.
library;

// Models
export 'models/farm_boundary.dart';
export 'models/drawing_state.dart';

// Controllers
export 'controllers/farm_boundary_controller.dart';

// Widgets
export 'presentation/widgets/farm_boundary_map.dart';
export 'presentation/widgets/map_controls.dart';
export 'presentation/widgets/drawing_hud.dart';
export 'presentation/widgets/drawing_canvas_overlay.dart';
export 'presentation/widgets/map_view.dart';

// Services & Utilities
export 'services/farm_area_calculator.dart';
export 'services/geojson_service.dart';
export 'services/location_service.dart';
export 'utils/polygon_utils.dart';
export 'utils/coordinate_converter.dart';

// LatLng export convenience
export 'package:latlong2/latlong.dart' show LatLng;
