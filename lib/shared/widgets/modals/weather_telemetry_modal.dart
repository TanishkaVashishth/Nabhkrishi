import '../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Micro-climate and rain telemetry modal dialog
class WeatherTelemetryModal extends StatelessWidget {
  final bool isHindi;
  final String? currentLanguage;

  const WeatherTelemetryModal({
    super.key,
    this.isHindi = false,
    this.currentLanguage,
  });

  static Future<void> show(BuildContext context, {bool isHindi = false, String? currentLanguage}) {
    return showDialog(
      context: context,
      builder: (ctx) => WeatherTelemetryModal(isHindi: isHindi, currentLanguage: currentLanguage),
    );
  }

  String get _activeLang => currentLanguage ?? (isHindi ? 'hi' : 'en');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.weatherLightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloudy_snowing, color: AppColors.weatherBlue, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.get('weather_modal_title', _activeLang),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.weatherDarkBlue,
                                ),
                              ),
                              Text(
                                AppLocalizations.get('weather_modal_subtitle', _activeLang),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.weatherBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 16),

              // Weather Telemetry Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.85,
                children: [
                  _buildMetricCard(
                    icon: Icons.thermostat,
                    iconColor: AppColors.warning,
                    label: AppLocalizations.get('temperature', _activeLang),
                    value: '22°C - 31°C',
                  ),
                  _buildMetricCard(
                    icon: Icons.water_drop,
                    iconColor: AppColors.weatherBlue,
                    label: AppLocalizations.get('humidity', _activeLang),
                    value: '68%',
                  ),
                  _buildMetricCard(
                    icon: Icons.air,
                    iconColor: AppColors.primaryMedium,
                    label: AppLocalizations.get('wind_speed', _activeLang),
                    value: '14 km/h',
                  ),
                  _buildMetricCard(
                    icon: Icons.umbrella_outlined,
                    iconColor: AppColors.weatherBlue,
                    label: AppLocalizations.get('rain_chance', _activeLang),
                    value: '25%',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Meteorological Agronomic Advisory
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mintBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.mintBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.get('met_advice_title', _activeLang),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.get('met_advice_body', _activeLang),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.primaryDark,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.weatherBlue,
                  ),
                  child: Text(
                    AppLocalizations.get('understood', _activeLang),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
