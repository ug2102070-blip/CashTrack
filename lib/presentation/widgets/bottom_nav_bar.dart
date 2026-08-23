// lib/presentation/widgets/bottom_nav_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  bool _isToolsRoute(String location) {
    return location.startsWith('/tools') ||
        location.startsWith('/budget') ||
        location.startsWith('/debts') ||
        location.startsWith('/calculator') ||
        location.startsWith('/notes') ||
        location.startsWith('/investments') ||
        location.startsWith('/assets') ||
        location.startsWith('/split-expenses') ||
        location.startsWith('/emi-calculator') ||
        location.startsWith('/goals') ||
        location.startsWith('/subscriptions');
  }

  int _getCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location == '/' || location == '/dashboard') return 0;
    if (location.startsWith('/analytics')) return 1;
    if (_isToolsRoute(location)) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.3)
                    : AppColors.lightBorder.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavItem(
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard_rounded,
                          label: context.t('dashboard'),
                          isSelected: currentIndex == 0,
                          primaryColor: primary,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.go('/dashboard');
                          },
                        ),
                        _NavItem(
                          icon: Icons.analytics_outlined,
                          activeIcon: Icons.analytics_rounded,
                          label: context.t('analytics'),
                          isSelected: currentIndex == 1,
                          primaryColor: primary,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.go('/analytics');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 72),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavItem(
                          icon: Icons.grid_view_outlined,
                          activeIcon: Icons.grid_view_rounded,
                          label: context.t('planning'),
                          isSelected: currentIndex == 2,
                          primaryColor: primary,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.go('/tools');
                          },
                        ),
                        _NavItem(
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings_rounded,
                          label: context.t('settings'),
                          isSelected: currentIndex == 3,
                          primaryColor: primary,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.go('/settings');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label navigation',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(maxWidth: 76),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: isDark ? 0.12 : 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey('$label-$isSelected'),
                  color: isSelected ? primaryColor : unselectedColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primaryColor : unselectedColor,
                ),
                child:
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              // Active indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(top: 3),
                width: isSelected ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
