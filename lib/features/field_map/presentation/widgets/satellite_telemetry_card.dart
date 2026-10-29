import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../models/satellite_field_data.dart';

/// Telemetry card displaying SAR measurements (VV Mean, VV Change, Satellite Age)
/// for the selected field sector, with transparent prototype labeling.
class SatelliteTelemetryCard extends StatelessWidget {
  final SatelliteRegionSignal region;
  final String language;

  const SatelliteTelemetryCard({
    super.key,
    required this.region,
    this.language = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(language);
    final isDeltaPositive = region.vvChange >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF07100C), // Reference dark background
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF58E0C9).withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Sector Name + Prototype Satellite View Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF58E0C9).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        region.label,
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF58E0C9),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        region.getLocalizedName(language),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 10, color: Color(0xFFE7C96E)),
                    const SizedBox(width: 4),
                    Text(
                      loc.translate('prototype_satellite_view'),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFE7C96E),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3-Metric Horizontal Row
          Row(
            children: [
              // 1. VV Mean
              Expanded(
                child: _TelemetryMetric(
                  label: 'VV Mean',
                  value: region.vvMeanString,
                  subtext: '5.4 GHz SAR',
                  valueColor: const Color(0xFF58E0C9),
                ),
              ),
              Container(
                height: 38,
                width: 1,
                color: Colors.white.withValues(alpha: 0.10),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              // 2. VV Change
              Expanded(
                child: _TelemetryMetric(
                  label: 'VV Change',
                  value: region.vvChangeString,
                  subtext: isDeltaPositive ? 'Biomass gain' : 'Soil moisture / shift',
                  valueColor: isDeltaPositive ? const Color(0xFF58E0C9) : const Color(0xFFFFA726),
                ),
              ),
              Container(
                height: 38,
                width: 1,
                color: Colors.white.withValues(alpha: 0.10),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              // 3. Satellite Age
              Expanded(
                child: _TelemetryMetric(
                  label: 'Satellite Age',
                  value: region.ageString(language),
                  subtext: 'Sentinel-1 pass',
                  valueColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mandatory Prototype / Simulation Disclaimer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.satellite_alt_rounded, size: 12, color: Color(0xFF58E0C9)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.translate('demo_sar_disclaimer'),
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryMetric extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final Color valueColor;

  const _TelemetryMetric({
    required this.label,
    required this.value,
    required this.subtext,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceMono(
            color: Colors.white60,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtext,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: Colors.white30,
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}
