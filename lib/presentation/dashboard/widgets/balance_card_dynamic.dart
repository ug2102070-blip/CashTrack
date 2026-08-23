// lib/presentation/dashboard/widgets/balance_card_dynamic.dart
import 'package:flutter/material.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/amount_mask.dart';

class BalanceCardDynamic extends StatefulWidget {
  final double totalBalance;
  final double income;
  final double expense;
  final String currency;
  final bool hideAmounts;
  final VoidCallback? onToggleReveal;

  const BalanceCardDynamic({
    super.key,
    required this.totalBalance,
    required this.income,
    required this.expense,
    required this.currency,
    required this.hideAmounts,
    this.onToggleReveal,
  });

  @override
  State<BalanceCardDynamic> createState() => _BalanceCardDynamicState();
}

class _BalanceCardDynamicState extends State<BalanceCardDynamic>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    // Derive richer gradient colors from the primary
    final gradientStart = primaryColor;
    final gradientMid = Color.lerp(primaryColor, Colors.teal, 0.35)!;
    final gradientEnd = Color.lerp(primaryColor, Colors.indigo.shade700, 0.5)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientMid, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.38),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle top-right
            Positioned(
              top: -32,
              right: -24,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -12,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Shimmer overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: AnimatedBuilder(
                  animation: _shimmerAnim,
                  builder: (context, _) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.03),
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.03),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: [
                            (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
                            (_shimmerAnim.value - 0.1).clamp(0.0, 1.0),
                            _shimmerAnim.value.clamp(0.0, 1.0),
                            (_shimmerAnim.value + 0.1).clamp(0.0, 1.0),
                            (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: Container(
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            context.t('total_balance'),
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      if (widget.onToggleReveal != null)
                        GestureDetector(
                          onTap: widget.onToggleReveal,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              widget.hideAmounts
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Balance amount with animated number
                  GestureDetector(
                    onTap: widget.onToggleReveal,
                    behavior: HitTestBehavior.translucent,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: widget.hideAmounts ? 0 : widget.totalBalance,
                      ),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Text(
                          formatAmount(
                            widget.currency,
                            widget.hideAmounts ? widget.totalBalance : value,
                            decimals: 2,
                            hide: widget.hideAmounts,
                          ),
                          style: AppTextStyles.h1.copyWith(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),

                  const SizedBox(height: 20),

                  // Income / Expense row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          label: context.t('income'),
                          amount: widget.income,
                          icon: Icons.arrow_downward_rounded,
                          iconBg: Colors.white.withValues(alpha: 0.18),
                          amountColor: Colors.greenAccent.shade100,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 44,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          label: context.t('expense'),
                          amount: widget.expense,
                          icon: Icons.arrow_upward_rounded,
                          iconBg: Colors.white.withValues(alpha: 0.18),
                          amountColor: Colors.red.shade100,
                          alignRight: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required double amount,
    required IconData icon,
    required Color iconBg,
    required Color amountColor,
    bool alignRight = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: alignRight ? 20 : 0,
        right: alignRight ? 0 : 20,
      ),
      child: Row(
        mainAxisAlignment:
            alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!alignRight)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 17),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: widget.onToggleReveal,
                  behavior: HitTestBehavior.translucent,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: widget.hideAmounts ? 0 : amount,
                    ),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Text(
                        formatAmount(widget.currency,
                            widget.hideAmounts ? amount : value,
                            decimals: 0, hide: widget.hideAmounts),
                        style: TextStyle(
                          color: amountColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (alignRight)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 17),
            ),
        ],
      ),
    );
  }
}
