// lib/presentation/widgets/glass_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium glassmorphism card widget.
///
/// Use sparingly — only for header, sidebar, modals, and hero sections.
/// NOT for every dashboard card.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 12,
    this.opacity = 0.7,
    this.padding,
    this.margin,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: opacity);

    final border = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06));

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: border, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
