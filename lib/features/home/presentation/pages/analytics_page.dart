import '../../../../core/localization/app_localizations.dart';
import '../../../language/providers/language_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/farm_model.dart';
import '../../../../services/firestore_service.dart';
import '../../../../shared/widgets/app_card.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  final bool isHindi;
  final String? currentLanguage;
  const AnalyticsPage({
    super.key,
    required this.isHindi,
    this.currentLanguage,
  });

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  String get _activeLang => widget.currentLanguage ?? ref.watch(languageProvider);

  String? _selectedFarmId;
  int _selectedFilterDays = 7; // 7, 30, or 0 (All)
  List<FarmModel> _farms = [];
  List<Map<String, dynamic>> _predictions = [];
  bool _loadingFarms = true;
  bool _loadingPredictions = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    setState(() {
      _loadingFarms = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _loadingFarms = false;
          _errorMessage = AppLocalizations.get('sign_in_first', _activeLang);
        });
        return;
      }

      final firestoreService = ref.read(firestoreServiceProvider);
      final farmsList = await firestoreService.getUserFarms(user.uid);

      setState(() {
        _farms = farmsList;
        _loadingFarms = false;
        if (farmsList.isNotEmpty) {
          _selectedFarmId = farmsList.first.farmId;
          _loadPredictionHistory();
        }
      });
    } catch (e) {
      setState(() {
        _loadingFarms = false;
        _errorMessage = '${AppLocalizations.get('failed_load_farms', _activeLang)}: $e';
      });
    }
  }

  Future<void> _loadPredictionHistory() async {
    if (_selectedFarmId == null) return;

    setState(() {
      _loadingPredictions = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final firestoreService = ref.read(firestoreServiceProvider);
      final predictionsList = await firestoreService.getPredictionHistory(
        user.uid,
        _selectedFarmId!,
        daysLimit: _selectedFilterDays > 0 ? _selectedFilterDays : null,
      );

      setState(() {
        _predictions = predictionsList;
        _loadingPredictions = false;
      });
    } catch (e) {
      setState(() {
        _loadingPredictions = false;
        _errorMessage = '${AppLocalizations.get('failed_load_predictions', _activeLang)}: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingFarms) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(color: AppColors.danger, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_farms.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.analytics_outlined, color: AppColors.textMuted, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.get('no_saved_farms', _activeLang),
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.get('save_farm_first', _activeLang),
                  style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPredictionHistory,
          color: AppColors.primary,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              // Title Header
              Text(
                AppLocalizations.get('insights_analytics', _activeLang),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                AppLocalizations.get('insights_subtitle', _activeLang),
                style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Farm Selector Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFarmId,
                    dropdownColor: Colors.white,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    items: _farms.map((farm) {
                      final areaStr = farm.farmArea != null ? ' (${farm.farmArea!.toStringAsFixed(1)} ha)' : '';
                      return DropdownMenuItem<String>(
                        value: farm.farmId,
                        child: Text(
                          '${AppLocalizations.get('field_label', _activeLang)} ${farm.latitude.toStringAsFixed(3)}, ${farm.longitude.toStringAsFixed(3)}$areaStr',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedFarmId = val;
                        });
                        _loadPredictionHistory();
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Filter Controls: 7 Days | 30 Days | All
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [7, 30, 0].map((days) {
                  final selected = _selectedFilterDays == days;
                  String label = '';
                  if (days == 7) label = AppLocalizations.get('filter_7d', _activeLang);
                  if (days == 30) label = AppLocalizations.get('filter_30d', _activeLang);
                  if (days == 0) label = AppLocalizations.get('filter_all', _activeLang);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilterDays = days;
                          });
                          _loadPredictionHistory();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primaryMedium : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? AppColors.primaryMedium : AppColors.borderLight,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryMedium.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: GoogleFonts.poppins(
                                color: selected ? Colors.white : AppColors.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              if (_loadingPredictions)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                )
              else if (_predictions.isEmpty)
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.show_chart_rounded, color: AppColors.textMuted, size: 28),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.isHindi
                            ? "इस समय अवधि के लिए कोई इतिहास नहीं है।"
                            : "No telemetry history found for this period.",
                        style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isHindi
                            ? "सिफारिशें देखने के लिए पहले कुछ दिन निगरानी जारी रखें।"
                            : "Make a few irrigation observations to establish your crop trends.",
                        style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 11.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else ...[
                // Summary Block
                _buildSummaryGrid(),

                const SizedBox(height: 16),

                // Charts
                _buildChartCard(
                  title: widget.isHindi ? 'सिंचाई की सिफारिश' : 'Irrigation Target',
                  subtitle: widget.isHindi ? 'दैनिक जल आवश्यकता (मिमी)' : 'Daily water application target (mm)',
                  unit: 'mm',
                  spots: _generateSpots((data) => data['irrigationAmount'] as double),
                  color: AppColors.primaryLight,
                ),

                const SizedBox(height: 14),

                _buildChartCard(
                  title: widget.isHindi ? 'वर्षा इतिहास' : 'Rainfall History',
                  subtitle: widget.isHindi ? 'संचित वर्षा (मिमी)' : 'Cumulative rain measurements (mm)',
                  unit: 'mm',
                  spots: _generateSpots((data) => data['rainfall'] as double),
                  color: AppColors.weatherBlue,
                ),

                const SizedBox(height: 14),

                _buildChartCard(
                  title: widget.isHindi ? 'तापमान का स्तर' : 'Temperature Trend',
                  subtitle: widget.isHindi ? 'दैनिक औसत तापमान (°C)' : 'Daily mean temperature (°C)',
                  unit: '°C',
                  spots: _generateSpots((data) => data['temperature'] as double),
                  color: AppColors.warning,
                ),

                const SizedBox(height: 14),

                _buildChartCard(
                  title: widget.isHindi ? 'जल की कमी (Deficit)' : 'Soil Water Deficit',
                  subtitle: widget.isHindi ? 'संभावित जल रिक्तीकरण (मिमी)' : 'Estimated soil water deficit (mm)',
                  unit: 'mm',
                  spots: _generateSpots((data) => data['deficit'] as double),
                  color: AppColors.danger,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    double totalIrrigation = 0;
    double maxTemp = -99;
    double avgDeficit = 0;
    double avgHumidity = 0;

    for (final p in _predictions) {
      totalIrrigation += p['irrigationAmount'] as double;
      final temp = p['temperature'] as double;
      if (temp > maxTemp) maxTemp = temp;
      avgDeficit += p['deficit'] as double;
      avgHumidity += p['humidity'] as double;
    }

    avgDeficit /= _predictions.length;
    avgHumidity /= _predictions.length;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isHindi ? 'अवधि सारांश' : 'Period Telemetry Summary',
                style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.mintBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_predictions.length} records',
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildSummaryItem(
                label: widget.isHindi ? 'कुल सिंचाई' : 'Total Water',
                val: '${totalIrrigation.toStringAsFixed(1)} mm',
                icon: Icons.water_drop_rounded,
                color: AppColors.primaryLight,
              ),
              _buildSummaryItem(
                label: widget.isHindi ? 'अधिकतम तापमान' : 'Peak Temp',
                val: '${maxTemp.toStringAsFixed(1)} °C',
                icon: Icons.wb_sunny_rounded,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryItem(
                label: widget.isHindi ? 'औसत कमी' : 'Avg Deficit',
                val: '${avgDeficit.toStringAsFixed(1)} mm',
                icon: Icons.bar_chart_rounded,
                color: AppColors.danger,
              ),
              _buildSummaryItem(
                label: widget.isHindi ? 'औसत आर्द्रता' : 'Avg Humidity',
                val: '${avgHumidity.toStringAsFixed(0)}%',
                icon: Icons.cloud_queue_rounded,
                color: AppColors.weatherBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String val,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    val,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots(double Function(Map<String, dynamic>) getValue) {
    final spots = <FlSpot>[];
    for (int i = 0; i < _predictions.length; i++) {
      spots.add(FlSpot(i.toDouble(), getValue(_predictions[i])));
    }
    return spots;
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required String unit,
    required List<FlSpot> spots,
    required Color color,
  }) {
    final List<String> dates = _predictions.map((p) {
      final dateObj = p['date'];
      if (dateObj is Timestamp) {
        final dt = dateObj.toDate();
        return '${dt.day}/${dt.month}';
      }
      return '';
    }).toList();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (val) => FlLine(color: AppColors.borderLight, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '${val.toStringAsFixed(0)}$unit',
                          style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 9),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < dates.length) {
                          final interval = (dates.length / 4).ceil();
                          if (idx == 0 || idx == dates.length - 1 || idx % interval == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                dates[idx],
                                style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 9),
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 10,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3,
                        color: color,
                        strokeColor: Colors.white,
                        strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
