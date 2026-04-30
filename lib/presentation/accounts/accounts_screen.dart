import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/account_model.dart';
import '../providers/app_providers.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  static const _defaultCurrency = '৳';
  static const _accountIcons = ['💵', '🏦', '💳', '💰', '📱'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final totalBalance = ref.watch(accountsProvider.notifier).getTotalBalance();
    final settings = ref.watch(settingsProvider);
    final currency =
        (settings['currency'] as String?)?.trim().isNotEmpty == true
            ? settings['currency'] as String
            : _defaultCurrency;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.t('accounts')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAccountDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTotalBalanceCard(context, totalBalance, currency),
          Expanded(
            child: accounts.isEmpty
                ? _buildEmptyState(context, ref)
                : _buildAccountsList(context, ref, accounts, currency),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalanceCard(
    BuildContext context,
    double totalBalance,
    String currency,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.t('total_balance'),
                style: AppTextStyles.body1.copyWith(color: Colors.white70),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$currency${totalBalance.toStringAsFixed(2)}',
            style: AppTextStyles.h1.copyWith(
              color: Colors.white,
              fontSize: 32,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t('across_all_accounts'),
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList(
    BuildContext context,
    WidgetRef ref,
    List<AccountModel> accounts,
    String currency,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        return _buildAccountCard(context, ref, accounts[index], currency);
      },
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    WidgetRef ref,
    AccountModel account,
    String currency,
  ) {
    final gradient = _getAccountGradient(account.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              _sanitizeIcon(account.icon),
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        title: Text(
          account.name,
          style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account.nameBn.trim().isNotEmpty &&
                account.nameBn != account.name)
              Text(
                account.nameBn,
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _getAccountTypeLabel(context, account.type),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$currency${account.balance.toStringAsFixed(0)}',
              style: AppTextStyles.amountSmall.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!account.isDefault)
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditAccountDialog(context, ref, account);
                  } else if (value == 'delete') {
                    _deleteAccount(context, ref, account);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text(context.t('edit'))),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(context.t('delete')),
                  ),
                ],
              ),
          ],
        ),
        onTap: () => _showAccountDetails(context, ref, account, currency),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            context.t('no_accounts'),
            style: AppTextStyles.h3.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddAccountDialog(context, ref),
            icon: const Icon(Icons.add),
            label: Text(context.t('add_account')),
          ),
        ],
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final nameBnController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    final currency = _currencyFromSettings(ref.read(settingsProvider));
    AccountType selectedType = AccountType.cash;
    String selectedIcon = _accountIcons.first;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.t('new_account')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _accountIcons.map((icon) {
                    return InkWell(
                      onTap: () => setState(() => selectedIcon = icon),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selectedIcon == icon
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : null,
                          border: Border.all(
                            color: selectedIcon == icon
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(icon, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AccountType>(
                  initialValue: selectedType,
                  decoration: InputDecoration(labelText: context.t('type')),
                  items: AccountType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_getAccountTypeLabel(context, type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: context.t('name_english'),
                  ),
                ),
                TextField(
                  controller: nameBnController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: context.t('name_bangla'),
                  ),
                ),
                TextField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.t('initial_balance'),
                    prefixText: '$currency ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final nameBn = nameBnController.text.trim();
                final balance = double.tryParse(balanceController.text.trim());

                if (name.isEmpty || balance == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(context.t('enter_valid_amount'))),
                  );
                  return;
                }

                final account = AccountModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  nameBn: nameBn.isEmpty ? name : nameBn,
                  type: selectedType,
                  balance: balance,
                  icon: selectedIcon,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await ref.read(accountsProvider.notifier).addAccount(account);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: Text(context.t('add')),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAccountDialog(
    BuildContext context,
    WidgetRef ref,
    AccountModel account,
  ) {
    final nameController = TextEditingController(text: account.name);
    final nameBnController = TextEditingController(text: account.nameBn);
    final balanceController =
        TextEditingController(text: account.balance.toString());
    final currency = _currencyFromSettings(ref.read(settingsProvider));

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.t('edit_account')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration:
                    InputDecoration(labelText: context.t('name_english')),
              ),
              TextField(
                controller: nameBnController,
                textCapitalization: TextCapitalization.words,
                decoration:
                    InputDecoration(labelText: context.t('name_bangla')),
              ),
              TextField(
                controller: balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.t('balance'),
                  prefixText: '$currency ',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final nameBn = nameBnController.text.trim();
              final balance = double.tryParse(balanceController.text.trim());

              if (name.isEmpty || balance == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(context.t('enter_valid_amount'))),
                );
                return;
              }

              final updatedAccount = account.copyWith(
                name: name,
                nameBn: nameBn.isEmpty ? name : nameBn,
                balance: balance,
                updatedAt: DateTime.now(),
              );
              await ref
                  .read(accountsProvider.notifier)
                  .updateAccount(updatedAccount);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: Text(context.t('update')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(
    BuildContext context,
    WidgetRef ref,
    AccountModel account,
  ) async {
    final transactions = ref.read(transactionsProvider);
    final isLinked = transactions.any(
      (transaction) =>
          !transaction.isDeleted &&
          (transaction.accountId == account.id ||
              transaction.toAccountId == account.id),
    );

    if (isLinked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This account is linked to transactions. Delete those transactions first.',
          ),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.t('delete_account')),
        content: Text(
          context.t('delete_account_confirm', params: {'name': account.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref
                  .read(accountsProvider.notifier)
                  .deleteAccount(account.id);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text(context.t('account_deleted'))),
              );
            },
            child: Text(
              context.t('delete'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountDetails(
    BuildContext context,
    WidgetRef ref,
    AccountModel account,
    String currency,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(account.name, style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              '${context.t('balance')}: $currency${account.balance.toStringAsFixed(2)}',
              style: AppTextStyles.h3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showEditAccountDialog(context, ref, account);
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(context.t('edit')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text(context.t('close')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getAccountGradient(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF10B981)],
        );
      case AccountType.bank:
        return const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
        );
      case AccountType.mfs:
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        );
    }
  }

  String _getAccountTypeLabel(BuildContext context, AccountType type) {
    switch (type) {
      case AccountType.cash:
        return context.t('cash');
      case AccountType.bank:
        return context.t('bank');
      case AccountType.mfs:
        return context.t('mfs');
    }
  }

  String _sanitizeIcon(String? value) {
    final icon = value?.trim();
    if (icon == null || icon.isEmpty || icon.contains('ð')) {
      return _accountIcons.first;
    }
    return icon;
  }

  String _currencyFromSettings(Map<String, dynamic> settings) {
    final value = (settings['currency'] as String?)?.trim();
    if (value == null || value.isEmpty || value == '?' || value == 'à§³') {
      return _defaultCurrency;
    }
    return value;
  }
}
