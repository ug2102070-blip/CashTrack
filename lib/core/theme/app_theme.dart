// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static const List<String> _fontFallback = <String>[
    'NotoSansBengali',
    'BalooDa2',
    'Noto Sans Bengali',
    'Noto Sans',
    'sans-serif',
  ];

  static TextTheme _withFallback(TextTheme textTheme) {
    return textTheme.copyWith(
      displayLarge:
          textTheme.displayLarge?.copyWith(fontFamilyFallback: _fontFallback),
      displayMedium:
          textTheme.displayMedium?.copyWith(fontFamilyFallback: _fontFallback),
      displaySmall:
          textTheme.displaySmall?.copyWith(fontFamilyFallback: _fontFallback),
      headlineLarge:
          textTheme.headlineLarge?.copyWith(fontFamilyFallback: _fontFallback),
      headlineMedium:
          textTheme.headlineMedium?.copyWith(fontFamilyFallback: _fontFallback),
      headlineSmall:
          textTheme.headlineSmall?.copyWith(fontFamilyFallback: _fontFallback),
      titleLarge:
          textTheme.titleLarge?.copyWith(fontFamilyFallback: _fontFallback),
      titleMedium:
          textTheme.titleMedium?.copyWith(fontFamilyFallback: _fontFallback),
      titleSmall:
          textTheme.titleSmall?.copyWith(fontFamilyFallback: _fontFallback),
      bodyLarge:
          textTheme.bodyLarge?.copyWith(fontFamilyFallback: _fontFallback),
      bodyMedium:
          textTheme.bodyMedium?.copyWith(fontFamilyFallback: _fontFallback),
      bodySmall:
          textTheme.bodySmall?.copyWith(fontFamilyFallback: _fontFallback),
      labelLarge:
          textTheme.labelLarge?.copyWith(fontFamilyFallback: _fontFallback),
      labelMedium:
          textTheme.labelMedium?.copyWith(fontFamilyFallback: _fontFallback),
      labelSmall:
          textTheme.labelSmall?.copyWith(fontFamilyFallback: _fontFallback),
    );
  }

  // ডাইনামিক লাইট থিম মেথড
  static ThemeData getLightTheme(Color accentColor) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
        primary: accentColor,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Poppins',
      textTheme: _withFallback(
        base.textTheme.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.surface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: accentColor, width: 2), // ডাইনামিক বর্ডার
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor, // ডাইনামিক ব্যাকগ্রাউন্ড
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor, // ডাইনামিক টেক্সট কালার
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: accentColor, // ডাইনামিক সিলেকশন
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor, // ডাইনামিক FAB
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: accentColor.withValues(alpha: 0.1),
        deleteIconColor: accentColor,
        labelStyle: AppTextStyles.caption.copyWith(color: accentColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      listTileTheme: const ListTileThemeData(
        visualDensity: VisualDensity.standard,
        dense: false,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ডাইনামিক ডার্ক থিম মেথড
  static ThemeData getDarkTheme(Color accentColor) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );
    final base = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.dark,
      primary: accentColor,
      secondary: AppColors.secondary,
      error: AppColors.error,
    );
    final scheme = base.copyWith(
      surface: const Color(0xFF1B1F23),
      surfaceContainerHighest: const Color(0xFF23282D),
      surfaceContainer: const Color(0xFF1F2428),
      surfaceContainerLow: const Color(0xFF1A1E21),
      surfaceContainerLowest: const Color(0xFF14171A),
      onSurface: const Color(0xFFE6E6E6),
      onSurfaceVariant: const Color(0xFFB3B3B3),
      outline: const Color(0xFF2B3238),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0F1113),
      fontFamily: 'Poppins',
      textTheme: _withFallback(
        baseTheme.textTheme.apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        ),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
      primaryIconTheme: IconThemeData(color: scheme.onSurface, size: 24),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurface,
        textColor: scheme.onSurface,
        visualDensity: VisualDensity.standard,
        dense: false,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.h2.copyWith(color: scheme.onSurface),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: scheme.surface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: AppTextStyles.body2.copyWith(color: scheme.onSurfaceVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: accentColor,
        unselectedItemColor: scheme.onSurface.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: accentColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: accentColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
