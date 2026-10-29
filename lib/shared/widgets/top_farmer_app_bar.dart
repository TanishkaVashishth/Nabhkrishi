import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'tractor_icon.dart';

/// Top Farmer App Bar inspired by the reference top bar.
/// Features Tractor brand logo, live connection beacon, active field status,
/// quick weather alert badge, language switcher, and profile entry.
class TopFarmerAppBar extends StatelessWidget {
  final String activeFieldName;
  final bool isHindi;
  final String? currentLanguage;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onOpenWeather;
  final VoidCallback onOpenProfile;

  const TopFarmerAppBar({
    super.key,
    required this.activeFieldName,
    required this.isHindi,
    this.currentLanguage,
    required this.onLanguageChanged,
    required this.onOpenWeather,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final topSafePadding = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 360;
    final hPadding = isVerySmall ? 8.0 : 12.0;
    const pillSpacing = 4.0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.94),
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            top: topSafePadding + 6,
            bottom: 8,
            left: hPadding,
            right: hPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Brand Logo & Title with Live Status
              Expanded(
                child: Row(
                  children: [
                    // Brand Icon Container with custom tractor logo
                    Container(
                      width: isVerySmall ? 32 : 36,
                      height: isVerySmall ? 32 : 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: TractorIcon(size: isVerySmall ? 18 : 20, color: Colors.white),
                    ),
                    const SizedBox(width: 8),

                    // Title & Field Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Flexible(
                                child: Text(
                                  _getAppName(currentLanguage, isHindi),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: isVerySmall ? 14 : 15.5,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            activeFieldName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Right side action pills
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick Weather Alert Badge
                  InkWell(
                    onTap: onOpenWeather,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.weatherLightBlue,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.weatherBorderBlue),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_outlined,
                            size: 13,
                            color: AppColors.weatherBlue,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '28°C',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.weatherDarkBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: pillSpacing),

                  // Language Switcher Pill (Supports all 6 languages)
                  InkWell(
                    onTap: () => _showLanguageModal(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            _getLanguagePillLabel(true),
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: pillSpacing),

                  // Profile Icon Button
                  InkWell(
                    onTap: onOpenProfile,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primaryMedium.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 15,
                        color: AppColors.primaryMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppName(String? lang, bool isHindi) {
    final l = (lang ?? (isHindi ? 'hi' : 'en')).toLowerCase();
    if (l.contains('bengali') || l == 'bn') return 'নভকৃষি';
    if (l.contains('punjabi') || l == 'pa') return 'ਨਾਭਕ੍ਰਿਸ਼ੀ';
    if (l.contains('hindi') || l == 'hi' || l.contains('haryanvi') || l == 'hr') return 'नाभकृषि';
    return 'NabhKrishi';
  }

  String _getLanguagePillLabel([bool short = false]) {
    final lang = (currentLanguage ?? (isHindi ? 'Hindi' : 'English')).toLowerCase();
    if (short) {
      if (lang.contains('hinglish') || lang == 'hing') return 'Hing';
      if (lang.contains('punjabi') || lang == 'pa') return 'ਪੰ';
      if (lang.contains('bengali') || lang == 'bn') return 'বা';
      if (lang.contains('haryanvi') || lang == 'hr') return 'हरि';
      if (lang.contains('hindi') || lang == 'hi') return 'हि';
      return 'EN';
    }
    if (lang.contains('hinglish') || lang == 'hing') return 'Hinglish';
    if (lang.contains('punjabi') || lang == 'pa') return 'ਪੰਜਾਬੀ';
    if (lang.contains('bengali') || lang == 'bn') return 'বাংলা';
    if (lang.contains('haryanvi') || lang == 'hr') return 'हरियाणवी';
    if (lang.contains('hindi') || lang == 'hi') return 'हिन्दी';
    return 'EN';
  }

  void _showLanguageModal(BuildContext context) {
    final activeLang = currentLanguage ?? (isHindi ? 'Hindi' : 'English');
    final options = [
      {'name': 'English', 'native': 'English', 'code': 'EN'},
      {'name': 'Hindi', 'native': 'हिन्दी (Hindi)', 'code': 'हि'},
      {'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ (Punjabi)', 'code': 'ਪੰ'},
      {'name': 'Bengali', 'native': 'বাংলা (Bengali)', 'code': 'বা'},
      {'name': 'Haryanvi', 'native': 'हरियाणवी (Haryanvi)', 'code': 'हरि'},
      {'name': 'Hinglish', 'native': 'Hinglish (रोमन हिन्दी)', 'code': 'Hing'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Language / भाषा चुनें',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final isSelected = activeLang.toLowerCase() == opt['name']!.toLowerCase();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryMedium.withValues(alpha: 0.12) : AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryMedium : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryMedium : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        opt['code']!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    title: Text(
                      opt['native']!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppColors.primaryMedium : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.primaryMedium, size: 22)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      onLanguageChanged(opt['name']!);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
