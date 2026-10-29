import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../screens/nabhkrishi_chatbot_screen.dart';
import '../../../../shared/widgets/ppo_decision_card.dart';
import '../../services/crop_disease_service.dart';

class CropDiseaseResultDialog extends StatelessWidget {
  final CropDiseaseResult result;
  final bool isHindi;
  final String? currentLanguage;

  const CropDiseaseResultDialog({
    super.key,
    required this.result,
    required this.isHindi,
    this.currentLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final lang = currentLanguage ?? (isHindi ? 'hi' : 'en');
    final confidencePercent = result.confidencePercent;
    final isHealthy = result.isHealthy;
    final isUncertain = result.isUncertain;

    final Color badgeColor = isHealthy
        ? AppColors.primaryLight
        : (isUncertain ? AppColors.warning : AppColors.danger);

    final String badgeText = isHealthy
        ? AppLocalizations.getStatusName('healthy', lang)
        : (isUncertain
            ? AppLocalizations.getStatusName('uncertain', lang)
            : AppLocalizations.getStatusName('alert', lang));

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.biotech_rounded,
                        color: badgeColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.get('wheat_disease_diagnosis', lang),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.get('swint_neural_analysis', lang),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Selected image display
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          color: AppColors.surfaceSoft,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (kIsWeb)
                                Image.network(
                                  result.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 40),
                                  ),
                                )
                              else
                                Image.file(
                                  File(result.imagePath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 40),
                                  ),
                                ),
                              // Analyzed overlay tag
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.72),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: AppColors.mintAccent, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocalizations.get('image_analyzed', lang),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Disease Name & Confidence Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.35),
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
                                    AppLocalizations.get('detected_class', lang),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textMuted,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      badgeText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        color: badgeColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              result.getLocalizedDiseaseName(lang),
                              style: GoogleFonts.poppins(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Confidence Bar (Strictly labeled confidence, never severity)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${AppLocalizations.get('model_confidence', lang)}: ',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$confidencePercent%',
                                  style: GoogleFonts.poppins(
                                    color: badgeColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: result.confidence.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceMuted,
                          valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                        ),
                      ),

                      if (isUncertain) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppLocalizations.get('uncertain_result_tip', lang),
                                  style: GoogleFonts.poppins(color: AppColors.warning, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Top Alternatives
                      if (result.topPredictions.length > 1) ...[
                        const SizedBox(height: 10),
                        Text(
                          AppLocalizations.get('top_alternatives', lang),
                          style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: result.topPredictions.skip(1).map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Text(
                                '${item.className}: ${(item.confidence * 100).toInt()}%',
                                style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 10),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // PPO Decision Card
                if (result.decision != null) ...[
                  const SizedBox(height: 14),
                  PPODecisionCard(
                    decision: result.decision!,
                    isHindi: lang == 'hi' || lang == 'Hindi',
                    currentLanguage: lang,
                  ),
                ],

                const SizedBox(height: 16),

                // Get Guidance CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      (result.decision?.isRecheck ?? false)
                          ? Icons.camera_alt_rounded
                          : Icons.auto_awesome_rounded,
                      size: 18,
                    ),
                    label: Text(
                      (result.decision?.isRecheck ?? false)
                          ? AppLocalizations.get('capture_clearer_photo', lang)
                          : AppLocalizations.get('get_verified_guidance', lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (result.decision?.isRecheck ?? false)
                          ? AppColors.warning
                          : AppColors.primaryMedium,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();

                      if (result.decision?.isRecheck ?? false) {
                        return;
                      }

                      final isHi = lang == 'hi' || lang == 'Hindi';
                      final diseaseName = result.getLocalizedDiseaseName(lang);
                      final String promptText = isHealthy
                          ? (isHi
                              ? 'मेरी गेहूं की फसल स्वस्थ है। फसल को रोगों से बचाने और अच्छी पैदावार के लिए क्या प्रारंभिक प्रबंधन उपाय करने चाहिए?'
                              : 'My wheat crop was detected as Healthy. What preventive care is recommended?')
                          : (isHi
                              ? 'मेरी गेहूं की पत्ती में $diseaseName पाया गया है। इसके प्रबंधन, रोकथाम और उपचार के उपाय बताएं।'
                              : 'Provide verified guidance for $diseaseName in wheat.');

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NabhKrishiChatbotScreen(
                            isHindi: isHi,
                            currentLanguage: lang,
                            initialPrompt: promptText,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      AppLocalizations.get('close', lang),
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
