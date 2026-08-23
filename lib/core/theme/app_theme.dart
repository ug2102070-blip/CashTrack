// lib/core/theme/app_theme.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  // ── Font Fallback Chain ─────────────────────────────────
  static const List<String> _fontFallback = <String>[
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

  // ═══════════════════════════════════════════════════════
  //  LIGHT THEME — Primary experience
  // ═══════════════════════════════════════════════════════
  static ThemeData getLightTheme(Color accentColor) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.light,
      primary: accentColor,
      secondary: AppColors.secondary,
      surface: AppColors.lightSurface,
      error: AppColors.error,
    ).copyWith(
      onSurface: AppColors.lightText,
      onSurfaceVariant: AppColors.lightTextSecondary,
      outline: AppColors.lightBorder,
      surfaceContainerHighest: AppColors.lightSurfaceElevated,
      surfaceContainer: AppColors.lightSurface,
      surfaceContainerLow: AppColors.lightBg,
      surfaceContainerLowest: AppColors.lightBg,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.lightBg,
      fontFamily: 'Inter',
      textTheme: _withFallback(
        base.textTheme.apply(
          fontFamily: 'Inter',
          bodyColor: AppColors.lightText,
          displayColor: AppColors.lightText,
        ),
      ),

      // ── AppBar ───────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.lightText,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.headingMd.copyWith(
          color: AppColors.lightText,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.lightText,
          size: 22,
        ),
      ),

      // ── Cards ────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.lightBorder.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        color: AppColors.lightSurface,
        margin: EdgeInsets.zero,
      ),

      // ── Input Fields ─────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
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
          vertical: 14,
        ),
        hintStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.lightTextTertiary,
        ),
      ),

      // ── Elevated Button ──────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // ── Text Button ──────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // ── Outlined Button ──────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightText,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.lightBorder),
          textStyle: AppTextStyles.button,
        ),
      ),

      // ── Icon Theme ───────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.lightTextSecondary,
        size: 22,
      ),

      // ── Bottom Navigation Bar ────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: accentColor,
        unselectedItemColor: AppColors.lightTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.caption,
      ),

      // ── FAB ──────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Chips ────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: accentColor.withValues(alpha: 0.08),
        deleteIconColor: accentColor,
        labelStyle: AppTextStyles.label.copyWith(color: accentColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),

      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      listTileTheme: const ListTileThemeData(
        visualDensity: VisualDensity.standard,
        dense: false,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),

      // ── Divider ──────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),

      // ── Tooltip ──────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF18181B).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: AppTextStyles.caption.copyWith(
          color: Colors.white,
          letterSpacing: 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        waitDuration: const Duration(milliseconds: 400),
      ),

      // ── Dialog ───────────────────────────────────────
      dialogTheme: DialogThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.headingMd.copyWith(
          color: AppColors.lightText,
        ),
      ),

      // ── SnackBar ─────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF18181B),
        contentTextStyle: AppTextStyles.bodySm.copyWith(
          color: Colors.white,
        ),
      ),

      // ── Scrollbar ────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return accentColor.withValues(alpha: 0.4);
          }
          if (states.contains(WidgetState.hovered)) {
            return accentColor.withValues(alpha: 0.25);
          }
          return AppColors.lightTextTertiary.withValues(alpha: 0.2);
        }),
        thickness: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.dragged)) {
            return 6.0;
          }
          return 3.0;
        }),
        radius: const Radius.circular(10),
        thumbVisibility: WidgetStateProperty.all(kIsWeb),
        interactive: true,
      ),

      // ── Page Transitions ─────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      // ── Popup Menu ───────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Bottom Sheet ─────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleSize: Size(36, 4),
      ),

      // ── Tab Bar ──────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: accentColor,
        unselectedLabelColor: AppColors.lightTextSecondary,
        indicatorColor: accentColor,
        labelStyle: AppTextStyles.tabLabel,
        unselectedLabelStyle: AppTextStyles.tabLabel,
      ),

      // ── Switch ───────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.lightTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentColor;
          return AppColors.lightBorder;
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  DARK THEME — Equally polished
  // ═══════════════════════════════════════════════════════
  static ThemeData getDarkTheme(Color accentColor) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.dark,
      primary: accentColor,
      secondary: AppColors.secondary,
      error: AppColors.error,
    ).copyWith(
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
      surfaceContainerHighest: AppColors.darkSurfaceElevated,
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerLow: AppColors.darkBg,
      surfaceContainerLowest: AppColors.darkBg,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      fontFamily: 'Inter',
      textTheme: _withFallback(
        base.textTheme.apply(
          fontFamily: 'Inter',
          bodyColor: AppColors.darkText,
          displayColor: AppColors.darkText,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary, size: 22),
      primaryIconTheme: IconThemeData(color: scheme.onSurface, size: 22),

      listTileTheme: ListTileThemeData(
        iconColor: AppColors.darkTextSecondary,
        textColor: scheme.onSurface,
        visualDensity: VisualDensity.standard,
        dense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),

      // ── AppBar ───────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.darkText,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.headingMd.copyWith(
          color: AppColors.darkText,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText, size: 22),
      ),

      // ── Cards ────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.darkBorder.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        color: AppColors.darkSurface,
        margin: EdgeInsets.zero,
      ),

      // ── Input Fields ─────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
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
          vertical: 14,
        ),
        hintStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.darkTextTertiary,
        ),
      ),

      // ── Elevated Button ──────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // ── Text Button ──────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // ── Outlined Button ──────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkText,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.darkBorder),
          textStyle: AppTextStyles.button,
        ),
      ),

      // ── FAB ──────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Bottom Nav ───────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: accentColor,
        unselectedItemColor: AppColors.darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.caption,
      ),

      // ── Chips ────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: accentColor.withValues(alpha: 0.15),
        labelStyle: AppTextStyles.label.copyWith(color: accentColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),

      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      // ── Divider ──────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),

      // ── Tooltip ──────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceElevated.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.darkBorder.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: AppTextStyles.caption.copyWith(
          color: AppColors.darkText,
          letterSpacing: 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        waitDuration: const Duration(milliseconds: 400),
      ),

      // ── Dialog ───────────────────────────────────────
      dialogTheme: DialogThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.headingMd.copyWith(
          color: AppColors.darkText,
        ),
      ),

      // ── SnackBar ─────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        backgroundColor: AppColors.darkSurfaceElevated,
        contentTextStyle: AppTextStyles.bodySm.copyWith(
          color: AppColors.darkText,
        ),
      ),

      // ── Scrollbar ────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return accentColor.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.hovered)) {
            return accentColor.withValues(alpha: 0.35);
          }
          return Colors.white.withValues(alpha: 0.08);
        }),
        thickness: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.dragged)) {
            return 6.0;
          }
          return 3.0;
        }),
        radius: const Radius.circular(10),
        thumbVisibility: WidgetStateProperty.all(kIsWeb),
        interactive: true,
      ),

      // ── Page Transitions ─────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      // ── Popup Menu ───────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.darkSurfaceElevated,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Bottom Sheet ─────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: AppColors.darkSurface,
        showDragHandle: true,
        dragHandleSize: Size(36, 4),
      ),

      // ── Tab Bar ──────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: accentColor,
        unselectedLabelColor: AppColors.darkTextSecondary,
        indicatorColor: accentColor,
        labelStyle: AppTextStyles.tabLabel,
        unselectedLabelStyle: AppTextStyles.tabLabel,
      ),

      // ── Switch ───────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.darkTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentColor;
          return AppColors.darkBorder;
        }),
      ),
    );
  }
}
