import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../models/satellite_field_data.dart';

/// Selectable region pills matching the exact appearance from NabhKrishi-Web reference:
/// - Selected: turquoise border (#58E0C9), turquoise tinted background, turquoise text
/// - Unselected: subtle dark border, muted text
class SatelliteRegionSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onRegionSelected;
  final String language;

  const SatelliteRegionSelector({
    super.key,
    required this.selectedIndex,
    required this.onRegionSelected,
    this.language = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(language);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF07100C), // Reference dark green background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF58E0C9).withValues(alpha: 0.20),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  loc.translate('tap_sector_hint'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFF58E0C9),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF58E0C9).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${kPrototypeSatelliteRegions[selectedIndex].label} ACTIVE',
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFF58E0C9),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(kPrototypeSatelliteRegions.length, (index) {
              final region = kPrototypeSatelliteRegions[index];
              final isSelected = index == selectedIndex;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < kPrototypeSatelliteRegions.length - 1 ? 8.0 : 0,
                  ),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onRegionSelected(index);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF58E0C9).withValues(alpha: 0.16)
                            : const Color(0xFF0C1D16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF58E0C9)
                              : Colors.white.withValues(alpha: 0.10),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF58E0C9).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            region.label,
                            style: GoogleFonts.spaceMono(
                              color: isSelected ? const Color(0xFF58E0C9) : Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            region.vvMeanString,
                            style: GoogleFonts.spaceMono(
                              color: isSelected
                                  ? const Color(0xFF58E0C9).withValues(alpha: 0.85)
                                  : Colors.white38,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
