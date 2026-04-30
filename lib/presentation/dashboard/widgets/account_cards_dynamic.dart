// lib/presentation/dashboard/widgets/account_cards_dynamic.dart
import 'package:flutter/material.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/amount_mask.dart';
import '../../../data/models/account_model.dart';

class AccountCardsDynamic extends StatelessWidget {
  final List<AccountModel> accounts;
  final String currency;
  final bool hideAmounts;
  final ValueChanged<AccountModel>? onAccountTap;
  final VoidCallback? onAmountTap;

  const AccountCardsDynamic({
    super.key,
    required this.accounts,
    required this.currency,
    required this.hideAmounts,
    this.onAccountTap,
    this.onAmountTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayAccounts = accounts.take(2).toList();
    if (displayAccounts.isEmpty) return _buildEmptyState(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          if (displayAccounts.isNotEmpty)
            Expanded(
              child: _buildAccountCard(
                context: context,
                account: displayAccounts[0],
                gradientColors: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                shadowColor: const Color(0xFF11998E),
              ),
            ),
          if (displayAccounts.length > 1) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _buildAccountCard(
                context: context,
                account: displayAccounts[1],
                gradientColors: const [Color(0xFF2563EB), Color(0xFF60A5FA)],
                shadowColor: const Color(0xFF2563EB),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountCard({
    required BuildContext context,
    required AccountModel account,
    required List<Color> gradientColors,
    required Color shadowColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onAccountTap == null ? null : () => onAccountTap!(account),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with gradient background
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  account.icon ?? '💰',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Account name
            Text(
              account.name,
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 5),

            // Balance
            GestureDetector(
              onTap: onAmountTap,
              behavior: HitTestBehavior.translucent,
              child: Text(
                formatAmount(currency, account.balance, hide: hideAmounts),
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  fontSize: 19,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Transfer hint chip
            if (onAccountTap != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: gradientColors.first.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz_rounded,
                        size: 12, color: gradientColors.first),
                    const SizedBox(width: 3),
                    Text(
                      context.t('transfer'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: gradientColors.first,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(
        child: Text(
          context.t('no_accounts'),
          style: AppTextStyles.body2.copyWith(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
