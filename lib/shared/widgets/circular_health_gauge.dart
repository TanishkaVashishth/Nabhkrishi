import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';

/// Animated Circular Health Gauge inspired by the reference dashboard.
class CircularHealthGauge extends StatelessWidget {
  final int score; // 0 to 100
  final String status; // 'Optimal' | 'Good' | 'Fair' | 'Alert'
  final double size;
  final double strokeWidth;
  final bool isHindi;
  final String? currentLanguage;

  const CircularHealthGauge({
    super.key,
    required this.score,
    this.status = 'Optimal',
    this.size = 140,
    this.strokeWidth = 11,
    this.isHindi = false,
    this.currentLanguage,
  });

  Color get _scoreColor {
    if (score >= 80) return AppColors.primaryLight;
    if (score >= 60) return AppColors.primaryMedium;
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  Color get _badgeBgColor {
    if (score >= 80) return AppColors.mintAccent.withValues(alpha: 0.5);
    if (score >= 60) return AppColors.mintBg;
    if (score >= 40) return AppColors.warningLight;
    return AppColors.dangerLight;
  }

  String get _localizedStatus {
    final lang = currentLanguage ?? (isHindi ? 'hi' : 'en');
    return AppLocalizations.getStatusName(status, lang);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CircularGaugePainter(
              score: score,
              strokeWidth: strokeWidth,
              trackColor: AppColors.surfaceMuted.withValues(alpha: 0.8),
              progressColor: _scoreColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: GoogleFonts.poppins(
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w900,
                  color: _scoreColor,
                  height: 1.0,
                ),
              ),
              Text(
                '/100',
                style: GoogleFonts.poppins(
                  fontSize: size * 0.08,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                constraints: BoxConstraints(maxWidth: size * 0.88),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _badgeBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _localizedStatus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: size * 0.072,
                    fontWeight: FontWeight.w800,
                    color: _scoreColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularGaugePainter extends CustomPainter {
  final int score;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  _CircularGaugePainter({
    required this.score,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track (270 degree arc)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = 135 * math.pi / 180;
    const sweepAngle = 270 * math.pi / 180;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active progress arc
    final progressSweep = sweepAngle * (score.clamp(0, 100) / 100.0);
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressSweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
