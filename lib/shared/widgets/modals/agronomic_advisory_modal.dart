import '../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Agronomic Advisory Modal inspired by ICAR & PAU extension guidelines
class AgronomicAdvisoryModal extends StatelessWidget {
  final bool isHindi;
  final String? currentLanguage;

  const AgronomicAdvisoryModal({
    super.key,
    this.isHindi = false,
    this.currentLanguage,
  });

  static Future<void> show(BuildContext context, {bool isHindi = false, String? currentLanguage}) {
    return showDialog(
      context: context,
      builder: (ctx) => AgronomicAdvisoryModal(isHindi: isHindi, currentLanguage: currentLanguage),
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
        constraints: const BoxConstraints(maxWidth: 480),
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
                            color: AppColors.primaryMedium.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.get('agronomic_advisory_title', _activeLang),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                AppLocalizations.get('agronomic_advisory_subtitle', _activeLang),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 14),

              // Advisory Steps
              _buildStepCard(
                stepNumber: '1',
                title: isHindi ? 'निगरानी एवं पत्ती निरीक्षण' : 'Field Inspection & Monitoring',
                desc: isHindi
                    ? 'खेत के निचले और नमी वाले हिस्सों में पत्तियों के नीचे भूरे/पीले धब्बों की जांच करें।'
                    : 'Scout shaded, dense canopy sections for early sporulation and lower leaf discoloration.',
                badgeColor: AppColors.primaryMedium,
              ),
              const SizedBox(height: 10),

              _buildStepCard(
                stepNumber: '2',
                title: isHindi ? 'सिंचाई नियंत्रण' : 'Irrigation Management',
                desc: isHindi
                    ? 'अत्यधिक नमी फंगस को बढ़ाती है। मौसम पूर्वानुमान देखकर ही अगली सिंचाई की योजना बनाएं।'
                    : 'Avoid standing moisture in wheat furrows during high relative humidity windows.',
                badgeColor: AppColors.weatherBlue,
              ),
              const SizedBox(height: 10),

              _buildStepCard(
                stepNumber: '3',
                title: isHindi ? 'रोकथाम एवं जैविक उपचार' : 'Preventive Bio-Management',
                desc: isHindi
                    ? 'संक्रमण के प्रारंभिक लक्षण दिखने पर ट्राइकोडर्मा या अनुशंसित फफूंदनाशक का छिड़काव करें।'
                    : 'Apply Trichoderma bio-formulation or PAU-recommended fungicide if rust risk escalates.',
                badgeColor: AppColors.warning,
              ),
              const SizedBox(height: 18),

              // KVK Helpline info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? 'स्थानीय केवीके हेल्पलाइन' : 'KVK Extension Helpline',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isHindi ? 'कृषि वैज्ञानिकों से सीधे मार्गदर्शन हेतु' : 'Toll-free Agronomist Support: 1800-180-1551',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
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

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String desc,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
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
