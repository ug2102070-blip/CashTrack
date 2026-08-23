// lib/presentation/dashboard/widgets/premium_dashboard_widgets.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

// ─── 1. FINANCIAL HEALTH SCORE ──────────────────────────────────────────────
class FinancialHealthScore extends StatefulWidget {
  final double score; // 0 to 100
  final String statusText;
  final String detailText;
  const FinancialHealthScore({
    super.key,
    required this.score,
    required this.statusText,
    required this.detailText,
  });

  @override
  State<FinancialHealthScore> createState() => _FinancialHealthScoreState();
}

class _FinancialHealthScoreState extends State<FinancialHealthScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(FinancialHealthScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: _animation.value, end: widget.score).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getScoreLabel(double score) {
    if (score <= 0) return 'No Data';
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Poor';
  }

  Color _getScoreColor(double score) {
    if (score <= 0) return Colors.grey;
    if (score >= 85) return AppColors.success;
    if (score >= 70) return AppColors.primary;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentScore = _animation.value;
        final scoreColor = _getScoreColor(currentScore);
        final label = _getScoreLabel(currentScore);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder.withValues(alpha: 0.5)
                  : AppColors.lightBorder.withValues(alpha: 0.7),
            ),
            boxShadow: isDark ? AppColors.shadowDarkSm : AppColors.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FINANCIAL HEALTH',
                    style: AppTextStyles.overline.copyWith(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CustomPaint(
                      painter: _GaugePainter(
                        score: currentScore,
                        color: scoreColor,
                        isDark: isDark,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentScore.toStringAsFixed(0),
                              style: AppTextStyles.headingMd.copyWith(
                                fontSize: 24,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                            ),
                            Text(
                              '/100',
                              style: AppTextStyles.caption.copyWith(
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.statusText,
                          style: AppTextStyles.bodySm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.detailText,
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;
  final bool isDark;

  _GaugePainter({required this.score, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0;

    final basePaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // We paint a semi-circle or a 3/4 circle
    const startAngle = 3 * math.pi / 4;
    const sweepAngle = 3 * math.pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      basePaint,
    );

    final scoreSweep = (score / 100) * sweepAngle;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      scoreSweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}

// ─── 2. SPENDING HEATMAP ─────────────────────────────────────────────────────
class SpendingHeatmap extends StatelessWidget {
  final List<int> simulatedData;
  const SpendingHeatmap({super.key, required this.simulatedData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getBlockColor(int level, bool isDark) {
      if (level == 0) {
        return isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04);
      }
      const baseColor = AppColors.primary;
      switch (level) {
        case 1:
          return baseColor.withValues(alpha: 0.25);
        case 2:
          return baseColor.withValues(alpha: 0.55);
        default:
          return baseColor;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : AppColors.lightBorder.withValues(alpha: 0.7),
        ),
        boxShadow: isDark ? AppColors.shadowDarkSm : AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPENDING INTENSITY',
                style: AppTextStyles.overline.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
              Text(
                'Last 4 Weeks',
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Day labels
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ['Mon', 'Wed', 'Fri', 'Sun'].map((day) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      day,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 9,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 12),
              // Heatmap grid
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (weekIndex) {
                    return Column(
                      children: List.generate(7, (dayIndex) {
                        final dataIndex = (weekIndex * 7) + dayIndex;
                        final val = simulatedData[dataIndex];
                        return Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: getBlockColor(val, isDark),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: AppTextStyles.caption.copyWith(fontSize: 9, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
              ),
              const SizedBox(width: 4),
              ...List.generate(4, (i) {
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: getBlockColor(i, isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(
                'More',
                style: AppTextStyles.caption.copyWith(fontSize: 9, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 3. UPCOMING BILLS TIMELINE ──────────────────────────────────────────────
class UpcomingBillItem {
  final String name;
  final String amount;
  final String dueDate;
  final Color color;
  UpcomingBillItem({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.color,
  });
}

class UpcomingBillsTimeline extends StatelessWidget {
  final List<UpcomingBillItem> bills;
  const UpcomingBillsTimeline({super.key, required this.bills});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : AppColors.lightBorder.withValues(alpha: 0.7),
        ),
        boxShadow: isDark ? AppColors.shadowDarkSm : AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPCOMING BILLS',
            style: AppTextStyles.overline.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 16),
          if (bills.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No upcoming bills in the next 30 days',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bills.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final bill = bills[index];
                return Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: bill.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.name,
                            style: AppTextStyles.bodySm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bill.dueDate,
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      bill.amount,
                      style: AppTextStyles.amountCompact.copyWith(
                        fontSize: 14,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

// ─── 4. WEEKLY SPENDING STREAK ───────────────────────────────────────────────
class WeeklySpendingStreak extends StatelessWidget {
  final int streakDays;
  final List<bool> dailyStatus;
  const WeeklySpendingStreak({
    super.key,
    required this.streakDays,
    required this.dailyStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : AppColors.lightBorder.withValues(alpha: 0.7),
        ),
        boxShadow: isDark ? AppColors.shadowDarkSm : AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEEKLY STREAK',
                style: AppTextStyles.overline.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$streakDays Days Under Budget',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isUnderBudget = index < dailyStatus.length ? dailyStatus[index] : false;
              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isUnderBudget
                          ? AppColors.success.withValues(alpha: isDark ? 0.15 : 0.08)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUnderBudget
                            ? AppColors.success
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isUnderBudget ? Icons.check_rounded : Icons.close_rounded,
                        size: 14,
                        color: isUnderBudget
                            ? AppColors.success
                            : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[index],
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── 5. AI FINANCIAL INSIGHTS CARD ───────────────────────────────────────────
class AiFinancialInsightsCard extends StatelessWidget {
  final String insightText;
  final VoidCallback onSetLimit;
  final VoidCallback onDismiss;
  const AiFinancialInsightsCard({
    super.key,
    required this.insightText,
    required this.onSetLimit,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkSurface,
                  const Color(0xFF1E1635),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF9F5FF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
        ),
        boxShadow: isDark ? AppColors.shadowDarkSm : AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'AI INSIGHT',
                style: AppTextStyles.overline.copyWith(
                  color: const Color(0xFF8B5CF6),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            insightText,
            style: AppTextStyles.bodySm.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              InkWell(
                onTap: onSetLimit,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Set Limit',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Dismiss',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 6. SMART RECOMMENDATIONS ────────────────────────────────────────────────
class SmartRecommendationItem {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  SmartRecommendationItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}

class SmartRecommendations extends StatelessWidget {
  final List<SmartRecommendationItem> recommendations;
  const SmartRecommendations({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : AppColors.lightBorder.withValues(alpha: 0.7),
        ),
        boxShadow: isDark ? AppColors.shadowDarkSm : AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SMART RECOMMENDATIONS',
            style: AppTextStyles.overline.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommendations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = recommendations[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.color, size: 16),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTextStyles.bodySm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.desc,
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
