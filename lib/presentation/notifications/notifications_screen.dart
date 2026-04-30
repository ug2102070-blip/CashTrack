// lib/presentation/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/app_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final budgets =
        ref.watch(budgetsProvider.notifier).getBudgetsForCurrentMonth();
    final debts = ref.watch(debtsProvider);
    final categories = ref.watch(categoriesProvider);
    final settings = ref.watch(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '৳';
    final categoryMap = {for (final c in categories) c.id: c.name};
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = <_NotifItem>[];

    if (summary.totalBalance <= 0) {
      items.add(_NotifItem(
        title: context.t('low_balance'),
        body: context.t('low_balance_body', params: {
          'amount': '$currency${summary.totalBalance.toStringAsFixed(0)}',
        }),
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.error,
        createdAt: DateTime.now(),
        priority: _Priority.high,
      ));
    }

    for (final b in budgets) {
      if (b.amount <= 0) continue;
      final catName = categoryMap[b.categoryId] ?? b.categoryId;
      final ratio = b.spent / b.amount;
      if (ratio >= 1) {
        items.add(_NotifItem(
          title: context.t('budget_exceeded'),
          body: context.t('budget_used_percent', params: {
            'category': catName,
            'percent': (ratio * 100).toStringAsFixed(0),
          }),
          icon: Icons.warning_amber_rounded,
          color: AppColors.error,
          createdAt: DateTime.now(),
          priority: _Priority.high,
        ));
      } else if (ratio >= 0.9) {
        items.add(_NotifItem(
          title: context.t('budget_nearly_full'),
          body: context.t('budget_used_percent', params: {
            'category': catName,
            'percent': (ratio * 100).toStringAsFixed(0),
          }),
          icon: Icons.notifications_active_rounded,
          color: AppColors.warning,
          createdAt: DateTime.now(),
          priority: _Priority.medium,
        ));
      }
    }

    for (final d in debts.where((d) => !d.isSettled && d.dueDate != null)) {
      if (d.dueDate!.isBefore(DateTime.now().add(const Duration(days: 3)))) {
        items.add(_NotifItem(
          title: context.t('debt_due_soon'),
          body: context.t('debt_due_body', params: {
            'name': d.personName,
            'date': DateFormat('dd MMM yyyy').format(d.dueDate!),
          }),
          icon: Icons.schedule_rounded,
          color: AppColors.info,
          createdAt: d.dueDate!,
          priority: _Priority.medium,
        ));
      }
    }

    items.sort((a, b) {
      final pCmp = b.priority.index.compareTo(a.priority.index);
      if (pCmp != 0) return pCmp;
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('notifications'),
                          style: AppTextStyles.h2.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.3,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          items.isEmpty
                              ? context.t('all_clear')
                              : context.t('alerts_count', params: {
                                  'count': items.length.toString(),
                                }),
                          style: AppTextStyles.caption.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: items.isEmpty
                  ? _buildEmpty(context)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _buildCard(context, items[i], isDark),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    _NotifItem item,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.priority == _Priority.high
              ? item.color.withValues(alpha: 0.25)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: item.priority == _Priority.high
                ? item.color.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (item.priority == _Priority.high)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          context.t('alert'),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: item.color,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 34,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.t('caught_up'),
            style: AppTextStyles.h5.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.t('no_alerts'),
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Priority { medium, high }

class _NotifItem {
  const _NotifItem({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.createdAt,
    required this.priority,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final DateTime createdAt;
  final _Priority priority;
}


