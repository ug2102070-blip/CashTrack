// lib/core/animations/page_transitions.dart
// Premium page transitions inspired by Linear, Fable, and Stripe.
// Provides smooth, purposeful motion that enhances UX clarity.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A fade + subtle slide-up transition that feels like Fable/Linear.
/// Duration: 280ms — fast enough to feel snappy, slow enough to perceive.
CustomTransitionPage<void> fadeSlideTransitionPage({
  required Widget child,
  required GoRouterState state,
  Duration duration = const Duration(milliseconds: 280),
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

/// A scale + fade transition for modals and overlays.
/// Gives a premium "pop-in" feel, inspired by Apple HIG.
CustomTransitionPage<void> scaleTransitionPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

/// A slide-from-right transition for drill-down navigation.
/// Used for detail pages, profiles, etc.
CustomTransitionPage<void> slideRightTransitionPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}
