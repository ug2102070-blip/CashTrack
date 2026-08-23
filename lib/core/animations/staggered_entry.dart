// lib/core/animations/staggered_entry.dart
// A reusable mixin that provides fade+slide stagger animations for
// screen sections. Inspired by Linear's choreographed entry motion.
//
// Usage:
//   class _MyScreenState extends State<MyScreen>
//       with TickerProviderStateMixin, StaggeredEntryMixin {
//     @override int get staggerCount => 6; // number of animated items
//
//     Widget build(BuildContext context) {
//       return Column(children: [
//         staggerItem(index: 0, child: Header()),
//         staggerItem(index: 1, child: Body()),
//       ]);
//     }
//   }

import 'package:flutter/material.dart';

mixin StaggeredEntryMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late AnimationController _staggerController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  /// Override to set the number of staggered items.
  int get staggerCount => 8;

  /// Total animation duration. Defaults to 800ms.
  Duration get staggerDuration => const Duration(milliseconds: 800);

  /// Delay between each item in ms. Defaults to 60ms.
  int get staggerDelayMs => 60;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: staggerDuration,
    );

    final totalMs = staggerDuration.inMilliseconds.toDouble();

    _fadeAnimations = List.generate(staggerCount, (i) {
      final startMs = (i * staggerDelayMs).toDouble();
      final endMs = startMs + 300;
      final s = (startMs / totalMs).clamp(0.0, 1.0);
      final e = (endMs / totalMs).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _staggerController,
        curve: Interval(s, e, curve: Curves.easeOut),
      );
    });

    _slideAnimations = List.generate(staggerCount, (i) {
      final startMs = (i * staggerDelayMs).toDouble();
      final endMs = startMs + 300;
      final s = (startMs / totalMs).clamp(0.0, 1.0);
      final e = (endMs / totalMs).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(s, e, curve: Curves.easeOutCubic),
      ));
    });

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  /// Wraps a child widget with staggered fade+slide animation.
  Widget staggerItem({required int index, required Widget child}) {
    if (index >= staggerCount) return child;
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: child,
      ),
    );
  }
}
