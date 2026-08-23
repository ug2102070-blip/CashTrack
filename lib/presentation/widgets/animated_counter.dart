// lib/presentation/widgets/animated_counter.dart
import 'package:flutter/material.dart';

/// Smooth count-up animation for financial values.
///
/// Inspired by Stripe's dashboard counters — numbers feel alive
/// when they animate from 0 to the target value on mount.
class AnimatedCounter extends StatefulWidget {
  final double value;
  final String prefix;
  final String suffix;
  final int decimals;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final bool hide;
  final String hiddenText;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.hide = false,
    this.hiddenText = '••••••',
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = _animation.value;
      _animation = Tween<double>(begin: _oldValue, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hide) {
      return Text(
        '${widget.prefix}\u00A0${widget.hiddenText}${widget.suffix}',
        style: widget.style,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final val = _animation.value;
        return Text(
          '${widget.prefix}${val.toStringAsFixed(widget.decimals)}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
