// lib/core/theme/app_text_styles.dart
import 'package:flutter/material.dart';

class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body Text
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  // Caption & Labels
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.6,
  );

  // Button Text
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Amount Text Styles
  static const TextStyle amountLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: -1,
    height: 1.2,
  );

  static const TextStyle amountMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.3,
  );

  static const TextStyle amountSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
  );

  // Special Styles
  static const TextStyle navLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle tabLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  // Bangla Text Styles (using BalooDa2 font)
  static const TextStyle banglaH1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    fontFamily: 'BalooDa2',
    height: 1.4,
  );

  static const TextStyle banglaH2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: 'BalooDa2',
    height: 1.4,
  );

  static const TextStyle banglaBody1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: 'BalooDa2',
    height: 1.6,
  );

  static const TextStyle banglaBody2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontFamily: 'BalooDa2',
    height: 1.6,
  );
}
