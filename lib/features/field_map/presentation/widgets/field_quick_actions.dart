import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class FieldQuickActions extends StatelessWidget {
  final VoidCallback onScanWheat;
  final VoidCallback onAskNabh;
  final VoidCallback onViewInsights;
  final String language;
  final bool isHindi;

  const FieldQuickActions({
    super.key,
    required this.onScanWheat,
    required this.onAskNabh,
    required this.onViewInsights,
    this.language = 'en',
    this.isHindi = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeLanguage = language.isNotEmpty ? language : (isHindi ? 'hi' : 'en');
    final loc = AppLocalizations(activeLanguage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Two Primary Action Buttons: [ Scan Wheat ] and [ Ask Nabh ]
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onScanWheat();
                },
                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                label: Text(
                  loc.translate('scan_wheat'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onAskNabh();
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text(
                  loc.translate('ask_nabh'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                    width: 1.3,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Third Action Button: [ View Insights ]
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              onViewInsights();
            },
            icon: const Icon(Icons.insights_rounded, size: 16, color: AppColors.textSecondary),
            label: Text(
              loc.translate('view_insights'),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              backgroundColor: AppColors.surface,
            ),
          ),
        ),
      ],
    );
  }
}
