import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../features/crop_disease/services/crop_disease_service.dart';

/// PPO V3 Reinforcement Learning Decision-Support Card.
/// Visibly surfaces the 60-dim observation policy recommendation
/// using transparent decision-support language across all 6 supported languages.
class PPODecisionCard extends StatelessWidget {
  final PpoDecision decision;
  final bool isHindi;
  final String? currentLanguage;
  final VoidCallback? onAskChatbot;
  final VoidCallback? onRecheckPhoto;

  const PPODecisionCard({
    super.key,
    required this.decision,
    this.isHindi = false,
    this.currentLanguage,
    this.onAskChatbot,
    this.onRecheckPhoto,
  });

  Color get _badgeColor {
    switch (decision.actionId) {
      case 0: // Monitor
        return AppColors.primaryLight;
      case 1: // Preventive Management
        return AppColors.weatherBlue;
      case 2: // Irrigation / Nutrient Review
        return const Color(0xFF0284C7);
      case 3: // Disease Management Review
        return AppColors.danger;
      case 4: // Recheck
        return AppColors.warning;
      case 5: // Ask NabhKrishi Chatbot
        return const Color(0xFF7C3AED);
      default:
        return AppColors.primaryMedium;
    }
  }

  IconData get _actionIcon {
    switch (decision.actionId) {
      case 0:
        return Icons.visibility_outlined;
      case 1:
        return Icons.shield_outlined;
      case 2:
        return Icons.water_drop_outlined;
      case 3:
        return Icons.medical_services_outlined;
      case 4:
        return Icons.camera_alt_outlined;
      case 5:
        return Icons.auto_awesome_rounded;
      default:
        return Icons.psychology_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor;
    final lang = currentLanguage ?? (isHindi ? 'hi' : 'en');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.psychology_rounded, size: 16, color: color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.get('ai_management_decision', lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Action ${decision.actionId}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Decision Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_actionIcon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  decision.getLocalizedActionName(lang),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Localized Description
          Text(
            decision.getLocalizedDescription(lang),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // Decision-Support Context Footnote
          Text(
            AppLocalizations.get('decision_footnote', lang),
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              color: AppColors.textMuted,
            ),
          ),

          // Action buttons if decision calls for RAG guidance or recheck
          if (decision.needsChatbotGuidance && onAskChatbot != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAskChatbot,
                icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                label: Text(
                  AppLocalizations.get('get_verified_guidance', lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMedium,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                ),
              ),
            ),
          ],
          if (decision.isRecheck && onRecheckPhoto != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRecheckPhoto,
                icon: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.warning),
                label: Text(
                  AppLocalizations.get('capture_clearer_photo', lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.warning),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
