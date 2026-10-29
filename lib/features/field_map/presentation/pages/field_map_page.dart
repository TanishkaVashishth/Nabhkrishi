import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../screens/nabhkrishi_chatbot_screen.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../crop_disease/presentation/pages/crop_health_scanner_page.dart';
import '../../../crop_disease/services/crop_disease_service.dart';
import '../../../home/presentation/pages/analytics_page.dart';
import '../../../language/providers/language_provider.dart';
import '../../../location/models/location_model.dart';
import '../../../location/presentation/widgets/farm_location_details_card.dart';
import '../../../location/presentation/widgets/farm_map_widget.dart';
import '../../../location/presentation/widgets/manual_coordinates_input.dart';
import '../../../location/providers/location_provider.dart';
import '../../models/satellite_field_data.dart';
import '../widgets/field_ai_status_card.dart';
import '../widgets/field_quick_actions.dart';
import '../widgets/satellite_radar_scanner_widget.dart';
import '../widgets/satellite_region_selector.dart';
import '../widgets/satellite_telemetry_card.dart';

/// Global state provider holding the latest vision & decision result
/// across crop disease scanning flows.
final latestCropDiseaseResultProvider = StateProvider<CropDiseaseResult?>(
  (ref) => null,
);

/// Dual Farm Experience Page:
/// Combines BOTH:
/// 1. EXISTING Farm Location Map (Select Farm Area, OSM, Draw Boundary, Coordinates, GPS)
/// 2. FIELD SELECTED Banner
/// 3. NEW Reference-Style Satellite Field Monitoring Experience (Satellite, Radar Sweep, Wheat Field, R1-R4)
/// 4. REGION SELECTOR (R1, R2, R3, R4)
/// 5. SATELLITE TELEMETRY (VV Mean, VV Change, Satellite Age, Demo Disclaimers)
/// 6. CROP HEALTH & AI RECOMMENDATION (Real Swin-T, Real PPO V3, Omit 4.237 t/ha)
/// 7. QUICK ACTIONS ([ Scan Wheat ], [ Ask Nabh ], [ View Insights ])
class FieldMapPage extends ConsumerStatefulWidget {
  const FieldMapPage({super.key});

  @override
  ConsumerState<FieldMapPage> createState() => _FieldMapPageState();
}

class _FieldMapPageState extends ConsumerState<FieldMapPage> {
  int _selectedRegionIndex = 0;
  String _selectedFieldName = 'My Wheat Field (Block A)';

  // Predefined farm plot profiles for the Field Selector
  final List<Map<String, dynamic>> _fieldOptions = [
    {
      'name': 'My Wheat Field (Block A)',
      'nameHi': 'मेरा गेहूं का खेत (ब्लॉक ए)',
      'namePa': 'ਮੇਰਾ ਕਣਕ ਦਾ ਖੇਤ (ਬਲਾਕ ਏ)',
      'nameBn': 'আমার গমের জমি (ব্লক এ)',
      'nameHr': 'म्हारा गेहूं का खेत (ब्लॉक ए)',
      'lat': 30.9009,
      'lng': 75.8573,
    },
    {
      'name': 'Ludhiana Research Plot 2',
      'nameHi': 'लुधियाना अनुसंधान खेत २',
      'namePa': 'ਲੁਧਿਆਣਾ ਰਿਸਰਚ ਪਲਾਟ ੨',
      'nameBn': 'লুধিয়ানা গবেষণা জমি ২',
      'nameHr': 'लुधियाना रिसर्च खेत २',
      'lat': 30.9120,
      'lng': 75.8340,
    },
    {
      'name': 'South Canal Wheat Parcel',
      'nameHi': 'दक्षिणी नहर गेहूं टुकड़ा',
      'namePa': 'ਦੱਖਣੀ ਨਹਿਰੀ ਕਣਕ ਪਲਾਟ',
      'nameBn': 'দক্ষিণ খাল গমের জমি',
      'nameHr': 'दक्षिण नहर गेहूं टुकड़ा',
      'lat': 30.8850,
      'lng': 75.8710,
    },
  ];

  Future<void> _openScanWheat(BuildContext context, bool isHindi) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CropHealthScannerPage(isHindi: isHindi),
      ),
    );
  }

  Future<void> _openAskNabh(BuildContext context, bool isHindi) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NabhKrishiChatbotScreen(isHindi: isHindi),
      ),
    );
  }

  Future<void> _openInsights(BuildContext context, bool isHindi) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalyticsPage(isHindi: isHindi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    final confirmedLoc = ref.watch(confirmedLocationProvider);
    final latestResult = ref.watch(latestCropDiseaseResultProvider);

    final isHindi = currentLanguage.toLowerCase().contains('hi');
    final loc = AppLocalizations(currentLanguage);

    final selectedRegion = kPrototypeSatelliteRegions[_selectedRegionIndex];

    final locationData = ref.watch(locationProvider);
    final isDrawingMode = locationData.mapMode == FarmMapMode.drawing;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: isDrawingMode
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==============================================================
              // SECTION 1: FIELD LOCATION (EXISTING OSM / GPS / BOUNDARY MAP)
              // ==============================================================
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.mintBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.map_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  loc.translate('select_farm_area'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.layers_outlined, color: AppColors.primary, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHindi
                          ? 'मानचित्र पर टैप करके सीमा बनाएं या खेत खोजें'
                          : 'Draw boundary, search coordinates, or use GPS location',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Existing Interactive OpenStreetMap with GPS & Drawing Controls
                    FarmMapWidget(
                      onLocationConfirmed: () {
                        final activeLoc = ref.read(locationProvider);
                        ref.read(confirmedLocationProvider.notifier).state =
                            activeLoc.copyWith(mapMode: FarmMapMode.saved);
                      },
                    ),

                    // Manual Coordinates Input (Latitude, Longitude, Locate Farm Coordinates)
                    const ManualCoordinatesInput(),

                    // Active Farm Location Details Card (Coordinates, Area, Boundary)
                    const FarmLocationDetailsCard(),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ==============================================================
              // SECTION 2: FIELD SELECTED BANNER & SELECTOR
              // ==============================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.mintBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isHindi ? 'चयनित खेत' : 'FIELD SELECTED',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceMono(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            loc.translate('tillering_stage'),
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF92400E),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Dropdown to switch active field
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFieldName,
                        isDense: true,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        items: _fieldOptions.map((f) {
                          String label = f['name'];
                          if (currentLanguage.toLowerCase().contains('hi')) {
                            label = f['nameHi'] ?? label;
                          } else if (currentLanguage.toLowerCase().contains('pa')) {
                            label = f['namePa'] ?? label;
                          } else if (currentLanguage.toLowerCase().contains('bn')) {
                            label = f['nameBn'] ?? label;
                          } else if (currentLanguage.toLowerCase().contains('hr')) {
                            label = f['nameHr'] ?? label;
                          }
                          return DropdownMenuItem<String>(
                            value: f['name'] as String,
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: AppColors.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final match = _fieldOptions.firstWhere((e) => e['name'] == val);
                            setState(() {
                              _selectedFieldName = val;
                            });
                            final lat = match['lat'] as double;
                            final lng = match['lng'] as double;
                            ref.read(locationProvider.notifier).updateCoordinate(lat, lng);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${confirmedLoc.latitude.toStringAsFixed(4)}°N, ${confirmedLoc.longitude.toStringAsFixed(4)}°E • ${loc.translate('wheat_crop')}',
                      style: GoogleFonts.spaceMono(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ==============================================================
              // SECTION 3: SATELLITE FIELD MONITOR (REFERENCE VISUAL SCENE)
              // ==============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.satellite_alt_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            loc.translate('satellite_field_scan'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF031A22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF58E0C9).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'SENTINEL-1 SAR',
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFF58E0C9),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // The Visual Native Satellite & Wheat Field Scene
              SatelliteRadarScannerWidget(
                selectedRegionIndex: _selectedRegionIndex,
                onRegionSelected: (idx) {
                  setState(() {
                    _selectedRegionIndex = idx;
                  });
                },
                language: currentLanguage,
                isHindi: isHindi,
              ),

              const SizedBox(height: 12),

              // ==============================================================
              // SECTION 4: REGION SELECTOR (R1, R2, R3, R4 Buttons)
              // ==============================================================
              SatelliteRegionSelector(
                selectedIndex: _selectedRegionIndex,
                onRegionSelected: (idx) {
                  setState(() {
                    _selectedRegionIndex = idx;
                  });
                },
                language: currentLanguage,
              ),

              const SizedBox(height: 12),

              // ==============================================================
              // SECTION 5: SATELLITE TELEMETRY CARD (VV Mean, VV Change, Age)
              // ==============================================================
              SatelliteTelemetryCard(
                region: selectedRegion,
                language: currentLanguage,
              ),

              const SizedBox(height: 18),

              // ==============================================================
              // SECTION 6: CROP HEALTH & AI RECOMMENDATION (Swin-T & PPO V3)
              // ==============================================================
              FieldAiStatusCard(
                latestResult: latestResult,
                onScanLeaf: () => _openScanWheat(context, isHindi),
                onAskChatbot: () => _openAskNabh(context, isHindi),
                language: currentLanguage,
                isHindi: isHindi,
              ),

              const SizedBox(height: 18),

              // ==============================================================
              // SECTION 7: QUICK ACTIONS ([ Scan Wheat ], [ Ask Nabh ], [ Insights ])
              // ==============================================================
              FieldQuickActions(
                onScanWheat: () => _openScanWheat(context, isHindi),
                onAskNabh: () => _openAskNabh(context, isHindi),
                onViewInsights: () => _openInsights(context, isHindi),
                language: currentLanguage,
                isHindi: isHindi,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
