// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Premium FinTech color system inspired by Stripe, Linear, Mercury.
///
/// Light-first approach with equally polished dark theme.
/// Uses Zinc-based neutrals for sophisticated surface hierarchy.
class AppColors {
  AppColors._();

  // ── Brand / Dynamic ─────────────────────────────────────
  // Primary color is dynamic (user-selectable via settings).
  // These are the default brand colors used as seeds.
  static const Color primaryDefault = Color(0xFF2D7A7B);
  static const Color secondary = Color(0xFF6366F1); // Indigo

  // ── Semantic ────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF6366F1);
  static const Color accent = Color(0xFF8B5CF6); // Violet — premium/AI

  // ── Transaction Colors ──────────────────────────────────
  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFEF4444);

  // ═══════════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════════

  // Backgrounds
  static const Color lightBg = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF4F4F5);
  static const Color lightSurfaceHover = Color(0xFFF0F0F2);

  // Borders
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightBorderSubtle = Color(0xFFF0F0F2);

  // Text
  static const Color lightText = Color(0xFF09090B);
  static const Color lightTextSecondary = Color(0xFF71717A);
  static const Color lightTextTertiary = Color(0xFFA1A1AA);

  // Divider
  static const Color lightDivider = Color(0xFFE4E4E7);

  // ═══════════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════════

  // Backgrounds
  static const Color darkBg = Color(0xFF09090B);
  static const Color darkSurface = Color(0xFF18181B);
  static const Color darkSurfaceElevated = Color(0xFF27272A);
  static const Color darkSurfaceHover = Color(0xFF2E2E33);

  // Borders
  static const Color darkBorder = Color(0xFF3F3F46);
  static const Color darkBorderSubtle = Color(0xFF27272A);

  // Text
  static const Color darkText = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextTertiary = Color(0xFF71717A);

  // Divider
  static const Color darkDivider = Color(0xFF27272A);

  // ═══════════════════════════════════════════════════════
  //  GRADIENTS
  // ═══════════════════════════════════════════════════════

  /// Hero balance card gradient
  static LinearGradient heroPrimaryGradient(Color primary) => LinearGradient(
        colors: [
          primary,
          Color.lerp(primary, const Color(0xFF6366F1), 0.35)!,
          Color.lerp(primary, const Color(0xFF8B5CF6), 0.55)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Soft surface gradient for subtle card backgrounds
  static const LinearGradient lightSurfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [Color(0xFF1C1C20), Color(0xFF18181B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Success (income) gradient
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Danger (expense) gradient
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// AI/Premium gradient
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Mesh aurora gradient for hero sections
  static LinearGradient auroraGradient(Color primary) => LinearGradient(
        colors: [
          primary.withValues(alpha: 0.08),
          const Color(0xFF6366F1).withValues(alpha: 0.05),
          const Color(0xFF8B5CF6).withValues(alpha: 0.03),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.3, 0.6, 1.0],
      );

  // ═══════════════════════════════════════════════════════
  //  SHADOWS
  // ═══════════════════════════════════════════════════════

  /// Subtle card shadow — light theme
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: const Color(0xFF09090B).withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: const Color(0xFF09090B).withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Medium card shadow
  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: const Color(0xFF09090B).withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF09090B).withValues(alpha: 0.03),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Elevated shadow for hover states
  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: const Color(0xFF09090B).withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF09090B).withValues(alpha: 0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Dark theme subtle shadow
  static List<BoxShadow> get shadowDarkSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowDarkMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // ═══════════════════════════════════════════════════════
  //  CHART PALETTES
  // ═══════════════════════════════════════════════════════

  static const List<Color> chartColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF22C55E), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
  ];

  static const List<Color> categoryColors = [
    Color(0xFFEF4444), Color(0xFFF87171), Color(0xFFF43F5E), Color(0xFFFB7185),
    Color(0xFFF97316), Color(0xFFFB923C), Color(0xFFF59E0B), Color(0xFFFBBF24),
    Color(0xFF22C55E), Color(0xFF34D399), Color(0xFF10B981), Color(0xFF4ADE80),
    Color(0xFF14B8A6), Color(0xFF2D7A7B),
    Color(0xFF3B82F6), Color(0xFF60A5FA), Color(0xFF06B6D4), Color(0xFF22D3EE),
    Color(0xFF6366F1), Color(0xFF818CF8), Color(0xFF8B5CF6), Color(0xFFA78BFA),
    Color(0xFFA855F7),
    Color(0xFFEC4899), Color(0xFFF472B6), Color(0xFFF0ABFC),
    Color(0xFF64748B), Color(0xFF94A3B8), Color(0xFF78716C), Color(0xFF95A5A6),
  ];

  static const List<Color> chartPaletteExpense = [
    Color(0xFF6366F1), Color(0xFFEF4444), Color(0xFF10B981), Color(0xFFF59E0B),
    Color(0xFFEC4899), Color(0xFF06B6D4), Color(0xFFF97316), Color(0xFF8B5CF6),
    Color(0xFF14B8A6), Color(0xFFE11D48), Color(0xFF3B82F6), Color(0xFFA3E635),
  ];

  static const List<Color> chartPaletteIncome = [
    Color(0xFF22C55E), Color(0xFF3B82F6), Color(0xFFF59E0B), Color(0xFFEC4899),
    Color(0xFF8B5CF6), Color(0xFFF97316), Color(0xFF06B6D4), Color(0xFFEF4444),
    Color(0xFF14B8A6), Color(0xFFA855F7), Color(0xFFE11D48), Color(0xFF84CC16),
  ];

  // ── Helpers ─────────────────────────────────────────────

  /// Semantic tint background for status indicators
  static Color tint(Color color, {double opacity = 0.1}) =>
      color.withValues(alpha: opacity);

  // Legacy alias for backward compatibility
  static Color withOpacity(Color color, double opacity) =>
      color.withValues(alpha: opacity);

  // Legacy aliases
  static const Color primary = primaryDefault;
  static const Color background = lightBg;
  static const Color surface = lightSurface;
  static const Color cardBackground = lightSurface;
  static const Color textPrimary = lightText;
  static const Color textSecondary = lightTextSecondary;
  static const Color textTertiary = lightTextTertiary;
  static const Color divider = lightDivider;
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2D7A7B), Color(0xFF38B2AC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
