import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../language/providers/language_provider.dart';
import 'package:nabhkrishi/models/farm_model.dart';
import '../../providers/location_provider.dart';
import 'package:nabhkrishi/services/firestore_service.dart';

/// Reusable card displaying active farm details (coordinates, area in hectares)
/// with an action to save the farm profile to Firestore.
class FarmLocationDetailsCard extends ConsumerWidget {
  const FarmLocationDetailsCard({super.key});

  String _pointLocationText(String lang) {
    final l = lang.toLowerCase();
    if (l.contains('pa') || l.contains('punjabi')) return 'ਬਿੰਦੂ ਸਥਾਨ (ਕੋਈ ਹੱਦਬੰਦੀ ਨਹੀਂ)';
    if (l.contains('bn') || l.contains('bengali')) return 'বিন্দু অবস্থান (সীমানা আঁকা হয়নি)';
    if (l.contains('hr') || l.contains('haryanvi')) return 'बिंदु जगा (सीमा कोन्या खींची)';
    if (l.contains('hinglish')) return 'Point location (Boundary nahi kheenchi)';
    if (l.contains('hi') || l.contains('hindi')) return 'बिंदु स्थान (सीमा नहीं खींची गई)';
    return 'Point location';
  }

  String _signInFirstText(String lang) {
    final l = lang.toLowerCase();
    if (l.contains('pa') || l.contains('punjabi')) return 'ਕਿਰਪਾ ਕਰਕੇ ਪਹਿਲਾਂ ਸਾਈਨ ਇਨ ਕਰੋ।';
    if (l.contains('bn') || l.contains('bengali')) return 'অনুগ্রহ করে প্রথমে সাইন ইন করুন।';
    if (l.contains('hr') || l.contains('haryanvi')) return 'पहल्यां साइन इन करो जी।';
    if (l.contains('hinglish')) return 'Kripya pehle sign in karein.';
    if (l.contains('hi') || l.contains('hindi')) return 'कृपया पहले साइन इन करें।';
    return 'Please sign in first.';
  }

  String _farmSavedText(String lang) {
    final l = lang.toLowerCase();
    if (l.contains('pa') || l.contains('punjabi')) return 'ਖੇਤ ਸਫਲਤਾਪੂਰਵਕ ਸੁਰੱਖਿਅਤ ਕੀਤਾ ਗਿਆ!';
    if (l.contains('bn') || l.contains('bengali')) return 'জমি সফলভাবে সংরক্ষণ করা হয়েছে!';
    if (l.contains('hr') || l.contains('haryanvi')) return 'खेत सफलतापूर्वक सहेज लिया!';
    if (l.contains('hinglish')) return 'Khet safaltapoorvak save ho gaya!';
    if (l.contains('hi') || l.contains('hindi')) return 'खेत सफलतापूर्वक सहेजा गया!';
    return 'Farm saved successfully!';
  }

  String _failedToSaveText(String lang) {
    final l = lang.toLowerCase();
    if (l.contains('pa') || l.contains('punjabi')) return 'ਸੇਵ ਕਰਨ ਵਿੱਚ ਅਸਫਲ';
    if (l.contains('bn') || l.contains('bengali')) return 'সংরক্ষণ করতে ব্যর্থ হয়েছে';
    if (l.contains('hr') || l.contains('haryanvi')) return 'सहेजण म फेल';
    if (l.contains('hinglish')) return 'Save karne mein dikkat aayi';
    if (l.contains('hi') || l.contains('hindi')) return 'सहेजने में विफल';
    return 'Failed to save';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final confirmedLoc = ref.watch(confirmedLocationProvider);

    final latStr = confirmedLoc.latitude.toStringAsFixed(5);
    final lngStr = confirmedLoc.longitude.toStringAsFixed(5);
    final area = confirmedLoc.farmAreaHectares;
    final hasBoundary = confirmedLoc.boundary.length >= 3;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.agriculture_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.get('active_farm_location', currentLanguage),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lat: $latStr',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
              Expanded(
                child: Text(
                  'Lng: $lngStr',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasBoundary
                ? '${confirmedLoc.farmAreaAcres.toStringAsFixed(2)} ${AppLocalizations.get('acres', currentLanguage)} (${area.toStringAsFixed(2)} Ha)'
                : _pointLocationText(currentLanguage),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: Text(
                AppLocalizations.get('save_farm', currentLanguage),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_signInFirstText(currentLanguage)),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  return;
                }

                try {
                  final firestoreService = ref.read(firestoreServiceProvider);
                  final farm = FarmModel(
                    farmId: '',
                    userId: user.uid,
                    latitude: confirmedLoc.latitude,
                    longitude: confirmedLoc.longitude,
                    farmArea: confirmedLoc.boundary.length >= 3
                        ? confirmedLoc.farmAreaHectares
                        : null,
                    areaUnit: confirmedLoc.boundary.length >= 3 ? 'hectares' : null,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await firestoreService.saveFarm(user.uid, farm);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_farmSavedText(currentLanguage)),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${_failedToSaveText(currentLanguage)}: $e',
                        ),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
