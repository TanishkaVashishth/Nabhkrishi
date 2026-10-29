import 'package:flutter/material.dart';

/// Represents SAR (Synthetic Aperture Radar) signals for a field sub-region
/// as defined in NabhKrishi-Web prototype data (Sentinel-1 SAR C-band simulation).
class SatelliteRegionSignal {
  final String label;
  final String nameEn;
  final String nameHi;
  final String namePa;
  final String nameBn;
  final String nameHr;
  final double vvMean; // Radar backscatter mean in dB
  final double vvChange; // Radar backscatter delta in dB
  final int ageDays; // Sentinel data age in days
  final Offset relativeOffset; // Relative 2D offset from field center (-1.0 to 1.0)
  final String status;
  final bool isDemoData;

  const SatelliteRegionSignal({
    required this.label,
    required this.nameEn,
    required this.nameHi,
    this.namePa = '',
    this.nameBn = '',
    this.nameHr = '',
    required this.vvMean,
    required this.vvChange,
    required this.ageDays,
    required this.relativeOffset,
    this.status = 'monitoring',
    this.isDemoData = true,
  });

  String get vvMeanString => '${vvMean.toStringAsFixed(1)} dB';
  String get vvChangeString => '${vvChange > 0 ? '+' : ''}${vvChange.toStringAsFixed(1)} dB';

  String ageString([dynamic languageOrIsHindi]) {
    String lang = 'en';
    if (languageOrIsHindi is bool) {
      lang = languageOrIsHindi ? 'hi' : 'en';
    } else if (languageOrIsHindi is String) {
      lang = languageOrIsHindi.toLowerCase().trim();
    }

    if (lang == 'pa' || lang == 'punjabi') {
      return '$ageDays ਦਿਨ ਪਹਿਲਾਂ';
    }
    if (lang == 'bn' || lang == 'bengali') {
      return '$ageDays দিন আগে';
    }
    if (lang == 'hr' || lang == 'haryanvi') {
      return '$ageDays दिन पैहल्यां';
    }
    if (lang == 'hi' || lang == 'hindi') {
      return '$ageDays दिन पहले';
    }
    if (lang == 'hinglish' || lang.contains('hinglish')) {
      return '$ageDays din pehle';
    }
    return '$ageDays days ago';
  }

  String getLocalizedName([dynamic languageOrIsHindi]) {
    String lang = 'en';
    if (languageOrIsHindi is bool) {
      lang = languageOrIsHindi ? 'hi' : 'en';
    } else if (languageOrIsHindi is String) {
      lang = languageOrIsHindi.toLowerCase().trim();
    }

    if (lang == 'pa' || lang == 'punjabi') {
      return namePa.isNotEmpty ? namePa : nameHi;
    }
    if (lang == 'bn' || lang == 'bengali') {
      return nameBn.isNotEmpty ? nameBn : nameHi;
    }
    if (lang == 'hr' || lang == 'haryanvi') {
      return nameHr.isNotEmpty ? nameHr : nameHi;
    }
    if (lang == 'hi' || lang == 'hindi') {
      return nameHi;
    }
    if (lang == 'hinglish' || lang.contains('hinglish')) {
      return nameEn;
    }
    return nameEn;
  }
}

/// Prototype region dataset matching exact values from NabhKrishi-Web/src/data/mock.ts
/// and SatelliteExperience.tsx.
/// 
/// NOTE: These are prototype indicators and illustrative simulation values.
/// They are clearly presented with transparency as demo SAR data.
const List<SatelliteRegionSignal> kPrototypeSatelliteRegions = [
  SatelliteRegionSignal(
    label: 'R1',
    nameEn: 'North-East Sector',
    nameHi: 'उत्तर-पूर्वी भाग',
    namePa: 'ਉੱਤਰ-ਪੂਰਬੀ ਭਾਗ',
    nameBn: 'উত্তর-পূর্ব অংশ',
    nameHr: 'उत्तर-पूर्वी हिस्सा',
    vvMean: -11.2,
    vvChange: 0.8,
    ageDays: 2,
    relativeOffset: Offset(0.50, 0.50), // Reference: [1.5, 0, 1.5]
    status: 'stable',
  ),
  SatelliteRegionSignal(
    label: 'R2',
    nameEn: 'North-West Sector',
    nameHi: 'उत्तर-पश्चिमी भाग',
    namePa: 'ਉੱਤਰ-ਪੱਛਮੀ ਭਾਗ',
    nameBn: 'উত্তর-পশ্চিম অংশ',
    nameHr: 'उत्तर-पश्चिमी हिस्सा',
    vvMean: -12.6,
    vvChange: -1.4,
    ageDays: 4,
    relativeOffset: Offset(-0.60, 0.20), // Reference: [-1.8, 0, 0.6]
    status: 'needs_check',
  ),
  SatelliteRegionSignal(
    label: 'R3',
    nameEn: 'South-East Sector',
    nameHi: 'दक्षिण-पूर्वी भाग',
    namePa: 'ਦੱਖਣ-ਪੂਰਬੀ ਭਾਗ',
    nameBn: 'দক্ষিণ-পূর্ব অংশ',
    nameHr: 'दक्षिण-पूर्वी हिस्सा',
    vvMean: -10.4,
    vvChange: 0.2,
    ageDays: 1,
    relativeOffset: Offset(0.13, -0.63), // Reference: [0.4, 0, -1.9]
    status: 'stable',
  ),
  SatelliteRegionSignal(
    label: 'R4',
    nameEn: 'South-West Sector',
    nameHi: 'दक्षिण-पश्चिमी भाग',
    namePa: 'ਦੱਖਣ-ਪੱਛਮੀ ਭਾਗ',
    nameBn: 'দক্ষিণ-পশ্চিম অংশ',
    nameHr: 'दक्षिण-पश्चिमी हिस्सा',
    vvMean: -13.1,
    vvChange: -2.1,
    ageDays: 4,
    relativeOffset: Offset(-0.37, -0.40), // Reference: [-1.1, 0, -1.2]
    status: 'needs_check',
  ),
];
