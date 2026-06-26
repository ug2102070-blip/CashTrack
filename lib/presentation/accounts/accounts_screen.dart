import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/account_model.dart';
import '../providers/app_providers.dart';
import '../dashboard/widgets/brand_logo.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  static const _defaultCurrency = '৳';


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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: BrandLogo(
          name: account.name,
          icon: account.icon,
          size: 37,
        ),
        title: Text(
          account.nickname?.isNotEmpty == true
              ? account.nickname!
              : account.name,
          style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account.nickname?.isNotEmpty == true)
              Text(
                account.name,
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
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
            if (_accountMetaSummary(account) != null) ...[
              const SizedBox(height: 2),
              Text(
                _accountMetaSummary(account)!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$currency${account.balance.toStringAsFixed(0)}',
              style: AppTextStyles.amountSmall.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
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
    final currency = _currencyFromSettings(ref.read(settingsProvider));
    _showAccountFormDialog(
      context: context,
      ref: ref,
      title: context.t('new_account'),
      submitLabel: context.t('add'),
      currency: currency,
      onSubmit: (data) async {
        final account = AccountModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: data.name,
          nameBn: data.nameBn.isEmpty ? data.name : data.nameBn,
          type: data.type,
          balance: data.balance,
          icon: data.icon,
          colorHex: data.colorHex,
          nickname: data.nickname,
          accountNumber: data.accountNumber,
          cardType: data.cardType,
          cardIssuer: data.cardIssuer,
          cardholderName: data.cardholderName,
          creditLimit: data.creditLimit,
          billingDay: data.billingDay,
          paymentDueDay: data.paymentDueDay,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(accountsProvider.notifier).addAccount(account);
      },
    );
  }

  void _showEditAccountDialog(
    BuildContext context,
    WidgetRef ref,
    AccountModel account,
  ) {
    final currency = _currencyFromSettings(ref.read(settingsProvider));
    _showAccountFormDialog(
      context: context,
      ref: ref,
      title: context.t('edit_account'),
      submitLabel: context.t('update'),
      currency: currency,
      initialAccount: account,
      onSubmit: (data) async {
        final updatedAccount = account.copyWith(
          name: data.name,
          nameBn: data.nameBn.isEmpty ? data.name : data.nameBn,
          type: data.type,
          icon: data.icon,
          colorHex: data.colorHex,
          nickname: data.nickname,
          balance: data.balance,
          accountNumber: data.accountNumber,
          cardType: data.cardType,
          cardIssuer: data.cardIssuer,
          cardholderName: data.cardholderName,
          creditLimit: data.creditLimit,
          billingDay: data.billingDay,
          paymentDueDay: data.paymentDueDay,
          updatedAt: DateTime.now(),
        );
        await ref.read(accountsProvider.notifier).updateAccount(updatedAccount);
      },
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
            Text(
              account.nickname?.isNotEmpty == true
                  ? account.nickname!
                  : account.name,
              style: AppTextStyles.h2,
            ),
            if (account.nickname?.isNotEmpty == true)
              Text(
                account.name,
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '${context.t('balance')}: $currency${account.balance.toStringAsFixed(2)}',
              style: AppTextStyles.h3.copyWith(color: AppColors.primary),
            ),
            if (_accountDetailRows(account).isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._accountDetailRows(account).map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.label,
                          style: AppTextStyles.caption.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          row.value,
                          textAlign: TextAlign.end,
                          style: AppTextStyles.body2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  String? _accountMetaSummary(AccountModel account) {
    final number = account.accountNumber?.trim();
    if (account.type == AccountType.creditCard) {
      final parts = [
        account.cardType?.trim(),
        account.cardIssuer?.trim(),
        if (number != null && number.isNotEmpty) '**** ${_lastFour(number)}',
      ].where((part) => part != null && part.isNotEmpty).cast<String>();
      final summary = parts.join(' • ');
      return summary.isEmpty ? null : summary;
    }
    if (number == null || number.isEmpty) return null;
    return '${account.type == AccountType.mfs ? 'Number' : 'Account'}: $number';
  }

  List<_AccountDetailRow> _accountDetailRows(AccountModel account) {
    final rows = <_AccountDetailRow>[];
    final number = account.accountNumber?.trim();
    if (number != null && number.isNotEmpty) {
      rows.add(
        _AccountDetailRow(
          account.type == AccountType.creditCard
              ? 'Card Number'
              : account.type == AccountType.mfs
                  ? 'Mobile Number'
                  : 'Account Number',
          account.type == AccountType.creditCard ? '**** ${_lastFour(number)}' : number,
        ),
      );
    }
    void addText(String label, String? value) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) rows.add(_AccountDetailRow(label, text));
    }

    if (account.type == AccountType.creditCard) {
      addText('Card Type', account.cardType);
      addText('Issuer', account.cardIssuer);
      addText('Cardholder', account.cardholderName);
      if (account.creditLimit != null) {
        rows.add(
          _AccountDetailRow(
            'Limit',
            account.creditLimit!.toStringAsFixed(
              account.creditLimit!.truncateToDouble() == account.creditLimit ? 0 : 2,
            ),
          ),
        );
      }
      if (account.billingDay != null) {
        rows.add(_AccountDetailRow('Billing Day', account.billingDay.toString()));
      }
      if (account.paymentDueDay != null) {
        rows.add(_AccountDetailRow('Due Day', account.paymentDueDay.toString()));
      }
    }
    return rows;
  }

  String _lastFour(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return digits;
    return digits.substring(digits.length - 4);
  }


  String _getAccountTypeLabel(BuildContext context, AccountType type) {
    switch (type) {
      case AccountType.cash:
        return context.t('cash');
      case AccountType.bank:
        return context.t('bank');
      case AccountType.mfs:
        return context.t('mfs');
      case AccountType.creditCard:
        return context.t('credit_card');
    }
  }


  String _currencyFromSettings(Map<String, dynamic> settings) {
    final value = (settings['currency'] as String?)?.trim();
    if (value == null || value.isEmpty || value == '?' || value == 'à§³') {
      return _defaultCurrency;
    }
    return value;
  }

  void _showAccountFormDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String submitLabel,
    required String currency,
    required Future<void> Function(_AccountFormData data) onSubmit,
    AccountModel? initialAccount,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _AccountFormDialog(
        title: title,
        submitLabel: submitLabel,
        currency: currency,
        initialAccount: initialAccount,
        onSubmit: (data) async {
          await onSubmit(data);
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        },
      ),
    );
  }
}

class _AccountDetailRow {
  const _AccountDetailRow(this.label, this.value);

  final String label;
  final String value;
}

class _AccountFormData {
  const _AccountFormData({
    required this.name,
    required this.nameBn,
    required this.type,
    required this.balance,
    required this.icon,
    required this.colorHex,
    this.nickname,
    this.accountNumber,
    this.cardType,
    this.cardIssuer,
    this.cardholderName,
    this.creditLimit,
    this.billingDay,
    this.paymentDueDay,
  });

  final String name;
  final String nameBn;
  final AccountType type;
  final double balance;
  final String icon;
  final String colorHex;
  final String? nickname;
  final String? accountNumber;
  final String? cardType;
  final String? cardIssuer;
  final String? cardholderName;
  final double? creditLimit;
  final int? billingDay;
  final int? paymentDueDay;
}

class AccountProviderTemplate {
  final String key;
  final String name;
  final String nameBn;
  final AccountType type;
  final String icon;
  final String colorHex;

  const AccountProviderTemplate({
    required this.key,
    required this.name,
    required this.nameBn,
    required this.type,
    required this.icon,
    required this.colorHex,
  });
}

const List<AccountProviderTemplate> _accountTemplates = [
  AccountProviderTemplate(
    key: 'cash',
    name: 'Cash',
    nameBn: 'নগদ',
    type: AccountType.cash,
    icon: '💵',
    colorHex: '#10B981',
  ),
  AccountProviderTemplate(
    key: 'bkash',
    name: 'bKash',
    nameBn: 'বিকাশ',
    type: AccountType.mfs,
    icon: '📱',
    colorHex: '#E2136E',
  ),
  AccountProviderTemplate(
    key: 'nagad',
    name: 'Nagad',
    nameBn: 'নগদ (ডিজিটাল)',
    type: AccountType.mfs,
    icon: '📲',
    colorHex: '#F6921E',
  ),
  AccountProviderTemplate(
    key: 'rocket',
    name: 'Rocket',
    nameBn: 'রকেট',
    type: AccountType.mfs,
    icon: '🚀',
    colorHex: '#8C1D8C',
  ),
  AccountProviderTemplate(
    key: 'upay',
    name: 'Upay',
    nameBn: 'উপায়',
    type: AccountType.mfs,
    icon: '💚',
    colorHex: '#00A651',
  ),
  AccountProviderTemplate(
    key: 'mcash',
    name: 'mCash',
    nameBn: 'এমক্যাশ',
    type: AccountType.mfs,
    icon: '💸',
    colorHex: '#059669',
  ),
  AccountProviderTemplate(
    key: 'tap',
    name: 'tap',
    nameBn: 'ট্যাপ',
    type: AccountType.mfs,
    icon: '📲',
    colorHex: '#E11D48',
  ),
  AccountProviderTemplate(
    key: 'mycash',
    name: 'MyCash',
    nameBn: 'মাইক্যাশ',
    type: AccountType.mfs,
    icon: '📱',
    colorHex: '#FFB300',
  ),
  AccountProviderTemplate(
    key: 'cellfin',
    name: 'CellFin',
    nameBn: 'সেলফিন',
    type: AccountType.mfs,
    icon: '🌀',
    colorHex: '#0284C7',
  ),
  AccountProviderTemplate(
    key: 'okwallet',
    name: 'OK Wallet',
    nameBn: 'ওকে ওয়ালেট',
    type: AccountType.mfs,
    icon: '🆗',
    colorHex: '#E2136E',
  ),
  AccountProviderTemplate(
    key: 'surecash',
    name: 'SureCash',
    nameBn: 'শিওরক্যাশ',
    type: AccountType.mfs,
    icon: '🟠',
    colorHex: '#EA580C',
  ),
  AccountProviderTemplate(
    key: 'pocket',
    name: 'Pocket',
    nameBn: 'পকেট',
    type: AccountType.mfs,
    icon: '👛',
    colorHex: '#2563EB',
  ),
  AccountProviderTemplate(
    key: 'binimoy',
    name: 'Binimoy',
    nameBn: 'বিনিময়',
    type: AccountType.mfs,
    icon: '🔄',
    colorHex: '#059669',
  ),
  AccountProviderTemplate(
    key: 'bank',
    name: 'Bank',
    nameBn: 'ব্যাংক',
    type: AccountType.bank,
    icon: '🏦',
    colorHex: '#3B82F6',
  ),
  AccountProviderTemplate(
    key: 'credit_card',
    name: 'Credit Card',
    nameBn: 'ক্রেডিট কার্ড',
    type: AccountType.creditCard,
    icon: '💳',
    colorHex: '#8B5CF6',
  ),
  AccountProviderTemplate(
    key: 'debit_card',
    name: 'Debit Card',
    nameBn: 'ডেবিট কার্ড',
    type: AccountType.creditCard,
    icon: '💳',
    colorHex: '#0D9488',
  ),
];

class _AccountFormDialog extends StatefulWidget {
  const _AccountFormDialog({
    required this.title,
    required this.submitLabel,
    required this.currency,
    required this.onSubmit,
    this.initialAccount,
  });

  final String title;
  final String submitLabel;
  final String currency;
  final Future<void> Function(_AccountFormData data) onSubmit;
  final AccountModel? initialAccount;

  @override
  State<_AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<_AccountFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _nameBnController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _cardIssuerController;
  late final TextEditingController _cardholderController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _billingDayController;
  late final TextEditingController _paymentDueDayController;

  late String _selectedTemplateKey;
  late AccountType _selectedType;
  late String _selectedIcon;
  late String _selectedColorHex;
  String _cardType = 'Credit Card';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final account = widget.initialAccount;
    
    _cardType = account?.cardType?.trim().isNotEmpty == true
        ? account!.cardType!
        : 'Credit Card';

    // Find starting template
    AccountProviderTemplate startTemplate = _accountTemplates.first;
    if (account != null) {
      final nameLower = account.name.toLowerCase();
      if (nameLower.contains('bkash')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'bkash');
      } else if (nameLower.contains('nagad')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'nagad');
      } else if (nameLower.contains('rocket')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'rocket');
      } else if (nameLower.contains('upay')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'upay');
      } else if (nameLower.contains('mcash')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'mcash');
      } else if (nameLower.contains('tap')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'tap');
      } else if (nameLower.contains('mycash')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'mycash');
      } else if (nameLower.contains('cellfin')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'cellfin');
      } else if (nameLower.contains('okwallet') || nameLower.contains('ok wallet')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'okwallet');
      } else if (nameLower.contains('surecash') || nameLower.contains('sure cash')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'surecash');
      } else if (nameLower.contains('pocket')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'pocket');
      } else if (nameLower.contains('binimoy')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'binimoy');
      } else if (nameLower.contains('cash')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'cash');
      } else if (nameLower.contains('debit')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'debit_card');
        _cardType = 'Debit Card';
      } else if (nameLower.contains('credit')) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'credit_card');
        _cardType = 'Credit Card';
      } else if (account.type == AccountType.bank) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'bank');
      } else if (account.type == AccountType.creditCard) {
        startTemplate = _accountTemplates.firstWhere((t) => t.key == 'credit_card');
      }
    } else {
      // New account
      startTemplate = _accountTemplates.firstWhere((t) => t.key == 'cash');
    }

    _selectedTemplateKey = startTemplate.key;
    _selectedType = account?.type ?? startTemplate.type;
    _selectedIcon = account?.icon ?? startTemplate.icon;
    _selectedColorHex = account?.colorHex ?? startTemplate.colorHex;

    _nameController = TextEditingController(text: account?.name ?? startTemplate.name);
    _nameBnController = TextEditingController(text: account?.nameBn ?? startTemplate.nameBn);
    _nicknameController = TextEditingController(text: account?.nickname ?? '');
    _balanceController = TextEditingController(
      text: account?.balance.toString() ?? '0',
    );
    _accountNumberController = TextEditingController(
      text: account?.accountNumber ?? '',
    );
    _cardIssuerController = TextEditingController(
      text: account?.cardIssuer ?? '',
    );
    _cardholderController = TextEditingController(
      text: account?.cardholderName ?? '',
    );
    _creditLimitController = TextEditingController(
      text: account?.creditLimit?.toString() ?? '',
    );
    _billingDayController = TextEditingController(
      text: account?.billingDay?.toString() ?? '',
    );
    _paymentDueDayController = TextEditingController(
      text: account?.paymentDueDay?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameBnController.dispose();
    _nicknameController.dispose();
    _balanceController.dispose();
    _accountNumberController.dispose();
    _cardIssuerController.dispose();
    _cardholderController.dispose();
    _creditLimitController.dispose();
    _billingDayController.dispose();
    _paymentDueDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: AppTextStyles.h2),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProviderPicker(),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _nicknameController,
                        label: context.t('nickname_optional'),
                        hint: 'e.g. Personal, Agent, Office',
                        helperText: isBn
                            ? 'একাধিক অ্যাকাউন্ট (যেমন ২টা বিকাশ) আলাদা করতে ব্যবহার করুন'
                            : 'Helps distinguish if you have multiple accounts of the same type',
                        textCapitalization: TextCapitalization.words,
                      ),
                      _buildField(
                        controller: _balanceController,
                        label: widget.initialAccount == null ? 'Initial Balance' : context.t('balance'),
                        prefixText: '${widget.currency} ',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      ..._buildExtraFields(context),
                      const SizedBox(height: 8),
                      _buildAdvancedFields(context),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: Text(context.t('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.submitLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderPicker() {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isBn ? 'অ্যাকাউন্ট প্রোভাইডার / টাইপ' : 'Account Provider / Type',
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _accountTemplates.length,
            itemBuilder: (context, index) {
              final template = _accountTemplates[index];
              final isSelected = _selectedTemplateKey == template.key;
              final color = Color(int.parse(template.colorHex.replaceFirst('#', '0xFF')));
              
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTemplateKey = template.key;
                      _selectedType = template.type;
                      _selectedIcon = template.icon;
                      _selectedColorHex = template.colorHex;
                      if (template.key == 'debit_card') {
                        _cardType = 'Debit Card';
                      } else if (template.key == 'credit_card') {
                        _cardType = 'Credit Card';
                      }
                      
                      // Auto-fill names if they are empty or still matching another template's default name
                      final currentName = _nameController.text.trim();
                      final currentNameBn = _nameBnController.text.trim();
                      final isNameDefault = currentName.isEmpty || 
                          _accountTemplates.any((t) => t.name == currentName || currentName == t.nameBn);
                      final isNameBnDefault = currentNameBn.isEmpty || 
                          _accountTemplates.any((t) => t.nameBn == currentNameBn || currentNameBn == t.name);
                          
                      if (isNameDefault) {
                        _nameController.text = template.name;
                      }
                      if (isNameBnDefault) {
                        _nameBnController.text = template.nameBn;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? color.withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04)),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BrandLogo(
                          name: template.name,
                          icon: template.icon,
                          size: 16,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBn ? template.nameBn.split(' ').first : template.name.split(' ').first,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected 
                              ? color 
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? prefixText,
    String? helperText,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        decoration: _inputDecoration(label, hint: hint, prefixText: prefixText, helperText: helperText),
      ),
    );
  }

  Widget _buildAdvancedFields(BuildContext context) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          isBn ? 'উন্নত অপশন (নাম পরিবর্তন করুন)' : 'Advanced Options (Change Names)',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        children: [
          _buildField(
            controller: _nameController,
            label: context.t('name_english'),
            textCapitalization: TextCapitalization.words,
          ),
          _buildField(
            controller: _nameBnController,
            label: context.t('name_bangla'),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExtraFields(BuildContext context) {
    if (_selectedType == AccountType.mfs) {
      return [
        _buildSectionLabel('Mobile wallet details'),
        _buildField(
          controller: _accountNumberController,
          label: 'Wallet Number',
          hint: '01XXXXXXXXX',
          keyboardType: TextInputType.phone,
        ),
      ];
    }
    if (_selectedType == AccountType.bank) {
      return [
        _buildSectionLabel('Bank details'),
        _buildField(
          controller: _accountNumberController,
          label: 'Account Number',
          keyboardType: TextInputType.number,
        ),
      ];
    }
    if (_selectedType == AccountType.creditCard) {
      return [
        _buildSectionLabel('Card details'),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _cardType,
            decoration: _inputDecoration('Card Type'),
            items: const [
              DropdownMenuItem(value: 'Credit Card', child: Text('Credit Card')),
              DropdownMenuItem(value: 'Debit Card', child: Text('Debit Card')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _cardType = value);
            },
          ),
        ),
        _buildField(
          controller: _accountNumberController,
          label: 'Card Number',
          keyboardType: TextInputType.number,
        ),
        _buildField(
          controller: _cardIssuerController,
          label: 'Bank / Issuer',
          textCapitalization: TextCapitalization.words,
        ),
        _buildField(
          controller: _cardholderController,
          label: 'Cardholder Name',
          textCapitalization: TextCapitalization.words,
        ),
        _buildField(
          controller: _creditLimitController,
          label: 'Credit Limit',
          prefixText: '${widget.currency} ',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        Row(
          children: [
            Expanded(
              child: _buildField(
                controller: _billingDayController,
                label: 'Billing Day',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                controller: _paymentDueDayController,
                label: 'Due Day',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ];
    }
    return const [];
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    String? prefixText,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      helperText: helperText,
      helperMaxLines: 2,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final nameBn = _nameBnController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim());

    if (name.isEmpty || balance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('enter_valid_amount'))),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSubmit(
        _AccountFormData(
          name: name,
          nameBn: nameBn,
          type: _selectedType,
          balance: balance,
          icon: _selectedIcon,
          colorHex: _selectedColorHex,
          nickname: _nullableText(_nicknameController),
          accountNumber: _selectedType == AccountType.cash
              ? null
              : _nullableText(_accountNumberController),
          cardType: _selectedType == AccountType.creditCard ? _cardType : null,
          cardIssuer: _selectedType == AccountType.creditCard
              ? _nullableText(_cardIssuerController)
              : null,
          cardholderName: _selectedType == AccountType.creditCard
              ? _nullableText(_cardholderController)
              : null,
          creditLimit: _selectedType == AccountType.creditCard
              ? double.tryParse(_creditLimitController.text.trim())
              : null,
          billingDay: _selectedType == AccountType.creditCard
              ? int.tryParse(_billingDayController.text.trim())
              : null,
          paymentDueDay: _selectedType == AccountType.creditCard
              ? int.tryParse(_paymentDueDayController.text.trim())
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }
}
