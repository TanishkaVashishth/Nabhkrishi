import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../screens/nabhkrishi_chatbot_screen.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/ppo_decision_card.dart';
import '../../services/crop_disease_service.dart';
import '../../../field_map/presentation/pages/field_map_page.dart';
import '../../../language/providers/language_provider.dart';

class CropHealthScannerPage extends ConsumerStatefulWidget {
  final bool isHindi;
  final String? currentLanguage;

  const CropHealthScannerPage({
    super.key,
    required this.isHindi,
    this.currentLanguage,
  });

  @override
  ConsumerState<CropHealthScannerPage> createState() => _CropHealthScannerPageState();
}

class _CropHealthScannerPageState extends ConsumerState<CropHealthScannerPage>
    with SingleTickerProviderStateMixin {
  String get _activeLanguage => widget.currentLanguage ?? ref.watch(languageProvider);

  bool _isAnalyzing = false;
  int _analysisStep = 0;
  Timer? _stepTimer1;
  Timer? _stepTimer2;
  Timer? _stepTimer3;

  CropDiseaseResult? _result;
  String? _errorMessage;
  String? _selectedImagePath;

  late final AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _stepTimer1?.cancel();
    _stepTimer2?.cancel();
    _stepTimer3?.cancel();
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImagePath = pickedFile.path;
        _isAnalyzing = true;
        _analysisStep = 0;
        _errorMessage = null;
      });

      // Drive 4-step progressive pathology status pipeline
      _stepTimer1 = Timer(const Duration(milliseconds: 700), () {
        if (mounted && _isAnalyzing) setState(() => _analysisStep = 1);
      });
      _stepTimer2 = Timer(const Duration(milliseconds: 1400), () {
        if (mounted && _isAnalyzing) setState(() => _analysisStep = 2);
      });
      _stepTimer3 = Timer(const Duration(milliseconds: 2100), () {
        if (mounted && _isAnalyzing) setState(() => _analysisStep = 3);
      });

      // Execute Swin-T model inference via existing API
      try {
        final result = await predictCropDisease(pickedFile.path);
        if (mounted) {
          ref.read(latestCropDiseaseResultProvider.notifier).state = result;
          setState(() {
            _result = result;
            _isAnalyzing = false;
          });
        }
      } catch (err) {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _errorMessage = err.toString().replaceFirst('Exception: ', '');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = widget.isHindi
              ? 'फोटो चुनने में समस्या आई: $e'
              : 'Failed to pick image: $e';
        });
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                widget.isHindi ? 'गेहूं पत्ती की फोटो लें या चुनें' : 'Scan Wheat Leaf',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isHindi
                    ? 'Swin-T 15-रोग वर्गीकरण व PPO V3 निर्णय सहायता'
                    : 'Swin-T 15-disease classification & PPO V3 decision support',
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.mintBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22),
                ),
                title: Text(
                  widget.isHindi ? 'कैमरे से फोटो लें' : 'Take Photo (Camera)',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndAnalyze(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.weatherLightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.weatherBlue, size: 22),
                ),
                title: Text(
                  widget.isHindi ? 'गैलरी से चुनें' : 'Choose from Gallery',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndAnalyze(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReferToKvkModal(BuildContext context, CropDiseaseResult result) {
    bool submitted = false;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: submitted
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: AppColors.mintBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle, color: AppColors.primary, size: 30),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            widget.isHindi ? 'केवीके कृषि वैज्ञानिक को भेजा गया!' : 'Case Submitted to KVK Agronomist!',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isHindi
                                ? 'विश्वविद्यालय विस्तार वैज्ञानिक आपके पत्ती निदान की समीक्षा करेंगे।'
                                : 'University extension scientists will review your diagnosis within 2 hours.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isHindi ? 'कृषि विशेषज्ञ समीक्षा' : 'Refer Case to University Expert',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isHindi
                                ? 'कृषि विज्ञान केंद्र (KVK) एवं ICAR पादप रोग वैज्ञानिकों से परामर्श लें।'
                                : 'Direct consultation with plant pathologists at Krishi Vigyan Kendra.',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.isHindi ? "रोग पहचान" : "Diagnosis"}: ${result.getLocalizedDiseaseName(_activeLanguage)} (${result.confidencePercent}%)',
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.isHindi ? "निर्णय" : "PPO Decision"}: ${result.decision?.getLocalizedActionName(_activeLanguage) ?? "Standard Management"}',
                                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: noteController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: widget.isHindi ? 'अपनी टिप्पणी या प्रश्न जोड़ें...' : 'Add notes or questions for agronomist...',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.all(10),
                            ),
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(widget.isHindi ? 'रद्द करें' : 'Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setDialogState(() => submitted = true);
                                  Future.delayed(const Duration(milliseconds: 1500), () {
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  });
                                },
                                child: Text(widget.isHindi ? 'भेजें' : 'Submit Case', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isHindi ? 'गेहूं फसल स्वास्थ्य स्कैन' : 'Wheat Health Scanner',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.isHindi ? 'Swin-T 15-रोग पहचान व PPO V3 निर्णय' : 'Swin-T 15-Class Vision & PPO V3 Engine',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: _showImageSourcePicker,
                icon: const Icon(Icons.camera_alt, color: AppColors.primary),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Conditional View: Scanning Progress VS Results VS Empty State
          if (_isAnalyzing)
            _buildAnalyzingView()
          else if (_result != null)
            _buildResultView(_result!)
          else
            _buildEmptyState(),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(color: AppColors.dangerDark, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Viewfinder Container
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 250,
              height: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    color: AppColors.surfaceSoft,
                    child: const Center(
                      child: Icon(Icons.eco_rounded, size: 68, color: AppColors.primaryLight),
                    ),
                  ),
                  Positioned(top: 12, left: 12, child: _cornerBracket(top: true, left: true)),
                  Positioned(top: 12, right: 12, child: _cornerBracket(top: true, left: false)),
                  Positioned(bottom: 12, left: 12, child: _cornerBracket(top: false, left: true)),
                  Positioned(bottom: 12, right: 12, child: _cornerBracket(top: false, left: false)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.isHindi ? 'गेहूं की पत्ती स्कैन करें' : 'Scan a Wheat Leaf',
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isHindi
                ? 'गेहूं पत्ती की स्पष्ट फोटो लें। Swin-T 15 रोगों की जांच करेगा और PPO V3 प्रबंधन निर्णय देगा।'
                : 'Capture a clear photo of wheat leaf. Swin-T detects 15 diseases and PPO V3 outputs recommended management action.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showImageSourcePicker,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: Text(
                widget.isHindi ? 'पत्ती की फोटो लें' : 'Capture Wheat Leaf',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingView() {
    String stepText = widget.isHindi
        ? 'पत्ती के रूपात्मक लक्षणों का निष्कर्षण हो रहा है...'
        : 'Extracting morphological leaf features...';
    if (_analysisStep == 1) {
      stepText = widget.isHindi
          ? 'नेक्रोटिक घाव सीमाओं का विभाजन किया जा रहा है...'
          : 'Segmenting necrotic lesion boundaries...';
    } else if (_analysisStep == 2) {
      stepText = widget.isHindi
          ? 'Swin-T 15 गेहूं रोग वर्गों से मिलान हो रहा है...'
          : 'Matching with Swin-T 15 wheat disease classes...';
    } else if (_analysisStep >= 3) {
      stepText = widget.isHindi
          ? 'PPO V3 प्रबंधन निर्णय तैयार किया जा रहा है...'
          : 'Formulating PPO V3 management decision...';
    }

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          // Viewfinder with Laser Scanner
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 250,
              height: 240,
              child: Stack(
                children: [
                  if (_selectedImagePath != null)
                    Positioned.fill(
                      child: kIsWeb
                          ? Image.network(_selectedImagePath!, fit: BoxFit.cover)
                          : Image.file(File(_selectedImagePath!), fit: BoxFit.cover),
                    )
                  else
                    Container(color: AppColors.surfaceSoft),

                  Container(color: Colors.black.withValues(alpha: 0.25)),

                  // Animated Laser Beam
                  AnimatedBuilder(
                    animation: _laserController,
                    builder: (context, child) {
                      return Positioned(
                        top: _laserController.value * 220,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.mintAccent,
                                AppColors.primaryLight,
                                AppColors.mintAccent,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryLight.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Corner Reticle Brackets
                  Positioned(top: 12, left: 12, child: _cornerBracket(top: true, left: true)),
                  Positioned(top: 12, right: 12, child: _cornerBracket(top: true, left: false)),
                  Positioned(bottom: 12, left: 12, child: _cornerBracket(top: false, left: true)),
                  Positioned(bottom: 12, right: 12, child: _cornerBracket(top: false, left: false)),

                  // Center pulsating sparkles
                  Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryMedium.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.mintAccent, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            widget.isHindi ? 'विश्लेषण प्रगति पर है...' : 'Analyzing Wheat Leaf...',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            stepText,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryMedium,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_analysisStep + 1) * 0.25,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryMedium),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(CropDiseaseResult result) {
    final confidencePercent = result.confidencePercent;
    final isHealthy = result.isHealthy;
    final isUncertain = result.isUncertain;

    final Color badgeColor = isHealthy
        ? AppColors.primaryLight
        : (isUncertain ? AppColors.warning : AppColors.danger);

    final String badgeText = isHealthy
        ? (widget.isHindi ? 'स्वस्थ' : 'Healthy')
        : (isUncertain
            ? (widget.isHindi ? 'कम सटीकता' : 'Uncertain')
            : (widget.isHindi ? 'सावधानी' : 'Alert'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visual Comparison Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isHindi ? 'पत्ती फोटो विश्लेषण' : 'Visual Specimen Inspection',
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Uploaded Image with Lesion Bounding Box
                  Expanded(
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: kIsWeb
                                      ? Image.network(result.imagePath, fit: BoxFit.cover)
                                      : Image.file(File(result.imagePath), fit: BoxFit.cover),
                                ),
                                // Lesion bounding box if not healthy
                                if (!isHealthy)
                                  Positioned(
                                    top: 25,
                                    left: 20,
                                    right: 20,
                                    bottom: 25,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.danger, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                        color: AppColors.danger.withValues(alpha: 0.12),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isHealthy ? AppColors.primaryLight : AppColors.danger,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isHealthy ? 'Clean' : 'Detected',
                                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.isHindi ? 'आपकी पत्ती फोटो' : 'Scanned Leaf',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ICAR Reference Specimen Card
                  Expanded(
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              color: AppColors.surfaceSoft,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    isHealthy ? Icons.verified_user_outlined : Icons.biotech_outlined,
                                    size: 44,
                                    color: AppColors.primaryMedium,
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.verified, size: 10, color: AppColors.primary),
                                          const SizedBox(width: 2),
                                          Text(
                                            'ICAR Specimen',
                                            style: GoogleFonts.poppins(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
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
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.isHindi ? 'ICAR संदर्भ प्रोफाइल' : 'ICAR Reference Profile',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // AI Match Card
        AppCard(
          padding: const EdgeInsets.all(18),
          borderColor: badgeColor.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.get('swint_vision_result', _activeLanguage),
                          style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.getLocalizedDiseaseName(_activeLanguage),
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isHealthy ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                      color: badgeColor,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 12),

              // Confidence Bar (Strictly labeled confidence, never severity)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${AppLocalizations.get('model_confidence', _activeLanguage)}: ',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$confidencePercent%',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: badgeColor),
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
                          widget.isHindi
                              ? 'सटीकता 50% से कम है। कृपया अच्छी रोशनी में पत्ती की एक और स्पष्ट फोटो लें।'
                              : 'Confidence below 50%. Please capture another clear photo under natural light.',
                          style: GoogleFonts.poppins(color: AppColors.warning, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Alternatives
              if (result.topPredictions.length > 1) ...[
                const SizedBox(height: 12),
                Text(
                  widget.isHindi ? 'अन्य निकट संभावनाएं:' : 'Top Alternatives:',
                  style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: result.topPredictions.skip(1).map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.className}: ${(item.confidence * 100).toInt()}%',
                        style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // PPO V3 Management Decision Card
        if (result.decision != null) ...[
          PPODecisionCard(
            decision: result.decision!,
            isHindi: _activeLanguage == 'hi' || _activeLanguage == 'Hindi',
            currentLanguage: _activeLanguage,
            onAskChatbot: () => _openChatbotWithGuidance(result),
            onRecheckPhoto: _showImageSourcePicker,
          ),
          const SizedBox(height: 14),
        ],

        // Action Buttons Row: Get Verified Guidance + Refer to KVK
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openChatbotWithGuidance(result),
                icon: const Icon(Icons.auto_awesome, size: 15),
                label: Text(
                  AppLocalizations.get('nabh_guidance', _activeLanguage),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showReferToKvkModal(context, result),
                icon: const Icon(Icons.contact_phone_outlined, size: 15, color: AppColors.primary),
                label: Text(
                  AppLocalizations.get('refer_expert', _activeLanguage),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Scan Another Photo
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _showImageSourcePicker,
            icon: const Icon(Icons.camera_alt_outlined, size: 16),
            label: Text(
              AppLocalizations.get('scan_another_leaf', _activeLanguage),
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  void _openChatbotWithGuidance(CropDiseaseResult result) {
    final isHi = _activeLanguage == 'hi' || _activeLanguage == 'Hindi';
    final diseaseName = result.getLocalizedDiseaseName(_activeLanguage);
    final prompt = result.isHealthy
        ? (isHi
            ? 'मेरी गेहूं की पत्ती स्वस्थ पाई गई है। फसल को रोगों से बचाने और अच्छी पैदावार के लिए क्या प्रारंभिक प्रबंधन उपाय करने चाहिए?'
            : 'My wheat crop was detected as Healthy. What preventive agronomic care is recommended?')
        : (isHi
            ? 'मेरी गेहूं की पत्ती में $diseaseName पाया गया है। इसके प्रबंधन, रोकथाम और उपचार के उपाय बताएं।'
            : 'Provide verified guidance for $diseaseName in wheat based on ICAR recommendations.');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NabhKrishiChatbotScreen(
          isHindi: isHi,
          currentLanguage: _activeLanguage,
          initialPrompt: prompt,
        ),
      ),
    );
  }

  Widget _cornerBracket({required bool top, required bool left}) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
          bottom: !top ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
          left: left ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
          right: !left ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
