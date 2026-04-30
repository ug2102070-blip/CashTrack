// lib/presentation/ai_assistant/ai_assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../presentation/providers/app_providers.dart';
import '../../services/ai_service.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final AiService _aiService = AiService();

  final List<_Msg> _msgs = [];
  bool _loading = false;
  bool _inputFocused = false;

  late AnimationController _headerCtrl;
  late AnimationController _typingCtrl;

  List<String> _suggestions(BuildContext context) => [
        context.t('ai_suggestion_spending'),
        context.t('ai_suggestion_top_category'),
        context.t('ai_suggestion_saving_tips'),
        context.t('ai_suggestion_over_budget'),
        context.t('ai_suggestion_income_vs_expense'),
      ];

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _typingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _focusNode.addListener(() {
      setState(() => _inputFocused = _focusNode.hasFocus);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _addWelcome());
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _headerCtrl.dispose();
    _typingCtrl.dispose();
    super.dispose();
  }

  // â”€â”€ Welcome â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _addWelcome() async {
    final snapshot = _monthSnapshot();
    _addBot(snapshot);

    if (!_aiService.isConfigured) {
      _addBot(
        context.t('ai_key_not_configured'),
        isSystem: true,
      );
    } else {
      _addBot(context.t('ai_welcome'));
    }
    setState(() {});
  }

  void _addBot(String text, {bool isSystem = false}) {
    _msgs.add(_Msg(text: text, isUser: false, isSystem: isSystem));
  }

  String _monthSnapshot() {
    final settings = ref.read(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '৳';
    final now = DateTime.now();
    final txs = ref
        .read(transactionsProvider)
        .where((t) =>
            !t.isDeleted &&
            t.date.month == now.month &&
            t.date.year == now.year)
        .toList();

    if (txs.isEmpty) {
      return context.t('ai_no_tx_month');
    }

    final income = txs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = txs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount);
    final net = income - expense;
    final sign = net >= 0 ? '+' : '';

    return context.t('ai_month_snapshot', params: {
      'month': DateFormat('MMMM').format(now),
      'income': '$currency${_fmt(income)}',
      'expense': '$currency${_fmt(expense)}',
      'net': '$sign$currency${_fmt(net.abs())}',
    });
  }

  // â”€â”€ Send â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _send([String? override]) async {
    final text = (override ?? _inputCtrl.text).trim();
    if (text.isEmpty || _loading) return;

    _inputCtrl.clear();
    HapticFeedback.lightImpact();

    setState(() {
      _msgs.add(_Msg(text: text, isUser: true));
      _loading = true;
    });
    _scrollToBottom();

    final response = await _aiService.getResponse(
      text,
      financialContext: _buildContext(),
      l10n: AppL10n.of(context),
    );

    if (!mounted) return;
    setState(() {
      _msgs.add(_Msg(text: response, isUser: false));
      _loading = false;
    });
    _scrollToBottom(delay: 100);
  }

  void _scrollToBottom({int delay = 0}) {
    Future.delayed(Duration(milliseconds: delay), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildHeader(context, primary, isDark),

            // â”€â”€ Insight chip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (!_inputFocused) _buildInsightChip(context, isDark),

            // â”€â”€ Messages â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: _msgs.isEmpty
                  ? _buildEmptyState(context, isDark)
                  : _buildMessageList(context, isDark),
            ),

            // â”€â”€ Suggestions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (!_inputFocused && !_loading)
              _buildSuggestions(context, primary, isDark),

            // â”€â”€ Input â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildInput(context, primary, isDark),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeader(BuildContext context, Color primary, bool isDark) {
    return FadeTransition(
      opacity: _headerCtrl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            // Back
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(13),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, Color.lerp(primary, Colors.purple, 0.45)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('ai_assistant'),
                    style: AppTextStyles.h5.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        _aiService.isConfigured
                            ? context.t('online')
                            : context.t('not_configured'),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: _aiService.isConfigured
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Clear
            InkWell(
              onTap: () {
                setState(() => _msgs.clear());
                _addWelcome();
              },
              borderRadius: BorderRadius.circular(13),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 19,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Insight chip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildInsightChip(BuildContext context, bool isDark) {
    final tip = _dailyTip();
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.lightbulb_rounded, color: primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('smart_insight'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tip,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _send(tip),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.t('ask'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Message list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildMessageList(BuildContext context, bool isDark) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      physics: const BouncingScrollPhysics(),
      itemCount: _msgs.length + (_loading ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _msgs.length) return _buildTyping(context, isDark);
        return _buildBubble(context, _msgs[i], isDark);
      },
    );
  }

  Widget _buildBubble(BuildContext context, _Msg msg, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;

    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  msg.text,
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_rounded, color: primary, size: 16),
            ),
          ],
        ),
      );
    }

    // Bot bubble
    final bgColor = msg.isSystem
        ? AppColors.warning.withValues(alpha: isDark ? 0.12 : 0.08)
        : Theme.of(context).colorScheme.surface;
    final borderColor = msg.isSystem
        ? AppColors.warning.withValues(alpha: 0.3)
        : isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.05);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, Color.lerp(primary, Colors.purple, 0.45)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Typing indicator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTyping(BuildContext context, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, Color.lerp(primary, Colors.purple, 0.45)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 15),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: _TypingDots(ctrl: _typingCtrl, color: primary),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary.withValues(alpha: 0.15),
                  Color.lerp(primary, Colors.purple, 0.4)!
                      .withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 34,
              color: primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.t('ai_empty_title'),
            style: AppTextStyles.h5.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.t('ai_empty_subtitle'),
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Suggestions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildSuggestions(BuildContext context, Color primary, bool isDark) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        itemCount: _suggestions(context).length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = _suggestions(context)[i];
          return GestureDetector(
            onTap: () => _send(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Text(
                s,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // â”€â”€ Input bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildInput(BuildContext context, Color primary, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _inputFocused
                      ? primary.withValues(alpha: 0.5)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.07),
                  width: _inputFocused ? 1.5 : 1,
                ),
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: context.t('ai_input_hint'),
                  hintStyle: AppTextStyles.body2.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.35),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _loading ? null : _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _loading
                    ? null
                    : LinearGradient(
                        colors: [
                          primary,
                          Color.lerp(primary, Colors.purple, 0.4)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: _loading
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.07))
                    : null,
                shape: BoxShape.circle,
                boxShadow: _loading
                    ? null
                    : [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: _loading
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: primary,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Context builder â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String _buildContext() {
    final settings = ref.read(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '৳';
    final language = (settings['language'] as String?) ?? 'en';
    final l10n =
        AppL10n(language == 'bn' ? const Locale('bn', 'BD') : const Locale('en'));
    final now = DateTime.now();

    final txs =
        ref.read(transactionsProvider).where((t) => !t.isDeleted).toList();
    final accounts = ref.read(accountsProvider);
    final cats =
        ref.read(categoriesProvider).where((c) => !c.isDeleted).toList();
    final budgets = ref.read(budgetsProvider);

    final monthTx = txs
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();

    final income = monthTx
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = monthTx
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount);

    final mBudgets = budgets
        .where((b) => b.month.year == now.year && b.month.month == now.month)
        .toList();
    final totalBudget = mBudgets.fold<double>(0, (s, b) => s + b.amount);
    final totalSpent = mBudgets.fold<double>(0, (s, b) => s + b.spent);
    final totalBal = accounts.fold<double>(0, (s, a) => s + a.balance);

    final topExpCat =
        _topCat(monthTx, TransactionType.expense, cats, currency, l10n);
    final topIncCat =
        _topCat(monthTx, TransactionType.income, cats, currency, l10n);

    final recent = [...txs]..sort((a, b) => b.date.compareTo(a.date));
    final recentLines = recent.take(5).map((t) {
      final catName = _catName(t.categoryId, cats);
      final typeLabel =
          t.type == TransactionType.income ? l10n.t('income') : l10n.t('expense');
      return l10n.t('ai_context_tx_line', params: {
        'type': typeLabel,
        'amount': '$currency${t.amount.toStringAsFixed(0)}',
        'category': catName,
        'date': DateFormat('yyyy-MM-dd').format(t.date),
      });
    }).join('\n');

    return '''
${l10n.t('ai_context_currency', params: {'currency': currency})}
${l10n.t('ai_context_today', params: {'date': DateFormat('yyyy-MM-dd').format(now)})}

${l10n.t('ai_context_this_month', params: {'month': DateFormat('MMMM yyyy').format(now)})}
${l10n.t('ai_context_income_line', params: {'amount': '$currency${income.toStringAsFixed(2)}'})}
${l10n.t('ai_context_expense_line', params: {'amount': '$currency${expense.toStringAsFixed(2)}'})}
${l10n.t('ai_context_net_line', params: {'amount': '$currency${(income - expense).toStringAsFixed(2)}'})}
${l10n.t('ai_context_top_expense_line', params: {'value': topExpCat})}
${l10n.t('ai_context_top_income_line', params: {'value': topIncCat})}

${l10n.t('ai_context_accounts')}
${l10n.t('ai_context_balance_line', params: {'amount': '$currency${totalBal.toStringAsFixed(2)}', 'count': accounts.length.toString()})}

${l10n.t('ai_context_budgets')}
${l10n.t('ai_context_budget_set_line', params: {'amount': '$currency${totalBudget.toStringAsFixed(2)}'})}
${l10n.t('ai_context_budget_spent_line', params: {'amount': '$currency${totalSpent.toStringAsFixed(2)}'})}
${l10n.t('ai_context_budget_remaining_line', params: {'amount': '$currency${(totalBudget - totalSpent).toStringAsFixed(2)}'})}

${l10n.t('ai_context_recent')}
${recentLines.isEmpty ? '- ${l10n.t('none')}' : recentLines}
''';
  }

  String _topCat(
    List<TransactionModel> txs,
    TransactionType type,
    List<CategoryModel> cats,
    String currency,
    AppL10n l10n,
  ) {
    final map = <String, double>{};
    for (final t in txs.where((t) => t.type == type)) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    if (map.isEmpty) return l10n.t('none');
    final top = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return '${_catName(top.first.key, cats)} ($currency${top.first.value.toStringAsFixed(0)})';
  }

  String _catName(String id, List<CategoryModel> cats) {
    for (final c in cats) {
      if (c.id == id) return c.name;
    }
    return id;
  }

  String _dailyTip() {
    final settings = ref.read(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '৳';
    final now = DateTime.now();

    final txs = ref
        .read(transactionsProvider)
        .where((t) =>
            !t.isDeleted &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .toList();

    final expense = txs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount);

    final budgets = ref
        .read(budgetsProvider)
        .where((b) => b.month.year == now.year && b.month.month == now.month);
    final totalBudget = budgets.fold<double>(0, (s, b) => s + b.amount);

    if (expense == 0) return context.t('ai_tip_no_expense');
    if (totalBudget > 0 && expense > totalBudget) {
      return context.t('ai_tip_over_budget', params: {
        'amount': '$currency${_fmt(expense - totalBudget)}',
      });
    }
    if (totalBudget > 0) {
      return context.t('ai_tip_budget_used', params: {
        'percent':
            _fmt((expense / totalBudget * 100).clamp(0, 100)),
        'remaining': '$currency${_fmt(totalBudget - expense)}',
      });
    }
    return context.t('ai_tip_spent_so_far', params: {
      'amount': '$currency${_fmt(expense)}',
    });
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// â”€â”€ Typing dots widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _TypingDots extends StatelessWidget {
  const _TypingDots({required this.ctrl, required this.color});
  final AnimationController ctrl;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (ctrl.value - i * 0.15).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * (1 - (t * 2 - 1).abs());
            return Container(
              width: 7,
              height: 7,
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3 + 0.7 * scale),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

// â”€â”€ Message model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _Msg {
  const _Msg({
    required this.text,
    required this.isUser,
    this.isSystem = false,
  });
  final String text;
  final bool isUser;
  final bool isSystem;
}



