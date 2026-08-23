// lib/presentation/widgets/stat_card.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Premium stat card for dashboard metrics.
///
/// Features: icon with tinted background, label, animated value,
/// optional change indicator, and hover lift animation.
class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;
  final String? changeText;
  final bool? changePositive;
  final VoidCallback? onTap;
  final bool compact;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
    this.changeText,
    this.changePositive,
    this.onTap,
    this.compact = false,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.accentColor ?? theme.colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0.0, _hovered ? -2.0 : 0.0, 0.0),
          padding: EdgeInsets.all(widget.compact ? 16 : 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? color.withValues(alpha: 0.2)
                  : (isDark
                      ? AppColors.darkBorder.withValues(alpha: 0.5)
                      : AppColors.lightBorder.withValues(alpha: 0.7)),
              width: 1,
            ),
            boxShadow: _hovered
                ? (isDark ? AppColors.shadowDarkMd : AppColors.shadowMd)
                : (isDark ? AppColors.shadowDarkSm : AppColors.shadowSm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Icon with tinted background
                  Container(
                    width: widget.compact ? 32 : 36,
                    height: widget.compact ? 32 : 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      size: widget.compact ? 16 : 18,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  // Change indicator
                  if (widget.changeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (widget.changePositive == true
                                ? AppColors.success
                                : AppColors.error)
                            .withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.changePositive == true
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 12,
                            color: widget.changePositive == true
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.changeText!,
                            style: AppTextStyles.caption.copyWith(
                              color: widget.changePositive == true
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: widget.compact ? 12 : 16),
              // Label
              Text(
                widget.label.toUpperCase(),
                style: AppTextStyles.overline.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
              const SizedBox(height: 4),
              // Value
              Text(
                widget.value,
                style: (widget.compact
                        ? AppTextStyles.amountSmall
                        : AppTextStyles.amountMedium)
                    .copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
