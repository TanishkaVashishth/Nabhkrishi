import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/ppo_decision_card.dart';
import '../../../crop_disease/services/crop_disease_service.dart';

class FieldAiStatusCard extends StatelessWidget {
  final CropDiseaseResult? latestResult;
  final String language;
  final bool isHindi;
  final VoidCallback onScanLeaf;
  final VoidCallback onAskChatbot;

  const FieldAiStatusCard({
    super.key,
    required this.latestResult,
    required this.onScanLeaf,
    required this.onAskChatbot,
    this.language = 'en',
    this.isHindi = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeLanguage = language.isNotEmpty ? language : (isHindi ? 'hi' : 'en');
    final loc = AppLocalizations(activeLanguage);
    final decision = latestResult?.decision;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. CROP HEALTH STATUS (Swin-T Vision Model)
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.mintBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.biotech_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            loc.translate('field_health'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: AppColors.textPrimary,
                              fontSize: 13,
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
                      'Swin-T Vision',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (latestResult != null) ...[
                // Active Scan Result
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: latestResult!.isHealthy
                        ? AppColors.mintBg.withValues(alpha: 0.5)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: latestResult!.isHealthy
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        latestResult!.isHealthy
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        color: latestResult!.isHealthy
                            ? AppColors.primary
                            : const Color(0xFFDC2626),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latestResult!.getLocalizedDiseaseName(activeLanguage),
                              style: GoogleFonts.poppins(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${loc.translate('confidence_label')}: ${latestResult!.confidencePercent}%',
                              style: GoogleFonts.poppins(
                                color: latestResult!.isHealthy
                                    ? AppColors.primary
                                    : const Color(0xFFDC2626),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Mandatory Confidence vs Severity Disclaimer
                Text(
                  loc.translate('confidence_disclaimer'),
                  style: GoogleFonts.poppins(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else ...[
                // Clean Fallback: No Recent AI Scan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.image_search_rounded,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.translate('no_recent_scan'),
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. AI RECOMMENDATION (PPO V3 Policy Decision)
        if (decision != null) ...[
          PPODecisionCard(
            decision: decision,
            isHindi: activeLanguage == 'hi' || activeLanguage == 'hindi',
            onAskChatbot: onAskChatbot,
            onRecheckPhoto: onScanLeaf,
          ),
        ] else ...[
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
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.psychology_rounded,
                              color: Color(0xFF7C3AED),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              loc.translate('recommended_action'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: AppColors.textPrimary,
                                fontSize: 13,
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
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PPO V3 RL',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF7C3AED),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.translate('no_recent_recommendation'),
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
