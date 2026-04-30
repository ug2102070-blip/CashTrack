// lib/presentation/transactions/add_transaction_form.dart
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../providers/app_providers.dart';

class AddTransactionForm extends ConsumerStatefulWidget {
  const AddTransactionForm({
    super.key,
    this.transactionToEdit,
    this.embedded = false,
  });

  final TransactionModel? transactionToEdit;
  final bool embedded;

  @override
  ConsumerState<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends ConsumerState<AddTransactionForm>
    with TickerProviderStateMixin {
  final _noteController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  String? _selectedAccount;
  bool _isSaving = false;
  bool _isListening = false;
  String _amountStr = '';
  String? _receiptPath;

  late AnimationController _entryCtrl;
  late final Animation<double> _entryFade;

  bool get _isEditMode => widget.transactionToEdit != null;

  double get _amount =>
      _amountStr.isEmpty ? 0 : (double.tryParse(_amountStr) ?? 0);

  Color get _expColor => const Color(0xFFEF4444);
  Color get _incColor => const Color(0xFF10B981);
  Color get _activeColor =>
      _selectedType == TransactionType.expense ? _expColor : _incColor;

  String get _currency {
    final s = ref.read(settingsProvider);
    return (s['currency'] as String?) ?? '৳';
  }

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureDefaultAccounts();
    });

    final t = widget.transactionToEdit;
    if (t != null) {
      _selectedType = t.type;
      _selectedDate = t.date;
      _selectedCategory = t.categoryId;
      _selectedAccount = t.accountId;
      _amountStr = t.amount.toStringAsFixed(0);
      _noteController.text = t.note ?? '';
      _receiptPath = t.receiptUrl;
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    _noteController.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _numTap(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == '⌫') {
        if (_amountStr.isNotEmpty) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        }
      } else if (key == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr = _amountStr.isEmpty ? '0.' : '$_amountStr.';
        }
      } else {
        if (_amountStr == '0') {
          _amountStr = key;
        } else {
          final dotIdx = _amountStr.indexOf('.');
          if (dotIdx != -1 && _amountStr.length - dotIdx > 2) return;
          if (_amountStr.replaceAll('.', '').length < 10) {
            _amountStr += key;
          }
        }
      }
    });
  }

  List<CategoryModel> get _categories {
    final all = ref.watch(categoriesProvider);
    return all.where((c) {
      if (_selectedType == TransactionType.expense) {
        return c.type == CategoryType.expense || c.type == CategoryType.both;
      }
      return c.type == CategoryType.income || c.type == CategoryType.both;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accounts = ref.watch(accountsProvider);
    final cats = _categories;
    final settings = ref.watch(settingsProvider);
    final voiceEnabled = settings['voiceTransactionInput'] == true;
    final receiptEnabled = settings['receiptImageAttachment'] == true;

    _syncDefaultSelections(accounts);

    final body = FadeTransition(
      opacity: _entryFade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _topBar(context, isDark, voiceEnabled, receiptEnabled),
          const SizedBox(height: 12),
          _typeSwitcher(isDark),
          const SizedBox(height: 28),
          _amountArea(isDark),
          const SizedBox(height: 20),
          _fieldsRow(context, cats, accounts, isDark),
          const SizedBox(height: 14),
          _numpadGrid(isDark),
          const SizedBox(height: 14),
          _saveBtn(),
          SizedBox(height: widget.embedded ? 8 : 16),
        ],
      ),
    );

    if (widget.embedded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          physics: const ClampingScrollPhysics(),
          child: body,
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _topBar(
    BuildContext context,
    bool isDark,
    bool voiceEnabled,
    bool receiptEnabled,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          _squareBtn(context, Icons.close_rounded, isDark, _closeScreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditMode
                  ? context.t('edit_transaction')
                  : context.t('new_transaction'),
              style: AppTextStyles.h2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          _squareBtn(
            context,
            Icons.content_paste_rounded,
            isDark,
            _pasteSms,
            tooltip: context.t('paste_sms'),
          ),
          if (voiceEnabled) ...[
            const SizedBox(width: 8),
            _squareBtn(
              context,
              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              isDark,
              _captureVoiceTransaction,
              tooltip: context.t('voice_transaction_input'),
            ),
          ],
          if (receiptEnabled) ...[
            const SizedBox(width: 8),
            _squareBtn(
              context,
              Icons.receipt_long_rounded,
              isDark,
              _pickReceiptImage,
              tooltip: context.t('receipt_photo_option'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _squareBtn(
    BuildContext context,
    IconData icon,
    bool isDark,
    VoidCallback onTap, {
    String? tooltip,
  }) {
    final w = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon,
            size: 20,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: w) : w;
  }

  // ── Type switcher ─────────────────────────────────────────────────────────
  Widget _typeSwitcher(bool isDark) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _typeChip(context.t('expense'), TransactionType.expense, _expColor,
              Icons.arrow_upward_rounded),
          _typeChip(context.t('income'), TransactionType.income, _incColor,
              Icons.arrow_downward_rounded),
        ],
      ),
    );
  }

  Widget _typeChip(
    String label,
    TransactionType type,
    Color color,
    IconData icon,
  ) {
    final sel = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedType == type) return;
          HapticFeedback.lightImpact();
          setState(() {
            _selectedType = type;
            _selectedCategory = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: sel ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: sel
                ? [
                    BoxShadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: sel
                      ? Colors.white
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: sel
                      ? Colors.white
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Amount area ───────────────────────────────────────────────────────────
  Widget _amountArea(bool isDark) {
    final display = _amountStr.isEmpty ? '0' : _amountStr;
    final len = display.length;
    final fz = len > 9
        ? 38.0
        : len > 6
            ? 50.0
            : 64.0;

    return Column(
      children: [
        // Currency
        Text(
          _currency,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _activeColor.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 2),
        // Amount
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 120),
          style: TextStyle(
            fontSize: fz,
            fontWeight: FontWeight.w900,
            letterSpacing: -2.5,
            height: 1.0,
            color: _amountStr.isEmpty
                ? Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.12)
                : _activeColor,
          ),
          child: Text(display),
        ),
        const SizedBox(height: 10),
        // Type badge
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _activeColor.withValues(alpha: isDark ? 0.15 : 0.09),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _selectedType == TransactionType.expense
                ? '↑  ${context.t('expense')}'
                : '↓  ${context.t('income')}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _activeColor,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  // ── Fields row ────────────────────────────────────────────────────────────
  Widget _fieldsRow(
    BuildContext context,
    List<CategoryModel> cats,
    List<AccountModel> accs,
    bool isDark,
  ) {
    final selCat = cats
        .cast<CategoryModel?>()
        .firstWhere((c) => c?.id == _selectedCategory, orElse: () => null);
    final selAcc = accs
        .cast<AccountModel?>()
        .firstWhere((a) => a?.id == _selectedAccount, orElse: () => null);

    return Column(
      children: [
        // Row 1: Category + Account
        Row(
          children: [
            Expanded(
              child: _fieldChip(
                context: context,
                isDark: isDark,
                icon: Icons.category_rounded,
                label: context.t('category'),
                value: selCat != null ? '${selCat.icon}  ${selCat.name}' : null,
                placeholder: context.t('select'),
                filled: selCat != null,
                onTap: () => _pickCategory(cats),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _fieldChip(
                context: context,
                isDark: isDark,
                icon: Icons.account_balance_wallet_rounded,
                label: context.t('account'),
                value: selAcc?.name,
                placeholder: context.t('select'),
                filled: selAcc != null,
                onTap: () => _pickAccount(accs),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 2: Date + Note
        Row(
          children: [
            Expanded(
              child: _fieldChip(
                context: context,
                isDark: isDark,
                icon: Icons.calendar_month_rounded,
                label: context.t('date'),
                value: _dateLabel(context, _selectedDate),
                filled: false,
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _noteChip(context, isDark)),
          ],
        ),
        if (_receiptPath != null) ...[
          const SizedBox(height: 10),
          _receiptPreview(context, isDark),
        ],
      ],
    );
  }

  Widget _receiptPreview(BuildContext context, bool isDark) {
    final file = _receiptPath == null ? null : File(_receiptPath!);
    final hasFile = file != null && file.existsSync();
    return GestureDetector(
      onTap: _pickReceiptImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _activeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: hasFile
                  ? Image.file(file, fit: BoxFit.cover)
                  : Icon(Icons.receipt_long_rounded, color: _activeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt attached',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasFile
                        ? file.path.split(Platform.pathSeparator).last
                        : 'Tap to attach a receipt again',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _receiptPath = null),
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldChip({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    String? value,
    String? placeholder,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: filled
              ? _activeColor.withValues(alpha: isDark ? 0.12 : 0.07)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled
                ? _activeColor.withValues(alpha: 0.28)
                : isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 11,
                    color: filled
                        ? _activeColor
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.38)),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: filled
                        ? _activeColor
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.38),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value ?? placeholder ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: value != null
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteChip(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded,
                  size: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.38)),
              const SizedBox(width: 4),
              Text(
                context.t('note'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.38),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          TextField(
            controller: _noteController,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 2),
              hintText: context.t('add_note'),
              hintStyle: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(BuildContext context, DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return context.t('today');
    }
    final yest = now.subtract(const Duration(days: 1));
    if (d.year == yest.year && d.month == yest.month && d.day == yest.day) {
      return context.t('yesterday');
    }
    return DateFormat('dd MMM yyyy').format(d);
  }

  // ── Picker sheets ─────────────────────────────────────────────────────────
  Future<void> _pickCategory(List<CategoryModel> cats) async {
    if (cats.isEmpty) {
      await _ensureDefaultCategories();
      if (!mounted) return;
      final refreshed = _categories;
      if (refreshed.isEmpty) {
        _msg(context.t('create_expense_category_first'));
        return;
      }
      await _pickCategory(refreshed);
      return;
    }

    _showPickerSheet(
      context: context,
      title: context.t('select_category'),
      children: cats.map((c) {
        final sel = _selectedCategory == c.id;
        return _pickerItem(
          context: context,
          leading: Text(c.icon, style: const TextStyle(fontSize: 22)),
          title: c.name,
          selected: sel,
          onTap: () {
            setState(() => _selectedCategory = c.id);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _pickAccount(List<AccountModel> accs) {
    if (accs.isEmpty) {
      _ensureDefaultAccounts().then((_) {
        if (!mounted) return;
        final refreshed = ref.read(accountsProvider);
        if (refreshed.isEmpty) {
          _msg(context.t('no_accounts'));
          return;
        }
        _pickAccount(refreshed);
      });
      return;
    }

    _showPickerSheet(
      context: context,
      title: context.t('select_account'),
      children: accs.map((a) {
        final sel = _selectedAccount == a.id;
        return _pickerItem(
          context: context,
          leading: Text(a.icon ?? '💳', style: const TextStyle(fontSize: 22)),
          title: a.name,
          selected: sel,
          onTap: () {
            setState(() => _selectedAccount = a.id);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  Future<void> _ensureDefaultCategories() async {
    final notifier = ref.read(categoriesProvider.notifier);
    final existing = ref.read(categoriesProvider);
    final existingIds = existing.map((e) => e.id).toSet();

    for (final category in [
      ...DefaultCategories.expenseCategories,
      ...DefaultCategories.incomeCategories,
    ]) {
      if (existingIds.contains(category.id)) continue;
      await notifier.addCategory(category);
      existingIds.add(category.id);
    }
  }

  Future<void> _ensureDefaultAccounts() async {
    final notifier = ref.read(accountsProvider.notifier);
    final existing = ref.read(accountsProvider);
    final existingIds = existing.map((e) => e.id).toSet();

    for (final account in DefaultAccounts.accounts) {
      if (existingIds.contains(account.id)) continue;
      await notifier.addAccount(account);
      existingIds.add(account.id);
    }
  }

  void _syncDefaultSelections(List<AccountModel> accounts) {
    final hasValidSelection = _selectedAccount != null &&
        accounts.any((account) => account.id == _selectedAccount);
    if (hasValidSelection) {
      return;
    }
    if (accounts.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final fallback = accounts.firstWhere(
        (account) => account.isDefault,
        orElse: () => accounts.first,
      );
      setState(() => _selectedAccount = fallback.id);
    });
  }

  void _showPickerSheet({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(title,
                    style:
                        AppTextStyles.h5.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: children,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickerItem({
    required BuildContext context,
    required Widget leading,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: leading,
      title: Text(
        title,
        style: AppTextStyles.body1.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? primary : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: primary, size: 20)
          : null,
      onTap: onTap,
    );
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (p != null) setState(() => _selectedDate = p);
  }

  // ── Numpad ────────────────────────────────────────────────────────────────
  Widget _numpadGrid(bool isDark) {
    const keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '.',
      '0',
      '⌫',
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 2.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: keys.map((k) => _numBtn(k, isDark)).toList(),
    );
  }

  Widget _numBtn(String key, bool isDark) {
    final isBack = key == '⌫';
    return GestureDetector(
      onTap: () => _numTap(key),
      onLongPress: isBack
          ? () {
              setState(() => _amountStr = '');
              HapticFeedback.mediumImpact();
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: isBack
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04))
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: isBack
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: isBack
              ? Icon(Icons.backspace_outlined,
                  size: 21,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.45))
              : Text(
                  key,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Save button ───────────────────────────────────────────────────────────
  Widget _saveBtn() {
    final ready =
        _amount > 0 && _selectedCategory != null && _selectedAccount != null;

    return GestureDetector(
      onTap: (ready && !_isSaving) ? _submit : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 56,
        decoration: BoxDecoration(
          color: ready
              ? _activeColor
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          boxShadow: ready
              ? [
                  BoxShadow(
                    color: _activeColor.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isEditMode
                          ? Icons.check_circle_rounded
                          : Icons.check_rounded,
                      color: ready ? Colors.white : Colors.white30,
                      size: 21,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      _isEditMode
                          ? context.t('update_transaction')
                          : context.t('save_transaction'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: ready ? Colors.white : Colors.white30,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Logic ─────────────────────────────────────────────────────────────────
  Future<void> _pasteSms() async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.t('paste_sms')),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: InputDecoration(hintText: context.t('paste_sms_hint')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final sms = ctrl.text.trim();
              if (sms.isNotEmpty) _applyParsedSms(sms);
              Navigator.pop(ctx);
            },
            child: Text(context.t('use_sms')),
          ),
        ],
      ),
    );
  }

  void _applyParsedSms(String sms) {
    final lower = sms.toLowerCase();
    final m = RegExp(r'(\d+(?:,\d{3})*(?:\.\d{1,2})?)').firstMatch(sms);
    final isInc = lower.contains('credited') ||
        lower.contains('received') ||
        lower.contains('deposit') ||
        lower.contains('cash in') ||
        lower.contains('salary');
    final isExp = lower.contains('debited') ||
        lower.contains('payment') ||
        lower.contains('purchase') ||
        lower.contains('sent') ||
        lower.contains('cash out') ||
        lower.contains('withdraw');

    setState(() {
      if (m != null) _amountStr = m.group(1)!.replaceAll(',', '');
      if (isInc && !isExp) {
        _selectedType = TransactionType.income;
      } else if (isExp && !isInc) {
        _selectedType = TransactionType.expense;
      }
      if (_noteController.text.trim().isEmpty) _noteController.text = sms;
    });

    final cats = ref.read(categoriesProvider);
    for (final c in cats) {
      final ok = _selectedType == TransactionType.expense
          ? c.type == CategoryType.expense || c.type == CategoryType.both
          : c.type == CategoryType.income || c.type == CategoryType.both;
      if (ok) {
        setState(() => _selectedCategory = c.id);
        break;
      }
    }
    _msg(context.t('sms_parsed_review'));
  }

  Future<void> _captureVoiceTransaction() async {
    // Voice input is not available on web
    if (kIsWeb) {
      _msg('Voice input is only available on mobile devices.');
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final available = await _speechToText.initialize(
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
          _msg('Voice error: ${error.errorMsg}');
        }
      },
    );
    if (!available) {
      _msg('Voice input is not available on this device.');
      return;
    }

    setState(() => _isListening = true);
    _msg('Listening... Speak now');

    await _speechToText.listen(
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 4),
      localeId: 'bn_BD', // Default to Bangla, falls back to device default
      onResult: (result) {
        if (result.finalResult) {
          _applyVoiceText(result.recognizedWords);
        }
      },
    );
  }

  void _applyVoiceText(String transcript) {
    if (!mounted) return;
    setState(() {
      _isListening = false;
      if (_noteController.text.trim().isEmpty) {
        _noteController.text = transcript;
      }
    });

    final normalized = transcript.toLowerCase();

    // Extract amount from spoken text
    final amountMatch = RegExp(r'(\d+(?:\.\d{1,2})?)').firstMatch(transcript);
    if (amountMatch != null) {
      setState(() => _amountStr = amountMatch.group(1)!);
    }

    // Detect transaction type (English + Bangla)
    if (normalized.contains('income') ||
        normalized.contains('received') ||
        normalized.contains('salary') ||
        normalized.contains('আয়') ||
        normalized.contains('বেতন') ||
        normalized.contains('পেয়েছি')) {
      setState(() => _selectedType = TransactionType.income);
    } else if (normalized.contains('expense') ||
        normalized.contains('spent') ||
        normalized.contains('bill') ||
        normalized.contains('খরচ') ||
        normalized.contains('বিল') ||
        normalized.contains('কিনেছি') ||
        normalized.contains('দিয়েছি')) {
      setState(() => _selectedType = TransactionType.expense);
    }

    // Try to match category by name
    final categories = _categories;
    for (final category in categories) {
      if (normalized.contains(category.name.toLowerCase()) ||
          normalized.contains(category.nameBn.toLowerCase())) {
        setState(() => _selectedCategory = category.id);
        break;
      }
    }

    _msg('Voice input added. Please review before saving.');
  }

  Future<void> _pickReceiptImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image == null || !mounted) return;
    setState(() => _receiptPath = image.path);
  }

  Future<void> _submit() async {
    if (_isSaving || _amount <= 0) return;
    if (_selectedCategory == null) {
      _msg(context.t('select_category_prompt'));
      return;
    }
    if (_selectedAccount == null) {
      await _ensureDefaultAccounts();
      if (!mounted) return;
      final refreshed = ref.read(accountsProvider);
      if (refreshed.isNotEmpty) {
        final fallback = refreshed.firstWhere(
          (account) => account.isDefault,
          orElse: () => refreshed.first,
        );
        setState(() => _selectedAccount = fallback.id);
      }
      if (_selectedAccount == null) {
        _msg(context.t('select_account_prompt'));
        return;
      }
    }

    final note = _noteController.text.trim();
    final prev = widget.transactionToEdit;

    final tx = prev != null
        ? prev.copyWith(
            amount: _amount,
            type: _selectedType,
            categoryId: _selectedCategory!,
            accountId: _selectedAccount!,
            date: _selectedDate,
            note: note.isEmpty ? null : note,
            receiptUrl: _receiptPath,
            updatedAt: DateTime.now(),
          )
        : TransactionModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            amount: _amount,
            type: _selectedType,
            categoryId: _selectedCategory!,
            accountId: _selectedAccount!,
            date: _selectedDate,
            note: note.isEmpty ? null : note,
            receiptUrl: _receiptPath,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

    setState(() => _isSaving = true);
    try {
      if (_isEditMode) {
        await ref.read(transactionsProvider.notifier).updateTransaction(tx);
      } else {
        await ref.read(transactionsProvider.notifier).addTransaction(tx);
      }
      await _syncBal(prev, tx);
      await _syncBudget(prev, tx);

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _msg(_isEditMode ? context.t('updated') : context.t('saved'));
      if (widget.embedded) {
        Navigator.of(context).pop();
      } else {
        _closeScreen();
      }
    } catch (e) {
      if (!mounted) return;
      _msg(context.t('error_with_detail', params: {'error': '$e'}));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _closeScreen() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  double _fx(TransactionType t, double a) =>
      t == TransactionType.income ? a : -a;

  Future<void> _syncBal(TransactionModel? prev, TransactionModel curr) async {
    final n = ref.read(accountsProvider.notifier);
    final ce = _fx(curr.type, curr.amount);
    if (prev == null) {
      final a = n.getAccountById(curr.accountId);
      if (a != null) await n.updateBalance(curr.accountId, a.balance + ce);
      return;
    }
    final pe = _fx(prev.type, prev.amount);
    if (prev.accountId == curr.accountId) {
      final a = n.getAccountById(curr.accountId);
      if (a != null) await n.updateBalance(curr.accountId, a.balance + ce - pe);
      return;
    }
    final pa = n.getAccountById(prev.accountId);
    if (pa != null) await n.updateBalance(prev.accountId, pa.balance - pe);
    final ca = n.getAccountById(curr.accountId);
    if (ca != null) await n.updateBalance(curr.accountId, ca.balance + ce);
  }

  Future<void> _syncBudget(
      TransactionModel? prev, TransactionModel curr) async {
    final n = ref.read(budgetsProvider.notifier);
    Future<void> apply(TransactionModel tx, double d) async {
      if (tx.type != TransactionType.expense) return;
      final b = n.getBudgetByCategory(tx.categoryId, tx.date);
      if (b == null) return;
      await n.updateSpent(b.id, (b.spent + d).clamp(0.0, double.infinity));
    }

    if (prev != null) await apply(prev, -prev.amount);
    await apply(curr, curr.amount);
  }
}
