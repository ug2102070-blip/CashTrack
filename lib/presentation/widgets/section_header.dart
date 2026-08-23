// lib/presentation/widgets/section_header.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

/// Consistent section header with title, subtitle, and optional action.
///
/// Used across dashboard, analytics, and other pages for visual hierarchy.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.actionIcon,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headingSm.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySm.copyWith(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionText != null && onAction != null)
            _ActionButton(
              text: actionText!,
              icon: actionIcon,
              onTap: onAction!,
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    this.icon,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                style: AppTextStyles.bodySm.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.icon != null) ...[
                const SizedBox(width: 4),
                Icon(widget.icon, size: 14, color: primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
