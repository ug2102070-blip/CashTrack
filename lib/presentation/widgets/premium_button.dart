// lib/presentation/widgets/premium_button.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Premium button system with multiple variants.
///
/// Variants:
/// - [PremiumButton.primary] — Solid filled with accent color
/// - [PremiumButton.secondary] — Outlined with border
/// - [PremiumButton.ghost] — Text-only with hover background
/// - [PremiumButton.gradient] — Gradient filled (use for CTAs)
enum PremiumButtonVariant { primary, secondary, ghost, gradient }

class PremiumButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final PremiumButtonVariant variant;
  final bool isLoading;
  final bool compact;
  final Color? color;

  const PremiumButton({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.variant = PremiumButtonVariant.primary,
    this.isLoading = false,
    this.compact = false,
    this.color,
  });

  const PremiumButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.isLoading = false,
    this.compact = false,
    this.color,
  }) : variant = PremiumButtonVariant.primary;

  const PremiumButton.secondary({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.isLoading = false,
    this.compact = false,
    this.color,
  }) : variant = PremiumButtonVariant.secondary;

  const PremiumButton.ghost({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.isLoading = false,
    this.compact = false,
    this.color,
  }) : variant = PremiumButtonVariant.ghost;

  const PremiumButton.gradient({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.isLoading = false,
    this.compact = false,
    this.color,
  }) : variant = PremiumButtonVariant.gradient;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = widget.color ?? theme.colorScheme.primary;
    final disabled = widget.onPressed == null;
    final double opacity = disabled ? 0.5 : (_pressed ? 0.85 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: disabled ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(
              _pressed ? 0.97 : 1.0,
              _pressed ? 0.97 : 1.0,
              1.0,
            ),
            transformAlignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 14 : 20,
              vertical: widget.compact ? 8 : 12,
            ),
            decoration: _buildDecoration(primary, isDark),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _foregroundColor(primary, isDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: widget.compact ? 16 : 18,
                    color: _foregroundColor(primary, isDark),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: (widget.compact
                          ? AppTextStyles.buttonSmall
                          : AppTextStyles.button)
                      .copyWith(
                    color: _foregroundColor(primary, isDark),
                  ),
                ),
                if (widget.trailingIcon != null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    widget.trailingIcon,
                    size: widget.compact ? 14 : 16,
                    color: _foregroundColor(primary, isDark),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(Color primary, bool isDark) {
    switch (widget.variant) {
      case PremiumButtonVariant.primary:
        return BoxDecoration(
          color: _hovered ? primary.withValues(alpha: 0.9) : primary,
          borderRadius: BorderRadius.circular(12),
        );
      case PremiumButtonVariant.secondary:
        return BoxDecoration(
          color: _hovered
              ? primary.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
            width: 1,
          ),
        );
      case PremiumButtonVariant.ghost:
        return BoxDecoration(
          color: _hovered
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        );
      case PremiumButtonVariant.gradient:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primary,
              Color.lerp(primary, AppColors.accent, 0.4)!,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        );
    }
  }

  Color _foregroundColor(Color primary, bool isDark) {
    switch (widget.variant) {
      case PremiumButtonVariant.primary:
      case PremiumButtonVariant.gradient:
        return Colors.white;
      case PremiumButtonVariant.secondary:
        return isDark ? AppColors.darkText : AppColors.lightText;
      case PremiumButtonVariant.ghost:
        return isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    }
  }
}
