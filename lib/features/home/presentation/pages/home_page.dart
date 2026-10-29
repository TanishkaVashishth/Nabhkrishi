import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'package:nabhkrishi/core/localization/app_localizations.dart';
import 'package:nabhkrishi/core/theme/app_colors.dart';
import 'package:nabhkrishi/features/crop_disease/presentation/pages/crop_health_scanner_page.dart';
import 'package:nabhkrishi/features/field_map/presentation/pages/field_map_page.dart';
import 'package:nabhkrishi/features/home/presentation/pages/analytics_page.dart';
import 'package:nabhkrishi/features/irrigation/providers/irrigation_provider.dart';
import 'package:nabhkrishi/features/language/providers/language_provider.dart';
import 'package:nabhkrishi/features/location/models/location_model.dart';
import 'package:nabhkrishi/features/location/presentation/widgets/farm_location_details_card.dart';
import 'package:nabhkrishi/features/location/presentation/widgets/farm_map_widget.dart';
import 'package:nabhkrishi/features/location/presentation/widgets/manual_coordinates_input.dart';
import 'package:nabhkrishi/features/location/providers/location_provider.dart';
import 'package:nabhkrishi/features/profile/presentation/pages/profile_page.dart';
import 'package:nabhkrishi/screens/nabhkrishi_chatbot_screen.dart';
import 'package:nabhkrishi/services/firestore_service.dart';
import 'package:nabhkrishi/shared/widgets/app_card.dart';
import 'package:nabhkrishi/shared/widgets/bento_stat_card.dart';
import 'package:nabhkrishi/shared/widgets/circular_health_gauge.dart';
import 'package:nabhkrishi/shared/widgets/floating_bottom_nav_bar.dart';
import 'package:nabhkrishi/shared/widgets/modals/agronomic_advisory_modal.dart';
import 'package:nabhkrishi/shared/widgets/modals/weather_telemetry_modal.dart';
import 'package:nabhkrishi/shared/widgets/ppo_decision_card.dart';
import 'package:nabhkrishi/shared/widgets/top_farmer_app_bar.dart';

class HomePage extends ConsumerStatefulWidget {
  final String language;
  final String farmerName;
  final int streakDays;

  const HomePage({
    super.key,
    required this.language,
    this.farmerName = '',
    this.streakDays = 1,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(languageProvider.notifier).setLanguage(widget.language);
    });
  }

  void _onTabSelected(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _openProfile(String currentLanguage) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          isHindi: currentLanguage == 'Hindi' || currentLanguage == 'hi',
          currentLanguage: currentLanguage,
        ),
      ),
    );
  }

  void _openWeatherModal(BuildContext context, String currentLanguage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WeatherTelemetryModal(
        isHindi: currentLanguage == 'Hindi' || currentLanguage == 'hi',
        currentLanguage: currentLanguage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top App Bar inspired by reference top_app_bar.dart
                TopFarmerAppBar(
                  activeFieldName: AppLocalizations(currentLanguage).translate('my_wheat_field'),
                  isHindi: isHindi,
                  currentLanguage: currentLanguage,
                  onLanguageChanged: (lang) {
                    ref.read(languageProvider.notifier).setLanguage(lang);
                  },
                  onOpenWeather: () => _openWeatherModal(context, currentLanguage),
                  onOpenProfile: () => _openProfile(currentLanguage),
                ),

                // 5 Tab Indexed Stack
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      // Tab 0: Home Overview Dashboard
                      _DashboardOverview(
                        farmerName: widget.farmerName,
                        streakDays: widget.streakDays,
                        isHindi: isHindi,
                        currentLanguage: currentLanguage,
                        onNavigateTab: _onTabSelected,
                      ),
                      // Tab 1: Analytics / Insights Page
                      AnalyticsPage(
                        isHindi: isHindi,
                        currentLanguage: currentLanguage,
                      ),
                      // Tab 2: Full-screen Crop Health & Swin-T Scanner Page
                      CropHealthScannerPage(
                        isHindi: isHindi,
                        currentLanguage: currentLanguage,
                      ),
                      // Tab 3: Interactive Field & Satellite Radar Map Page
                      const FieldMapPage(),
                      // Tab 4: Multilingual RAG Chatbot
                      NabhKrishiChatbotScreen(
                        isHindi: isHindi,
                        currentLanguage: currentLanguage,
                        bottomPadding: 84,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Frosted Bottom Navigation Bar (hidden when software keyboard is open)
          if (MediaQuery.of(context).viewInsets.bottom == 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingBottomNavBar(
                selectedIndex: _selectedTabIndex,
                onTabSelected: _onTabSelected,
                isHindi: isHindi,
                currentLanguage: currentLanguage,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// DASHBOARD OVERVIEW VIEW (Tab 0)
// ============================================================================

class _DashboardOverview extends ConsumerWidget {
  final String farmerName;
  final int streakDays;
  final bool isHindi;
  final String? currentLanguage;
  final ValueChanged<int> onNavigateTab;

  const _DashboardOverview({
    required this.farmerName,
    required this.streakDays,
    required this.isHindi,
    this.currentLanguage,
    required this.onNavigateTab,
  });

  String _timeGreeting(String lang) {
    final code = AppLocalizations.normalizeCode(lang);
    final hour = DateTime.now().hour;
    if (hour < 12) {
      switch (code) {
        case 'hi': return 'सुप्रभात';
        case 'pa': return 'ਸਤਿ ਸ਼੍ਰੀ ਅਕਾਲ';
        case 'bn': return 'সুপ্রভাত';
        case 'hr': return 'राम राम';
        case 'hinglish': return 'Good morning';
        default: return 'Good morning';
      }
    }
    if (hour < 17) {
      switch (code) {
        case 'hi': return 'नमस्ते';
        case 'pa': return 'ਸਤਿ ਸ਼੍ਰੀ ਅਕਾਲ';
        case 'bn': return 'নমস্কার';
        case 'hr': return 'राम राम';
        case 'hinglish': return 'Namaste';
        default: return 'Good afternoon';
      }
    }
    switch (code) {
      case 'hi': return 'शुभ संध्या';
      case 'pa': return 'ਸ਼ੁਭ ਸ਼ਾਮ';
      case 'bn': return 'শুভ সন্ধ্যা';
      case 'hr': return 'शुभ संझा';
      case 'hinglish': return 'Shubh sandhya';
      default: return 'Good evening';
    }
  }

  void _openAdvisoryModal(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AgronomicAdvisoryModal(
        isHindi: lang == 'hi' || lang == 'Hindi',
        currentLanguage: lang,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String activeLang = currentLanguage ?? ref.watch(languageProvider);
    final confirmedLoc = ref.watch(confirmedLocationProvider);
    final centroid = confirmedLoc.centroid;
    final latestResult = ref.watch(latestCropDiseaseResultProvider);

    final locationData = ref.watch(locationProvider);
    final isDrawingMode = locationData.mapMode == FarmMapMode.drawing;

    final name = farmerName.trim().isEmpty
        ? (isHindi ? 'किसान मित्र' : 'Farmer')
        : farmerName.trim();

    return SingleChildScrollView(
      physics: isDrawingMode
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Welcome Card & Streak Banner
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.mintBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          AppLocalizations.get('days_together', activeLang, {'days': '$streakDays'}),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _openAdvisoryModal(context, activeLang),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 13, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.get('icar_advisory', activeLang),
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF92400E),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${_timeGreeting(activeLang)}, $name',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.get('field_crop_summary', activeLang),
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Circular Health Gauge & Bento Telemetry Cards
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final gaugeSize = (constraints.maxWidth - 4).clamp(80.0, 140.0);
                        return CircularHealthGauge(
                          score: latestResult != null
                              ? (latestResult.isHealthy ? 92 : 68)
                              : 84,
                          isHindi: isHindi,
                          currentLanguage: activeLang,
                          size: gaugeSize,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.get('current_status', activeLang),
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latestResult != null
                            ? latestResult.getLocalizedDiseaseName(activeLang)
                            : AppLocalizations.get('wheat_optimal', activeLang),
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.get('satellite_weather_favorable', activeLang),
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => onNavigateTab(2),
                        child: Text(
                          AppLocalizations.get('scan_foliage_link', activeLang),
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Bento Grid Telemetry Cards
          Row(
            children: [
              Expanded(
                child: BentoStatCard(
                  icon: Icons.water_drop_rounded,
                  iconBg: AppColors.mintBg,
                  iconColor: AppColors.primary,
                  label: AppLocalizations.get('water_demand', activeLang),
                  value: '0.0 mm',
                  valueColor: AppColors.primary,
                  subtitle: AppLocalizations.get('low_stress_short', activeLang),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BentoStatCard(
                  icon: Icons.grain_rounded,
                  iconBg: const Color(0xFFE1F5FE),
                  iconColor: AppColors.weatherBlue,
                  label: AppLocalizations.get('rainfall_7d_short', activeLang),
                  value: '18.4 mm',
                  valueColor: AppColors.weatherBlue,
                  subtitle: AppLocalizations.get('adequate', activeLang),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: BentoStatCard(
                  icon: Icons.radar_rounded,
                  iconBg: AppColors.mintBg,
                  iconColor: AppColors.accent,
                  label: AppLocalizations.get('radar_backscatter', activeLang),
                  value: '-12.8 dB',
                  valueColor: AppColors.accent,
                  subtitle: 'Sentinel-1',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BentoStatCard(
                  icon: Icons.wb_sunny_rounded,
                  iconBg: const Color(0xFFFFF4E5),
                  iconColor: AppColors.warning,
                  label: AppLocalizations.get('avg_temp', activeLang),
                  value: '26.5 °C',
                  valueColor: AppColors.warning,
                  subtitle: AppLocalizations.get('normal', activeLang),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 4. Latest Wheat Scan & PPO V3 Decision Section
          if (latestResult != null) ...[
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.biotech_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                AppLocalizations.get('recent_foliage_diagnosis', activeLang),
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
                          color: AppColors.mintBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${latestResult.confidencePercent}% ${AppLocalizations.get('confidence_short', activeLang)}',
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    latestResult.getLocalizedDiseaseName(activeLang),
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (latestResult.decision != null) ...[
                    const SizedBox(height: 12),
                    PPODecisionCard(
                      decision: latestResult.decision!,
                      isHindi: isHindi,
                      currentLanguage: activeLang,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // 5. Quick Actions Row
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.get('quick_actions', activeLang),
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onNavigateTab(2),
                        icon: const Icon(Icons.camera_alt_rounded, size: 13),
                        label: Text(
                          AppLocalizations.get('scan_leaf', activeLang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onNavigateTab(4),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 13),
                        label: Text(
                          AppLocalizations.get('ask_nabh', activeLang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onNavigateTab(3),
                        icon: const Icon(Icons.map_outlined, size: 13),
                        label: Text(
                          AppLocalizations.get('field_map', activeLang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.borderLight),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 6. Farm Selection & Interactive Map Card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.get('select_farm_area', activeLang),
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.layers_outlined, color: AppColors.primary, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.get('farm_map_instruction', activeLang),
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 14),
                FarmMapWidget(
                  onLocationConfirmed: () {
                    final activeLoc = ref.read(locationProvider);
                    ref.read(confirmedLocationProvider.notifier).state =
                        activeLoc.copyWith(mapMode: FarmMapMode.saved);
                  },
                ),
                const ManualCoordinatesInput(),
                const FarmLocationDetailsCard(),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 7. Dynamic Telemetry & DQN Irrigation Recommendation Section
          _IrrigationRecommendationSection(
            centroid: centroid,
            isHindi: isHindi,
            currentLanguage: activeLang,
          ),

          const SizedBox(height: 18),

          // 8. Farmer Feedback Card
          _FeedbackCard(currentLanguage: activeLang),
        ],
      ),
    );
  }
}

// ============================================================================
// IRRIGATION RECOMMENDATION SECTION (Performance Isolated)
// ============================================================================

class _IrrigationRecommendationSection extends ConsumerWidget {
  final LatLng centroid;
  final bool isHindi;
  final String? currentLanguage;

  const _IrrigationRecommendationSection({
    required this.centroid,
    required this.isHindi,
    this.currentLanguage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final coordinateKey =
        '${centroid.latitude.toStringAsFixed(4)},${centroid.longitude.toStringAsFixed(4)}';
    final irrigationState = ref.watch(irrigationProvider(coordinateKey));

    if (irrigationState.isLoading) {
      return AppCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.translate(irrigationState.loadingStage, currentLanguage),
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.get('processing_radar_weather', currentLanguage),
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    } else if (irrigationState.errorMessage != null) {
      return AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 36),
            const SizedBox(height: 10),
            Text(
              context.translate(irrigationState.errorMessage!, currentLanguage),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(irrigationProvider(coordinateKey).notifier)
                    .fetchRecommendation(centroid.latitude, centroid.longitude);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                context.translate('retry_button', currentLanguage),
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else if (irrigationState.data != null) {
      final data = irrigationState.data!;
      final rec = data.recommendation;

      return AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.mintBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.translate('irrigation_recommendation', currentLanguage),
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        rec.irrigationMm > 0
                            ? context.translate('apply_irrigation', currentLanguage,
                                arguments: {'amount': '${rec.irrigationMm.toInt()}'})
                            : context.translate('no_irrigation', currentLanguage),
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.borderLight, height: 1),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.get('irrigation_decision_footnote', currentLanguage),
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}


// ============================================================================
// FARMER FEEDBACK CARD & DIALOG
// ============================================================================

class _FeedbackCard extends ConsumerWidget {
  final String? currentLanguage;
  const _FeedbackCard({this.currentLanguage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLang = currentLanguage ?? ref.watch(languageProvider);
    final isHindi = activeLang == 'Hindi' || activeLang == 'hi';

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.get('feedback_title', activeLang),
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.get('feedback_subtitle', activeLang),
            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _FeedbackDialog(
                    isHindi: isHindi,
                    currentLanguage: activeLang,
                  ),
                );
              },
              child: Text(
                AppLocalizations.get('give_feedback', activeLang),
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackDialog extends ConsumerStatefulWidget {
  final bool isHindi;
  final String? currentLanguage;
  const _FeedbackDialog({required this.isHindi, this.currentLanguage});

  @override
  ConsumerState<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<_FeedbackDialog> {
  int _rating = 5;
  final TextEditingController _feedbackController = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final activeLang = widget.currentLanguage ?? ref.watch(languageProvider);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        AppLocalizations.get('farmer_feedback_form', activeLang),
        style: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.get('select_rating', activeLang),
              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final filled = starIndex <= _rating;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled ? const Color(0xFFFFB300) : AppColors.textTertiary,
                      size: 28,
                    ),
                  ),
                  onPressed: () => setState(() => _rating = starIndex),
                );
              }),
            ),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.get('comments_optional', activeLang),
              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 3,
                style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 12),
                decoration: InputDecoration(
                  hintText: AppLocalizations.get('comments_hint', activeLang),
                  hintStyle: GoogleFonts.poppins(color: AppColors.textTertiary, fontSize: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(
            AppLocalizations.get('cancel', activeLang),
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _submitting ? null : _submitFeedback,
          child: _submitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  AppLocalizations.get('submit', activeLang),
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    setState(() => _submitting = true);
    final activeLang = widget.currentLanguage ?? ref.read(languageProvider);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await ref.read(firestoreServiceProvider).saveFeedback(
              userId: user.uid,
              rating: _rating,
              feedback: _feedbackController.text,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.get('feedback_thanks', activeLang),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.get('error_title', activeLang)}: $e',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
