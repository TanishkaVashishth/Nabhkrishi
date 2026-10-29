import '../../../../core/localization/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/chatbot_service.dart';
import '../../../../shared/widgets/app_card.dart';
import 'package:nabhkrishi/features/language/providers/language_provider.dart';
import 'package:nabhkrishi/features/location/providers/location_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final bool isHindi;
  final String? currentLanguage;

  const ProfilePage({
    super.key,
    required this.isHindi,
    this.currentLanguage,
  });

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isCheckingHealth = false;
  bool? _isBackendOnline;

  Future<void> _checkBackendHealth() async {
    setState(() {
      _isCheckingHealth = true;
      _isBackendOnline = null;
    });

    try {
      final chatbotService = ref.read(chatbotServiceProvider);
      final isHealthy = await chatbotService.checkHealth();
      if (mounted) {
        setState(() {
          _isBackendOnline = isHealthy;
          _isCheckingHealth = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBackendOnline = false;
          _isCheckingHealth = false;
        });
      }
    }
  }

  Future<void> _handleSignOut(String activeLang) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.get('sign_out_confirm_title', activeLang),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppLocalizations.get('sign_out_confirm_msg', activeLang),
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.get('cancel', activeLang), style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(AppLocalizations.get('logout_button', activeLang), style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final confirmedLoc = ref.watch(confirmedLocationProvider);
    final currentLanguage = ref.watch(languageProvider);
    final String activeLang = widget.currentLanguage ?? currentLanguage;

    final String displayName = user?.displayName ??
        (user?.phoneNumber ?? AppLocalizations.get('farmer', activeLang));
    final String emailOrPhone = user?.email ?? user?.phoneNumber ?? AppLocalizations.get('verified_farmer_account', activeLang);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            AppLocalizations.get('farmer_profile', activeLang),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            AppLocalizations.get('account_settings', activeLang),
            style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // User Card
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryMedium.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'N',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        emailOrPhone,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.mintBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.get('verified_farmer', activeLang),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Active Farm Location Card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.get('active_farm_location', activeLang),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${widget.isHindi ? "अक्षांश / देशांतर" : "Coordinates"}: ${confirmedLoc.centroid.latitude.toStringAsFixed(4)}° N, ${confirmedLoc.centroid.longitude.toStringAsFixed(4)}° E',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.isHindi ? "खेत क्षेत्र" : "Farm Area"}: ${confirmedLoc.farmAreaHectares.toStringAsFixed(2)} ha (${(confirmedLoc.farmAreaHectares * 2.471).toStringAsFixed(2)} acres)',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Language Preferences
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.language_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.get('language_preference', activeLang),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LanguageNotifier.supportedLanguages.map((lang) {
                    final isSelected = currentLanguage.toLowerCase() == lang.toLowerCase();
                    final displayName = LanguageNotifier.displayNames[lang] ?? lang;
                    return GestureDetector(
                      onTap: () => ref.read(languageProvider.notifier).setLanguage(lang),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryMedium : AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryMedium : AppColors.border.withValues(alpha: 0.4),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryMedium.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(Icons.check, size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              displayName,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Backend Health & LAN Checker
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_sync_outlined, color: AppColors.weatherBlue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.get('ai_server_status', activeLang),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (_isCheckingHealth)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    else if (_isBackendOnline != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isBackendOnline! ? AppColors.mintBg : AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isBackendOnline!
                              ? (widget.isHindi ? 'ऑनलाइन' : 'Online')
                              : (widget.isHindi ? 'अनुपलब्ध' : 'Offline'),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _isBackendOnline! ? AppColors.primary : AppColors.danger,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Endpoint: ${ApiConstants.resolvedBaseUrl}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isCheckingHealth ? null : _checkBackendHealth,
                    icon: const Icon(Icons.refresh, size: 15),
                    label: Text(
                      AppLocalizations.get('test_connection', activeLang),
                      style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleSignOut(activeLang),
              icon: const Icon(Icons.logout, size: 17, color: Colors.white),
              label: Text(
                AppLocalizations.get('logout_button', activeLang),
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
