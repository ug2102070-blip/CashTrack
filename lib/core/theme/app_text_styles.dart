// lib/core/theme/app_text_styles.dart
import 'package:flutter/material.dart';

/// Premium typography system using Inter.
///
/// Tight letter-spacing on headings for a modern SaaS feel.
/// Generous line heights on body text for readability.
/// Monospace-style tabular figures for financial amounts.
class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'Inter';

  // ═══════════════════════════════════════════════════════
  //  DISPLAY — Hero numbers, balance amounts
  // ═══════════════════════════════════════════════════════

  static const TextStyle displayLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    height: 1.1,
  );

  static const TextStyle displayMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.15,
  );

  static const TextStyle displaySm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.2,
  );

  // ═══════════════════════════════════════════════════════
  //  HEADINGS — Section titles, page titles
  // ═══════════════════════════════════════════════════════

  static const TextStyle headingLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.3,
  );

  static const TextStyle headingMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle headingSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════
  //  BODY — Primary content text
  // ═══════════════════════════════════════════════════════

  static const TextStyle bodyLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.6,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════
  //  LABELS & CAPTIONS
  // ═══════════════════════════════════════════════════════

  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    height: 1.4,
  );

  static const TextStyle labelLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.4,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    height: 1.6,
  );

  // ═══════════════════════════════════════════════════════
  //  AMOUNT — Financial numbers with tabular figures
  // ═══════════════════════════════════════════════════════

  static const TextStyle amountLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle amountMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle amountSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle amountCompact = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ═══════════════════════════════════════════════════════
  //  BUTTON & NAV
  // ═══════════════════════════════════════════════════════

  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.2,
  );

  static const TextStyle navLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.2,
  );

  static const TextStyle tabLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.2,
  );

  // ═══════════════════════════════════════════════════════
  //  LEGACY ALIASES (backward compatibility)
  // ═══════════════════════════════════════════════════════

  static const TextStyle h1 = headingLg;
  static const TextStyle h2 = headingMd;
  static const TextStyle h3 = headingSm;
  static const TextStyle h4 = headingSm;
  static const TextStyle h5 = headingSm;
  static const TextStyle body1 = bodyLg;
  static const TextStyle body2 = bodyMd;

  // Removed unused bangla legacy styles
}
