// lib/core/animations/hover_scale_card.dart
// A wrapper widget that gives any child a smooth hover-lift + press-sink
// micro-interaction. Designed for web/desktop mouse interaction.
//
// Inspired by Stripe Dashboard and Linear card interactions.

import 'package:flutter/material.dart';

class HoverScaleCard extends StatefulWidget {
  final Widget child;
  final double hoverScale;
  final double pressScale;
  final Duration duration;
  final double hoverElevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const HoverScaleCard({
    super.key,
    required this.child,
    this.hoverScale = 1.015,
    this.pressScale = 0.98,
    this.duration = const Duration(milliseconds: 200),
    this.hoverElevation = 8,
    this.borderRadius,
    this.onTap,
  });

  @override
  State<HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<HoverScaleCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  double get _currentScale {
    if (_isPressed) return widget.pressScale;
    if (_isHovered) return widget.hoverScale;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          transformAlignment: Alignment.center,
          transform: Matrix4.diagonal3Values(_currentScale, _currentScale, 1.0),
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: widget.hoverElevation,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A subtle shimmer loading placeholder for skeleton screens.
/// Gives a premium feel while data loads.
class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1, 0),
              colors: isDark
                  ? [
                      const Color(0xFF1A1A2E),
                      const Color(0xFF252545),
                      const Color(0xFF1A1A2E),
                    ]
                  : [
                      const Color(0xFFF1F5F9),
                      const Color(0xFFE2E8F0),
                      const Color(0xFFF1F5F9),
                    ],
            ),
          ),
        );
      },
    );
  }
}
