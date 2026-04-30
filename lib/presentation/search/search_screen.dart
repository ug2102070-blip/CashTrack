import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/transaction_model.dart';
import '../providers/app_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final accounts = ref.watch(accountsProvider);
    final settings = ref.watch(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '৳';

    final categoryMap = {for (final c in categories) c.id: c.name};
    final accountMap = {for (final a in accounts) a.id: a.name};
    final filtered = _filterTransactions(
      transactions: transactions,
      query: _query,
      categoryMap: categoryMap,
      accountMap: accountMap,
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.t('search'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: context.t('search_hint'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _query.isEmpty
                          ? context.t('start_typing_to_search')
                          : context.t('no_matches_found'),
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final t = filtered[index];
                      final isIncome = t.type == TransactionType.income;
                      final amountColor =
                          isIncome ? AppColors.success : AppColors.error;
                      return ListTile(
                        title: Text(categoryMap[t.categoryId] ?? t.categoryId),
                        subtitle: Text(
                          '${accountMap[t.accountId] ?? t.accountId} â€¢ ${DateFormat('dd MMM yyyy, hh:mm a').format(t.date)}',
                        ),
                        trailing: Text(
                          '${isIncome ? '+' : '-'} $currency${t.amount.toStringAsFixed(0)}',
                          style: AppTextStyles.body1.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<TransactionModel> _filterTransactions({
    required List<TransactionModel> transactions,
    required String query,
    required Map<String, String> categoryMap,
    required Map<String, String> accountMap,
  }) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();

    final filtered = transactions.where((t) {
      final amountStr = t.amount.toStringAsFixed(2);
      final note = (t.note ?? '').toLowerCase();
      final category =
          (categoryMap[t.categoryId] ?? t.categoryId).toLowerCase();
      final account = (accountMap[t.accountId] ?? t.accountId).toLowerCase();

      return amountStr.contains(q) ||
          note.contains(q) ||
          category.contains(q) ||
          account.contains(q);
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }
}


