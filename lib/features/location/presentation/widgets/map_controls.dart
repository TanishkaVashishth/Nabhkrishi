import 'package:flutter/material.dart';

/// Floating map control buttons:
/// - Map / Satellite layer toggle
/// - My Location GPS button
/// - Zoom In / Zoom Out buttons
class MapControls extends StatelessWidget {
  final bool isSatellite;
  final bool isLocating;
  final VoidCallback onToggleSatellite;
  final VoidCallback onLocateMe;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final bool enableSatelliteSwitch;
  final bool enableLocationButton;

  const MapControls({
    super.key,
    required this.isSatellite,
    required this.isLocating,
    required this.onToggleSatellite,
    required this.onLocateMe,
    required this.onZoomIn,
    required this.onZoomOut,
    this.enableSatelliteSwitch = true,
    this.enableLocationButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (enableSatelliteSwitch) ...[
          _MapControlButton(
            tooltip: isSatellite ? 'Switch to Street Map' : 'Switch to Satellite',
            onPressed: onToggleSatellite,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSatellite ? Icons.map_outlined : Icons.satellite_alt_outlined,
                  size: 20,
                  color: const Color(0xFF1B5E20),
                ),
                const SizedBox(width: 4),
                Text(
                  isSatellite ? 'Map' : 'Satellite',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (enableLocationButton) ...[
          _MapControlButton(
            tooltip: 'My Location',
            onPressed: isLocating ? null : onLocateMe,
            child: isLocating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
                    ),
                  )
                : const Icon(
                    Icons.my_location,
                    size: 20,
                    color: Color(0xFF1B5E20),
                  ),
          ),
          const SizedBox(height: 8),
        ],
        // Zoom controls container
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ZoomButton(
                icon: Icons.add,
                tooltip: 'Zoom In',
                onPressed: onZoomIn,
              ),
              Container(
                height: 1,
                width: 32,
                color: Colors.black.withValues(alpha: 0.08),
              ),
              _ZoomButton(
                icon: Icons.remove,
                tooltip: 'Zoom Out',
                onPressed: onZoomOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String tooltip;

  const _MapControlButton({
    required this.child,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF263238),
            ),
          ),
        ),
      ),
    );
  }
}
