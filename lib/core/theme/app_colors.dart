// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ── Brand ──────────────────────────────────────────────
  static const Color primary = Color(0xFF2D7A7B);
  static const Color secondary = Color(0xFF6366F1);

  // ── Semantic ───────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── Transaction ────────────────────────────────────────
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFEF4444);

  // ── Backgrounds (light) ────────────────────────────────
  static const Color background = Color(0xFFF8FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ── Text ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // ── Divider ────────────────────────────────────────────
  static const Color divider = Color(0xFFE5E7EB);

  // ── Gradients ──────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2D7A7B), Color(0xFF38B2AC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Chart (legacy combined palette) ────────────────────
  static const List<Color> chartColors = [
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
  ];

  /// Expense breakdown: warm / coral / rose (visually distinct from income).
  static const List<Color> chartPaletteExpense = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEC4899),
    Color(0xFFFB7185),
    Color(0xFFF59E0B),
    Color(0xFFDC2626),
    Color(0xFFEA580C),
    Color(0xFFC026D3),
    Color(0xFFE11D48),
    Color(0xFF991B1B),
  ];

  /// Income breakdown: cool greens / teals / blues.
  static const List<Color> chartPaletteIncome = [
    Color(0xFF10B981),
    Color(0xFF14B8A6),
    Color(0xFF22C55E),
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
    Color(0xFF2DD4BF),
    Color(0xFF4ADE80),
    Color(0xFF0EA5E9),
    Color(0xFF059669),
    Color(0xFF2563EB),
  ];

  // ── Helper ─────────────────────────────────────────────
  static Color withOpacity(Color color, double opacity) =>
      color.withValues(alpha: opacity);
}
