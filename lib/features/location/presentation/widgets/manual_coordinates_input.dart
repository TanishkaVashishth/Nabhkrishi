import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../language/providers/language_provider.dart';
import '../../providers/location_provider.dart';

/// Reusable widget for manually entering latitude and longitude
/// and locating farm coordinates on the geographic map.
class ManualCoordinatesInput extends ConsumerStatefulWidget {
  const ManualCoordinatesInput({super.key});

  @override
  ConsumerState<ManualCoordinatesInput> createState() => _ManualCoordinatesInputState();
}

class _ManualCoordinatesInputState extends ConsumerState<ManualCoordinatesInput> {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  String _invalidLatMsg(String lang) {
    final l = lang.toLowerCase();
    if (l.contains('pa') || l.contains('punjabi')) return 'ਗ਼ਲਤ ਵਿਥਕਾਰ (-90 ਤੋਂ 90)';
    if (l.contains('bn') || l.contains('bengali')) return 'অকার্যকর অক্ষাংশ (-90 থেকে 90)';
    if (l.contains('hr') || l.contains('haryanvi')) return 'गलत अक्षांश (-90 तै 90)';
    if (l.contains('hinglish')) return 'Invalid Latitude (-90 se 90)';
    if (l.contains('hi') || l.contains('hindi')) return 'अमान्य अक्षांश (-90 से 90)';
    return 'Invalid Latitude (-90 to 90)';
  }

  String _invalidLngMsg(String lang) {
    final l = lang.toLowerCase();
    if (l.contains('pa') || l.contains('punjabi')) return 'ਗ਼ਲਤ ਲੰਬਕਾਰ (-180 ਤੋਂ 180)';
    if (l.contains('bn') || l.contains('bengali')) return 'অকার্যকর দ্রাঘিমাংশ (-180 থেকে 180)';
    if (l.contains('hr') || l.contains('haryanvi')) return 'गलत देशांतर (-180 तै 180)';
    if (l.contains('hinglish')) return 'Invalid Longitude (-180 se 180)';
    if (l.contains('hi') || l.contains('hindi')) return 'अमान्य देशांतर (-180 से 180)';
    return 'Invalid Longitude (-180 to 180)';
  }

  void _locateFarm(String lang) {
    final latVal = double.tryParse(_latController.text);
    final lngVal = double.tryParse(_lngController.text);

    if (latVal == null || latVal < -90.0 || latVal > 90.0) {
      setState(() {
        _validationError = _invalidLatMsg(lang);
      });
      return;
    }

    if (lngVal == null || lngVal < -180.0 || lngVal > 180.0) {
      setState(() {
        _validationError = _invalidLngMsg(lang);
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    FocusScope.of(context).unfocus();
    ref.read(locationProvider.notifier).updateCoordinate(latVal, lngVal);
    ref.read(locationProvider.notifier).clearBoundary();

    final activeLoc = ref.read(locationProvider);
    ref.read(confirmedLocationProvider.notifier).state =
        activeLoc.copyWith(isDrawing: false);
    ref.read(locationProvider.notifier).toggleDrawing(false);
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _CoordinateField(
                controller: _latController,
                label: '${AppLocalizations.get('latitude', currentLanguage)} (Lat)',
                hint: '28.6139',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CoordinateField(
                controller: _lngController,
                label: '${AppLocalizations.get('longitude', currentLanguage)} (Lng)',
                hint: '77.2090',
              ),
            ),
          ],
        ),
        if (_validationError != null) ...[
          const SizedBox(height: 6),
          Text(
            _validationError!,
            style: GoogleFonts.poppins(
              color: AppColors.danger,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
            icon: const Icon(Icons.search_rounded, size: 16),
            label: Text(
              AppLocalizations.get('locate_farm_coords', currentLanguage),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _locateFarm(currentLanguage),
          ),
        ),
      ],
    );
  }
}

class _CoordinateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _CoordinateField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 12),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: AppColors.textTertiary, fontSize: 12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
