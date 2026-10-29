import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../models/drawing_state.dart';
import '../../models/farm_boundary.dart';

/// Floating Heads-Up Display (HUD) presenting instructions, live area statistics,
/// validation messages, and drawing action controls.
class DrawingHud extends StatelessWidget {
  final DrawingState state;
  final FarmBoundary? currentBoundary;
  final double? liveAreaAcres;
  final String? errorMessage;
  final VoidCallback onStartDrawing;
  final VoidCallback onClearDrawing;
  final VoidCallback onDoneDrawing;
  final VoidCallback onRedraw;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isHindi;
  final String? currentLanguage;

  const DrawingHud({
    super.key,
    required this.state,
    this.currentBoundary,
    this.liveAreaAcres,
    this.errorMessage,
    required this.onStartDrawing,
    required this.onClearDrawing,
    required this.onDoneDrawing,
    required this.onRedraw,
    required this.onConfirm,
    this.onCancel,
    this.isHindi = false,
    this.currentLanguage,
  });

  String get _activeLang => currentLanguage ?? (isHindi ? 'hi' : 'en');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error banner if validation failed
            if (errorMessage != null) ...[
              _buildErrorBanner(errorMessage!),
              const SizedBox(height: 8),
            ],

            // Content card based on state
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _buildCardForState(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForState(BuildContext context) {
    switch (state) {
      case DrawingState.idle:
        return _buildIdleCard(context);
      case DrawingState.drawing:
        return _buildDrawingCard(context);
      case DrawingState.reviewing:
        return _buildReviewingCard(context);
      case DrawingState.confirmed:
        return _buildConfirmedCard(context);
    }
  }

  Widget _buildIdleCard(BuildContext context) {
    return Container(
      key: const ValueKey('idle_hud'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onStartDrawing,
              icon: const Icon(Icons.gesture, size: 22),
              label: Text(
                AppLocalizations.get('draw_farm_boundary', _activeLang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ),
          if (onCancel != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: AppLocalizations.get('cancel', _activeLang),
              icon: const Icon(Icons.close),
              onPressed: onCancel,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawingCard(BuildContext context) {
    return Container(
      key: const ValueKey('drawing_hud'),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.edit_road,
                  size: 18,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.get('trace_boundary_instruction', _activeLang),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
              if (liveAreaAcres != null && liveAreaAcres! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${liveAreaAcres!.toStringAsFixed(2)} ${AppLocalizations.get('acres', _activeLang)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClearDrawing,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD32F2F),
                    side: const BorderSide(color: Color(0xFFFFCDD2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.get('clear', _activeLang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onDoneDrawing,
                  icon: const Icon(Icons.check, size: 20),
                  label: Text(
                    AppLocalizations.get('done', _activeLang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewingCard(BuildContext context) {
    final boundary = currentBoundary;

    return Container(
      key: const ValueKey('reviewing_hud'),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (boundary != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    size: 22,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${boundary.areaAcres.toStringAsFixed(2)} ${AppLocalizations.get('acres', _activeLang)} (${boundary.areaHectares.toStringAsFixed(2)} Ha)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      Text(
                        'Perimeter: ${boundary.perimeterMeters.toStringAsFixed(0)} m • ${boundary.points.length} vertices',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRedraw,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF455A64),
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.get('redraw', _activeLang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    AppLocalizations.get('confirm_farm', _activeLang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmedCard(BuildContext context) {
    final boundary = currentBoundary;
    return Container(
      key: const ValueKey('confirmed_hud'),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF2E7D32),
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.get('boundary_confirmed', _activeLang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                if (boundary != null)
                  Text(
                    '${boundary.areaAcres.toStringAsFixed(2)} ${AppLocalizations.get('acres', _activeLang)} (${boundary.areaHectares.toStringAsFixed(2)} Ha)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRedraw,
            child: Text(AppLocalizations.get('edit', _activeLang)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCDD2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Color(0xFFC62828),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
