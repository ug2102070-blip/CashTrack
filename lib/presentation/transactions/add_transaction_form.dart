// lib/presentation/transactions/add_transaction_form.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../services/duplicate_detection_service.dart';
import '../providers/app_providers.dart';
import 'calculator_bottom_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widget Entry Point
// ─────────────────────────────────────────────────────────────────────────────

class AddTransactionForm extends ConsumerStatefulWidget {
  const AddTransactionForm({
    super.key,
    this.transactionToEdit,
    this.embedded = false,
  });

  final TransactionModel? transactionToEdit;
  final bool embedded;

  @override
  ConsumerState<AddTransactionForm> createState() =>
      _AddTransactionFormState();
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class _AddTransactionFormState extends ConsumerState<AddTransactionForm>
    with TickerProviderStateMixin {
  // Controllers
  final _noteController = TextEditingController();
  final _noteFocusNode = FocusNode();
  final _imagePicker = ImagePicker();
  final _speech = stt.SpeechToText();

  // Form state
  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  String? _categoryId;
  String? _accountId;
  String _amountStr = '';
  String? _receiptPath;
  bool _isRecurring = false;
  RecurringType? _recurringType;

  // UI state
  bool _isPendingSms = false;
  bool _isSaving = false;
  bool _isListening = false;
  bool _speechInitialized = false;


  // Animations
  late AnimationController _entryCtrl;
  late AnimationController _typeSwitchCtrl;
  late Animation<double> _entryFade;


  // ── Computed helpers ───────────────────────────────────────────────────────

  bool get _isEditMode => widget.transactionToEdit != null;

  double get _amount =>
      _amountStr.isEmpty ? 0 : (double.tryParse(_amountStr) ?? 0);

  // Colors
  Color get _expColor => const Color(0xFFEF4444);
  Color get _incColor => const Color(0xFF10B981);
  Color get _xfrColor => const Color(0xFF6366F1);

  Color get _activeColor {
    switch (_type) {
      case TransactionType.income:
        return _incColor;
      case TransactionType.transfer:
      case TransactionType.lent:
      case TransactionType.borrowed:
        return _xfrColor;
      default:
        return _expColor;
    }
  }

  String get _currency =>
      (ref.read(settingsProvider)['currency'] as String?) ?? '৳';

  List<CategoryModel> get _filteredCategories {
    final all = ref.watch(categoriesProvider);
    return all.where((c) {
      if (_type == TransactionType.expense) {
        return c.type == CategoryType.expense || c.type == CategoryType.both;
      }
      return c.type == CategoryType.income || c.type == CategoryType.both;
    }).toList();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _noteFocusNode.addListener(_onFocusChange);

    // Entry animation
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _typeSwitchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..value = 1;

    // Populate from edit model
    final t = widget.transactionToEdit;
    if (t != null) {
      final repo = ref.read(transactionRepositoryProvider);
      final isAlreadySaved = repo.getAllTransactions().any((item) => item.id == t.id);
      _isPendingSms = !isAlreadySaved;

      _type = t.type;
      _date = t.date;
      _categoryId = t.categoryId;
      _accountId = t.accountId;
      _isRecurring = t.isRecurring;
      _recurringType = t.recurringType;
      _amountStr = t.amount.toStringAsFixed(
          t.amount == t.amount.truncate() ? 0 : 2);
      _noteController.text = t.note ?? '';
      _receiptPath = t.receiptUrl;
    }

    // Apply defaults after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureDefaultAccounts();
    });
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _noteFocusNode.removeListener(_onFocusChange);
    _noteFocusNode.dispose();
    _noteController.dispose();
    _entryCtrl.dispose();
    _typeSwitchCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accounts = ref.watch(accountsProvider);
    final cats = _filteredCategories;
    final settings = ref.watch(settingsProvider);



    final voiceEnabled = settings['voiceTransactionInput'] == true;
    final receiptEnabled = settings['receiptImageAttachment'] == true;

    final body = FadeTransition(
      opacity: _entryFade,
      child: _buildCard(context, isDark, cats, accounts,
          voiceEnabled, receiptEnabled),
    );

    if (widget.embedded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const ClampingScrollPhysics(),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const ClampingScrollPhysics(),
          child: body,
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    bool isDark,
    List<CategoryModel> cats,
    List<AccountModel> accounts,
    bool voiceEnabled,
    bool receiptEnabled,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTopBar(context, isDark, voiceEnabled, receiptEnabled),
            const SizedBox(height: 14),
            _buildTypeSwitcher(isDark),
            const SizedBox(height: 20),
            _buildAmountDisplay(isDark),
            const SizedBox(height: 16),
            _buildFieldsSection(context, cats, accounts, isDark),
            const SizedBox(height: 14),
            _buildNumpad(isDark),
            const SizedBox(height: 16),
            _buildSaveButton(),
            if (widget.embedded) const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Top Bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTopBar(
    BuildContext context,
    bool isDark,
    bool voiceEnabled,
    bool receiptEnabled,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          _iconBtn(
            context,
            Icons.close_rounded,
            isDark,
            _closeScreen,
            isClose: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditMode
                  ? context.t('edit_transaction')
                  : context.t('new_transaction'),
              style: AppTextStyles.h2.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          // Calculator
          _iconBtn(
            context,
            Icons.calculate_rounded,
            isDark,
            _openCalculator,
            tooltip: context.t('calculator'),
          ),
          const SizedBox(width: 8),
          // Paste SMS
          _iconBtn(
            context,
            Icons.content_paste_rounded,
            isDark,
            _openPasteSmsDialog,
            tooltip: context.t('paste_sms'),
          ),
          if (voiceEnabled) ...[
            const SizedBox(width: 8),
            _iconBtn(
              context,
              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              isDark,
              _captureVoiceTransaction,
              tooltip: context.t('voice_transaction_input'),
              isActive: _isListening,
            ),
          ],
          if (receiptEnabled) ...[
            const SizedBox(width: 8),
            _iconBtn(
              context,
              Icons.receipt_long_rounded,
              isDark,
              _pickReceiptImage,
              tooltip: context.t('receipt_photo_option'),
              hasIndicator: _receiptPath != null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconBtn(
    BuildContext context,
    IconData icon,
    bool isDark,
    VoidCallback onTap, {
    String? tooltip,
    bool isClose = false,
    bool isActive = false,
    bool hasIndicator = false,
  }) {
    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? _activeColor.withValues(alpha: 0.15)
                    : isClose
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : _activeColor.withValues(alpha: 0.07))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? _activeColor.withValues(alpha: 0.3)
                      : isClose
                          ? _activeColor.withValues(alpha: 0.12)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03)),
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isActive
                    ? _activeColor
                    : isClose
                        ? _activeColor.withValues(alpha: 0.8)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
              ),
            ),
            if (hasIndicator)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _activeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Type Switcher
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTypeSwitcher(bool isDark) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _typeChip(
            label: context.t('expense'),
            type: TransactionType.expense,
            color: _expColor,
            icon: Icons.arrow_upward_rounded,
          ),
          _typeChip(
            label: context.t('income'),
            type: TransactionType.income,
            color: _incColor,
            icon: Icons.arrow_downward_rounded,
          ),
        ],
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required TransactionType type,
    required Color color,
    required IconData icon,
  }) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_type == type) return;
          HapticFeedback.lightImpact();
          _typeSwitchCtrl.forward(from: 0);
          setState(() {
            _type = type;
            _categoryId = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [color, Color.lerp(color, Colors.black, 0.12)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? Colors.white
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.35),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight:
                      selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: -0.1,
                  color: selected
                      ? Colors.white
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Amount Display
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAmountDisplay(bool isDark) {
    final display = _amountStr.isEmpty ? '0' : _amountStr;
    final len = display.replaceAll('.', '').length;
    final fontSize = len > 9 ? 34.0 : len > 6 ? 46.0 : 58.0;
    final hasAmount = _amountStr.isNotEmpty && _amountStr != '0';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: hasAmount
            ? _activeColor.withValues(alpha: isDark ? 0.07 : 0.04)
            : Colors.transparent,
      ),
      child: Column(
        children: [
          // Currency badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _activeColor.withValues(alpha: isDark ? 0.14 : 0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _currency,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _activeColor.withValues(alpha: 0.75),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Amount value
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 120),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.5,
              height: 1.05,
              color: hasAmount
                  ? _activeColor
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.1),
            ),
            child: Text(
              display,
              textAlign: TextAlign.center,
            ),
          ),

        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fields Section
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFieldsSection(
    BuildContext context,
    List<CategoryModel> cats,
    List<AccountModel> accounts,
    bool isDark,
  ) {
    final selCat = cats.cast<CategoryModel?>().firstWhere(
          (c) => c?.id == _categoryId,
          orElse: () => null,
        );
    final selAcc = accounts.cast<AccountModel?>().firstWhere(
          (a) => a?.id == _accountId,
          orElse: () => null,
        );

    return Column(
      children: [
        // Row 1: Account + Category
        Row(
          children: [
            Expanded(
              child: _fieldTile(
                context: context,
                isDark: isDark,
                icon: Icons.account_balance_wallet_rounded,
                label: context.t('account'),
                value: selAcc != null
                    ? (selAcc.nickname?.isNotEmpty == true
                        ? selAcc.nickname
                        : (selAcc.accountNumber?.isNotEmpty == true
                            ? '${selAcc.name} (${selAcc.accountNumber!.length > 4 ? selAcc.accountNumber!.substring(selAcc.accountNumber!.length - 4) : selAcc.accountNumber})'
                            : selAcc.name))
                    : null,
                placeholder: context.t('select'),
                isFilled: selAcc != null,
                onTap: () => _showAccountSheet(accounts),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _fieldTile(
                context: context,
                isDark: isDark,
                icon: Icons.category_rounded,
                label: context.t('category'),
                value: selCat != null ? '${selCat.icon}  ${selCat.name}' : null,
                placeholder: context.t('select'),
                isFilled: selCat != null,
                onTap: () => _showCategorySheet(cats),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 2: Date + Note
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _fieldTile(
                context: context,
                isDark: isDark,
                icon: Icons.calendar_month_rounded,
                label: context.t('date'),
                value: _dateLabel(_date),
                isFilled: false,
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _noteTile(context, isDark)),
          ],
        ),
        // Receipt preview
        if (_receiptPath != null) ...[
          const SizedBox(height: 10),
          _buildReceiptPreview(context, isDark),
        ],
      ],
    );
  }

  Widget _fieldTile({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    String? value,
    String? placeholder,
    required bool isFilled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: _activeColor.withValues(alpha: 0.06),
        highlightColor: _activeColor.withValues(alpha: 0.03),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isFilled
                ? _activeColor.withValues(alpha: isDark ? 0.10 : 0.05)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF8F9FA)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFilled
                  ? _activeColor.withValues(alpha: 0.22)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: isDark ? 0.08 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isFilled
                      ? _activeColor.withValues(alpha: isDark ? 0.18 : 0.12)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: isFilled
                      ? _activeColor
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: isFilled
                            ? _activeColor.withValues(alpha: 0.75)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value ?? placeholder ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: value != null
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.28),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noteTile(BuildContext context, bool isDark) {
    final hasFocus = _noteFocusNode.hasFocus;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _noteController,
      builder: (context, value, child) {
        final isFilled = value.text.isNotEmpty;
        return GestureDetector(
          onTap: () {
            _noteFocusNode.requestFocus();
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: hasFocus
                  ? _activeColor.withValues(alpha: isDark ? 0.08 : 0.04)
                  : isFilled
                      ? _activeColor.withValues(alpha: isDark ? 0.06 : 0.03)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF8F9FA)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasFocus
                    ? _activeColor.withValues(alpha: 0.45)
                    : isFilled
                        ? _activeColor.withValues(alpha: 0.22)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.05)),
                width: hasFocus ? 1.5 : 1.0,
              ),
              boxShadow: [
                if (hasFocus)
                  BoxShadow(
                    color: _activeColor.withValues(alpha: isDark ? 0.15 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: (hasFocus || isFilled)
                        ? _activeColor.withValues(alpha: isDark ? 0.18 : 0.12)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    size: 14,
                    color: (hasFocus || isFilled)
                        ? _activeColor
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.t('note').toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: (hasFocus || isFilled)
                              ? _activeColor.withValues(alpha: 0.75)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.35),
                        ),
                      ),
                      const SizedBox(height: 1),
                      TextField(
                        controller: _noteController,
                        focusNode: _noteFocusNode,
                        minLines: 1,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 2),
                          hintText: context.t('add_note'),
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFilled) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      _noteController.clear();
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptPreview(BuildContext context, bool isDark) {
    final file = File(_receiptPath!);
    final hasFile = file.existsSync();

    return GestureDetector(
      onTap: _pickReceiptImage,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _activeColor.withValues(alpha: isDark ? 0.07 : 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _activeColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 48,
                height: 48,
                color: _activeColor.withValues(alpha: 0.12),
                child: hasFile
                    ? Image.file(file, fit: BoxFit.cover)
                    : Icon(Icons.receipt_long_rounded,
                        color: _activeColor, size: 22),
              ),
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
                  const SizedBox(height: 2),
                  Text(
                    hasFile
                        ? file.path.split(Platform.pathSeparator).last
                        : 'Tap to re-attach receipt',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _receiptPath = null),
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              tooltip: 'Remove receipt',
            ),
          ],
        ),
      ),
    );
  }



  // ─────────────────────────────────────────────────────────────────────────
  // Numpad
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNumpad(bool isDark) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.8,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: keys.map((k) => _numpadKey(k, isDark)).toList(),
      ),
    );
  }

  Widget _numpadKey(String key, bool isDark) {
    final isBack = key == '⌫';
    final isDot = key == '.';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumpadTap(key),
        onLongPress: isBack
            ? () {
                HapticFeedback.mediumImpact();
                setState(() => _amountStr = '');
              }
            : null,
        borderRadius: BorderRadius.circular(14),
        splashColor: _activeColor.withValues(alpha: 0.08),
        highlightColor: _activeColor.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          decoration: BoxDecoration(
            color: isBack
                ? _activeColor.withValues(alpha: isDark ? 0.1 : 0.07)
                : isDot
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03))
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: (!isBack && !isDot)
                ? [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.1 : 0.03),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isBack
                ? Icon(
                    Icons.backspace_rounded,
                    size: 23,
                    color: _activeColor.withValues(alpha: 0.75),
                  )
                : Text(
                    key,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: isDot
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _onNumpadTap(String key) {
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
        // Replace leading zero
        if (_amountStr == '0') {
          _amountStr = key;
        } else {
          // Limit decimal places to 2
          final dotIdx = _amountStr.indexOf('.');
          if (dotIdx != -1 && _amountStr.length - dotIdx > 2) return;
          // Limit total digits to 10
          if (_amountStr.replaceAll('.', '').length >= 10) return;
          _amountStr += key;
        }
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Save Button
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    final ready =
        _amount > 0 && _categoryId != null && _accountId != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (ready && !_isSaving) ? _submit : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: 56,
          decoration: BoxDecoration(
            gradient: ready
                ? LinearGradient(
                    colors: [
                      _activeColor,
                      Color.lerp(_activeColor, Colors.black, 0.18)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: ready
                ? null
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            boxShadow: ready
                ? [
                    BoxShadow(
                      color: _activeColor.withValues(alpha: 0.4),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: _activeColor.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
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
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isEditMode
                            ? Icons.check_circle_rounded
                            : Icons.check_rounded,
                        size: 20,
                        color: ready
                            ? Colors.white
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isEditMode
                            ? context.t('update_transaction')
                            : context.t('save_transaction'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: ready
                              ? Colors.white
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Picker Sheets
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _showCategorySheet(List<CategoryModel> cats) async {
    if (cats.isEmpty) {
      await _ensureDefaultCategories();
      if (!mounted) return;
      final refreshed = _filteredCategories;
      if (refreshed.isEmpty) {
        _showSnack(context.t('create_expense_category_first'));
        return;
      }
      await _showCategorySheet(refreshed);
      return;
    }

    final settings = ref.read(settingsProvider);
    final pinnedIds = (settings['pinnedCategories'] as List<dynamic>?)
            ?.cast<String>()
            .toSet() ??
        <String>{};
    final localPinned = pinnedIds.toSet();

    _showPickerSheet(
      title: context.t('select_category'),
      builder: (sheetSetState) {
        final sorted = [...cats]..sort((a, b) {
            final aP = localPinned.contains(a.id);
            final bP = localPinned.contains(b.id);
            if (aP != bP) return aP ? -1 : 1;
            return a.name.compareTo(b.name);
          });
        return sorted
            .map(
              (c) => _pickerListTile(
                context: context,
                leading: Text(c.icon,
                    style: const TextStyle(fontSize: 24)),
                title: c.name,
                subtitle: c.nameBn.isNotEmpty ? c.nameBn : null,
                selected: _categoryId == c.id,
                onTap: () {
                  setState(() => _categoryId = c.id);
                  Navigator.pop(context);
                },
                trailing: IconButton(
                  icon: Icon(
                    localPinned.contains(c.id)
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    size: 18,
                    color: localPinned.contains(c.id)
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                  ),
                  splashRadius: 20,
                  tooltip: localPinned.contains(c.id)
                      ? context.t('unpin_category')
                      : context.t('pin_category'),
                  onPressed: () async {
                    if (localPinned.contains(c.id)) {
                      localPinned.remove(c.id);
                    } else {
                      localPinned.add(c.id);
                    }
                    await ref
                        .read(settingsProvider.notifier)
                        .updatePinnedCategories(localPinned.toList());
                    sheetSetState(() {});
                  },
                ),
              ),
            )
            .toList();
      },
    );
  }

  void _showAccountSheet(List<AccountModel> accs) {
    if (accs.isEmpty) {
      _ensureDefaultAccounts().then((_) {
        if (!mounted) return;
        final refreshed = ref.read(accountsProvider);
        if (refreshed.isEmpty) {
          _showSnack(context.t('no_accounts'));
          return;
        }
        _showAccountSheet(refreshed);
      });
      return;
    }

    final settings = ref.read(settingsProvider);
    final pinnedIds = (settings['pinnedAccounts'] as List<dynamic>?)
            ?.cast<String>()
            .toSet() ??
        <String>{};
    final localPinned = pinnedIds.toSet();

    final sorted = [...accs]..sort((a, b) {
        final aP = localPinned.contains(a.id);
        final bP = localPinned.contains(b.id);
        if (aP != bP) return aP ? -1 : 1;
        return a.name.compareTo(b.name);
      });

    _showPickerSheet(
      title: context.t('select_account'),
      builder: (sheetSetState) => sorted
          .map(
            (a) => _pickerListTile(
              context: context,
              leading: Text(a.icon ?? '💳',
                  style: const TextStyle(fontSize: 24)),
              title: a.nickname?.isNotEmpty == true ? a.nickname! : a.name,
              subtitle: a.nickname?.isNotEmpty == true
                  ? '${a.name}${a.accountNumber?.isNotEmpty == true ? " • ${a.accountNumber}" : ""}'
                  : (a.accountNumber?.isNotEmpty == true ? a.accountNumber : null),
              selected: _accountId == a.id,
              onTap: () {
                setState(() => _accountId = a.id);
                Navigator.pop(context);
              },
              trailing: IconButton(
                icon: Icon(
                  localPinned.contains(a.id)
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  size: 18,
                  color: localPinned.contains(a.id)
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                ),
                splashRadius: 20,
                tooltip: localPinned.contains(a.id)
                    ? context.t('unpin_account')
                    : context.t('pin_account'),
                onPressed: () async {
                  if (localPinned.contains(a.id)) {
                    localPinned.remove(a.id);
                  } else {
                    localPinned.add(a.id);
                  }
                  await ref
                      .read(settingsProvider.notifier)
                      .updatePinnedAccounts(localPinned.toList());
                  if (!mounted) return;
                  Navigator.pop(context);
                  _showAccountSheet(accs);
                },
              ),
            ),
          )
          .toList(),
    );
  }

  void _showPickerSheet({
    required String title,
    required List<Widget> Function(StateSetter) builder,
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: AppTextStyles.h5
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StatefulBuilder(
                    builder: (_, ss) => ListView(
                      padding: EdgeInsets.zero,
                      children: builder(ss),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickerListTile({
    required BuildContext context,
    required Widget leading,
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: leading,
      title: Text(
        title,
        style: AppTextStyles.body1.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color:
              selected ? primary : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null && subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            )
          : null,
      trailing: trailing != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      color: primary, size: 20),
                trailing,
              ],
            )
          : (selected
              ? Icon(Icons.check_circle_rounded,
                  color: primary, size: 20)
              : null),
      onTap: onTap,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Date Picker
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: _activeColor,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return context.t('today');
    }
    final yest = now.subtract(const Duration(days: 1));
    if (d.year == yest.year &&
        d.month == yest.month &&
        d.day == yest.day) {
      return context.t('yesterday');
    }
    return DateFormat('dd MMM yyyy').format(d);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Calculator
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _openCalculator() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CalculatorBottomSheet(initialValue: _amountStr),
    );
    if (result is String && result.isNotEmpty && mounted) {
      setState(() => _amountStr = result);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Paste SMS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _openPasteSmsDialog() async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22)),
        title: Text(context.t('paste_sms'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            hintText: context.t('paste_sms_hint'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final sms = ctrl.text.trim();
              if (sms.isNotEmpty) _parseSmsText(sms);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _activeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.t('use_sms')),
          ),
        ],
      ),
    );
  }

  void _parseSmsText(String sms) {
    final lower = sms.toLowerCase();
    final amountMatch =
        RegExp(r'(\d+(?:,\d{3})*(?:\.\d{1,2})?)').firstMatch(sms);

    final isIncome = lower.contains('credited') ||
        lower.contains('received') ||
        lower.contains('deposit') ||
        lower.contains('cash in') ||
        lower.contains('salary');
    final isExpense = lower.contains('debited') ||
        lower.contains('payment') ||
        lower.contains('purchase') ||
        lower.contains('sent') ||
        lower.contains('cash out') ||
        lower.contains('withdraw');

    setState(() {
      if (amountMatch != null) {
        _amountStr = amountMatch.group(1)!.replaceAll(',', '');
      }
      if (isIncome && !isExpense) {
        _type = TransactionType.income;
        _categoryId = null;
      } else if (isExpense && !isIncome) {
        _type = TransactionType.expense;
        _categoryId = null;
      }
      if (_noteController.text.trim().isEmpty) {
        _noteController.text = sms;
      }
    });

    // Auto-select first matching category
    final cats = _filteredCategories;
    if (cats.isNotEmpty && _categoryId == null) {
      setState(() => _categoryId = cats.first.id);
    }

    _showSnack(context.t('sms_parsed_review'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Voice Input
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _captureVoiceTransaction() async {
    if (kIsWeb) {
      _showSnack('Voice input is only available on mobile devices.');
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    // Request mic permission
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _showSnack('Microphone permission is required for voice input.');
      return;
    }

    // Initialize speech engine once
    if (!_speechInitialized) {
      bool available = false;
      try {
        available = await _speech.initialize(
          onError: (err) {
            if (mounted) {
              setState(() => _isListening = false);
              _showSnack('Voice error: ${err.errorMsg}');
            }
          },
          onStatus: (status) {
            if (mounted &&
                (status == 'done' || status == 'notListening')) {
              setState(() => _isListening = false);
            }
          },
        );
      } catch (_) {
        if (mounted) _showVoiceNotAvailableDialog();
        return;
      }
      if (!available) {
        if (mounted) _showVoiceNotAvailableDialog();
        return;
      }
      _speechInitialized = true;
    }

    setState(() => _isListening = true);
    _showSnack('Listening… Speak now');

    final locales = await _speech.locales();
    final hasBangla = locales.any((l) => l.localeId.startsWith('bn'));

    await _speech.listen(
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 4),
      localeId: hasBangla ? 'bn_BD' : null,
      onResult: (result) {
        if (result.finalResult) {
          _applyVoiceText(result.recognizedWords);
        }
      },
    );
  }

  void _applyVoiceText(String transcript) {
    if (!mounted) return;
    setState(() => _isListening = false);

    final normalized = transcript.toLowerCase();

    // Extract amount
    final amountMatch =
        RegExp(r'(\d+(?:\.\d{1,2})?)').firstMatch(transcript);
    if (amountMatch != null) {
      setState(() => _amountStr = amountMatch.group(1)!);
    }

    // Detect type
    if (normalized.contains('income') ||
        normalized.contains('received') ||
        normalized.contains('salary') ||
        normalized.contains('আয়') ||
        normalized.contains('বেতন') ||
        normalized.contains('পেয়েছি')) {
      setState(() {
        _type = TransactionType.income;
        _categoryId = null;
      });
    } else if (normalized.contains('expense') ||
        normalized.contains('spent') ||
        normalized.contains('bill') ||
        normalized.contains('খরচ') ||
        normalized.contains('বিল') ||
        normalized.contains('কিনেছি') ||
        normalized.contains('দিয়েছি')) {
      setState(() {
        _type = TransactionType.expense;
        _categoryId = null;
      });
    }

    // Match category by name
    for (final cat in _filteredCategories) {
      if (normalized.contains(cat.name.toLowerCase()) ||
          normalized.contains(cat.nameBn.toLowerCase())) {
        setState(() => _categoryId = cat.id);
        break;
      }
    }

    // Set note
    if (_noteController.text.trim().isEmpty) {
      _noteController.text = transcript;
    }

    _showSnack('Voice input added. Please review before saving.');
  }

  void _showVoiceNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Voice Input Not Available'),
        content: const Text(
          'Speech recognition is not available on this device.\n\n'
          'To enable it, install Google app and Google Speech Services '
          'from the Play Store, then try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Receipt Image
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _pickReceiptImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _activeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt_rounded,
                      color: _activeColor, size: 20),
                ),
                title: Text(context.t('take_photo'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _activeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library_rounded,
                      color: _activeColor, size: 20),
                ),
                title: Text(context.t('choose_from_gallery'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null && mounted) {
      setState(() => _receiptPath = image.path);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Submit Logic
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_isSaving || _amount <= 0) return;

    if (_categoryId == null) {
      _showSnack(context.t('select_category_prompt'));
      return;
    }

    if (_accountId == null) {
      _showSnack(context.t('select_account_prompt'));
      return;
    }

    final note = _noteController.text.trim();
    final prev = _isPendingSms ? null : widget.transactionToEdit;
    final now = DateTime.now();

    final tx = widget.transactionToEdit != null
        ? widget.transactionToEdit!.copyWith(
            amount: _amount,
            type: _type,
            categoryId: _categoryId!,
            accountId: _accountId!,
            date: _date,
            note: note.isEmpty ? null : note,
            receiptUrl: _receiptPath,
            isRecurring: _isRecurring,
            recurringType: _isRecurring ? _recurringType : null,
            updatedAt: now,
          )
        : TransactionModel(
            id: now.millisecondsSinceEpoch.toString(),
            amount: _amount,
            type: _type,
            categoryId: _categoryId!,
            accountId: _accountId!,
            date: _date,
            note: note.isEmpty ? null : note,
            receiptUrl: _receiptPath,
            isRecurring: _isRecurring,
            recurringType: _isRecurring ? _recurringType : null,
            createdAt: now,
            updatedAt: now,
          );

    setState(() => _isSaving = true);
    try {
      if (_isEditMode && !_isPendingSms) {
        await ref.read(transactionsProvider.notifier).updateTransaction(tx);
      } else {
        // Duplicate check
        final dupService = DuplicateDetectionService();
        final existing = ref.read(transactionsProvider);
        final dupPair = dupService.checkForDuplicate(tx, existing);

        if (dupPair != null &&
            dupPair.similarityScore >=
                DuplicateDetectionService.highConfidenceThreshold) {
          if (!mounted) return;
          final shouldSave = await _showDuplicateWarning(dupPair);
          if (shouldSave != true) {
            setState(() => _isSaving = false);
            return;
          }
        }

        await ref.read(transactionsProvider.notifier).addTransaction(tx);
      }

      await _syncBalance(prev, tx);
      await _syncBudget(prev, tx);

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _showSnack(
          _isEditMode ? context.t('updated') : context.t('saved'));

      if (widget.embedded) {
        Navigator.of(context).pop();
      } else {
        _closeScreen();
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(
          context.t('error_with_detail', params: {'error': '$e'}));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Duplicate Warning Dialog
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool?> _showDuplicateWarning(DuplicatePair dupPair) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final orig = dupPair.original;
    final score = (dupPair.similarityScore * 100).toStringAsFixed(0);
    final dateStr = DateFormat('dd MMM, hh:mm a').format(orig.date);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 26),
        ),
        title: Text(
          isBn ? 'ডুপ্লিকেট লেনদেন?' : 'Duplicate Transaction?',
          style:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBn
                  ? 'একটি একই রকম লেনদেন ইতোমধ্যে আছে:'
                  : 'A similar transaction already exists:',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(ctx)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_currency${orig.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$score% ${isBn ? 'মিল' : 'match'}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(ctx)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isBn ? 'বাতিল' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isBn ? 'তবুও সেভ করুন' : 'Save Anyway'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Balance & Budget Sync
  // ─────────────────────────────────────────────────────────────────────────

  double _signedAmount(TransactionType type, double amount) =>
      type == TransactionType.income ? amount : -amount;

  Future<void> _syncBalance(
      TransactionModel? prev, TransactionModel curr) async {
    final notifier = ref.read(accountsProvider.notifier);
    final ce = _signedAmount(curr.type, curr.amount);

    if (prev == null) {
      final acc = notifier.getAccountById(curr.accountId);
      if (acc != null) {
        await notifier.updateBalance(curr.accountId, acc.balance + ce);
      }
      return;
    }

    final pe = _signedAmount(prev.type, prev.amount);
    if (prev.accountId == curr.accountId) {
      final acc = notifier.getAccountById(curr.accountId);
      if (acc != null) {
        await notifier.updateBalance(
            curr.accountId, acc.balance + ce - pe);
      }
    } else {
      // Different accounts
      final prevAcc = notifier.getAccountById(prev.accountId);
      if (prevAcc != null) {
        await notifier.updateBalance(prev.accountId, prevAcc.balance - pe);
      }
      final currAcc = notifier.getAccountById(curr.accountId);
      if (currAcc != null) {
        await notifier.updateBalance(curr.accountId, currAcc.balance + ce);
      }
    }
  }

  Future<void> _syncBudget(
      TransactionModel? prev, TransactionModel curr) async {
    final notifier = ref.read(budgetsProvider.notifier);

    Future<void> apply(TransactionModel tx, double delta) async {
      if (tx.type != TransactionType.expense) return;
      final budget =
          notifier.getBudgetByCategory(tx.categoryId, tx.date);
      if (budget == null) return;
      await notifier.updateSpent(
          budget.id, (budget.spent + delta).clamp(0.0, double.infinity));
    }

    if (prev != null) await apply(prev, -prev.amount);
    await apply(curr, curr.amount);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Default Data Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _ensureDefaultCategories() async {
    final notifier = ref.read(categoriesProvider.notifier);
    final existingIds =
        ref.read(categoriesProvider).map((e) => e.id).toSet();

    for (final cat in [
      ...DefaultCategories.expenseCategories,
      ...DefaultCategories.incomeCategories,
    ]) {
      if (existingIds.contains(cat.id)) continue;
      await notifier.addCategory(cat);
      existingIds.add(cat.id);
    }
  }

  Future<void> _ensureDefaultAccounts() async {
    final notifier = ref.read(accountsProvider.notifier);
    final existing = ref.read(accountsProvider);
    if (existing.isNotEmpty) return;

    for (final acc in DefaultAccounts.accounts) {
      await notifier.addAccount(acc);
    }
  }



  // ─────────────────────────────────────────────────────────────────────────
  // Utility Helpers
  // ─────────────────────────────────────────────────────────────────────────



  void _closeScreen() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
  }
}
