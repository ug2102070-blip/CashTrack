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

  static const List<Color> categoryColors = [
    // Red / Coral / Rose
    Color(0xFFEF4444), // Red
    Color(0xFFF87171), // Light Red
    Color(0xFFF43F5E), // Rose
    Color(0xFFFB7185), // Light Rose
    
    // Orange / Amber / Yellow
    Color(0xFFF97316), // Orange
    Color(0xFFFB923C), // Light Orange
    Color(0xFFF59E0B), // Amber
    Color(0xFFFBBF24), // Yellow
    
    // Green / Teal / Emerald
    Color(0xFF10B981), // Emerald
    Color(0xFF34D399), // Light Emerald
    Color(0xFF22C55E), // Green
    Color(0xFF4ADE80), // Light Green
    Color(0xFF14B8A6), // Teal
    Color(0xFF2D7A7B), // CashTrack Primary
    
    // Blue / Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF60A5FA), // Light Blue
    Color(0xFF06B6D4), // Cyan
    Color(0xFF22D3EE), // Light Cyan
    
    // Purple / Violet / Indigo
    Color(0xFF6366F1), // Indigo
    Color(0xFF818CF8), // Light Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFA78BFA), // Light Violet
    Color(0xFFA855F7), // Purple
    
    // Pink / Magenta
    Color(0xFFEC4899), // Pink
    Color(0xFFF472B6), // Light Pink
    Color(0xFFF0ABFC), // Magenta/Purple
    
    // Neutral / Slate / Earthy
    Color(0xFF64748B), // Slate
    Color(0xFF94A3B8), // Light Slate
    Color(0xFF78716C), // Stone
    Color(0xFF95A5A6), // Gray
  ];

  /// Expense breakdown: vibrant, maximally distinct colors.
  static const List<Color> chartPaletteExpense = [
    Color(0xFF6366F1), // Indigo
    Color(0xFFEF4444), // Red
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFF8B5CF6), // Violet
    Color(0xFF14B8A6), // Teal
    Color(0xFFE11D48), // Rose
    Color(0xFF3B82F6), // Blue
    Color(0xFFA3E635), // Lime
  ];

  /// Income breakdown: vibrant, maximally distinct colors.
  static const List<Color> chartPaletteIncome = [
    Color(0xFF22C55E), // Green
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF97316), // Orange
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEF4444), // Red
    Color(0xFF14B8A6), // Teal
    Color(0xFFA855F7), // Purple
    Color(0xFFE11D48), // Rose
    Color(0xFF84CC16), // Lime
  ];

  // ── Helper ─────────────────────────────────────────────
  static Color withOpacity(Color color, double opacity) =>
      color.withValues(alpha: opacity);
}
