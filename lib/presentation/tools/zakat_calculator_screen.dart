// lib/presentation/tools/zakat_calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/transaction_model.dart';
import '../providers/app_providers.dart';

enum NisabStandard { silver, gold }

class ZakatCalculatorScreen extends ConsumerStatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  ConsumerState<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends ConsumerState<ZakatCalculatorScreen>
    with TickerProviderStateMixin {
  NisabStandard _nisabStandard = NisabStandard.silver;

  // Commodity prices per Bhori (11.664 grams) in BDT
  final _goldPriceCtrl = TextEditingController(text: '145000');
  final _silverPriceCtrl = TextEditingController(text: '2400');

  // Asset controllers
  final _cashBankCtrl = TextEditingController(text: '0');
  final _goldSilverCtrl = TextEditingController(text: '0');
  final _investmentsCtrl = TextEditingController(text: '0');
  final _businessStockCtrl = TextEditingController(text: '0');
  final _receivablesCtrl = TextEditingController(text: '0');

  // Liability controllers
  final _debtsPayableCtrl = TextEditingController(text: '0');
  final _dueBillsCtrl = TextEditingController(text: '0');

  late AnimationController _entryCtrl;
  late AnimationController _resultCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const List<int> _delays = [0, 70, 140, 210, 280];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeAnims = _delays.map((ms) {
      final s = (ms / 900).clamp(0.0, 1.0);
      final e = ((ms + 350) / 900).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(s, e, curve: Curves.easeOut),
      );
    }).toList();

    _slideAnims = _delays.map((ms) {
      final s = (ms / 900).clamp(0.0, 1.0);
      final e = ((ms + 350) / 900).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(s, e, curve: Curves.easeOutCubic),
      ));
    }).toList();

    // Auto-fill on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFillFromApp();
    });
  }

  @override
  void dispose() {
    _goldPriceCtrl.dispose();
    _silverPriceCtrl.dispose();
    _cashBankCtrl.dispose();
    _goldSilverCtrl.dispose();
    _investmentsCtrl.dispose();
    _businessStockCtrl.dispose();
    _receivablesCtrl.dispose();
    _debtsPayableCtrl.dispose();
    _dueBillsCtrl.dispose();
    _entryCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  Widget _anim({required int index, required Widget child}) {
    final i = index.clamp(0, _fadeAnims.length - 1);
    return FadeTransition(
      opacity: _fadeAnims[i],
      child: SlideTransition(position: _slideAnims[i], child: child),
    );
  }

  void _autoFillFromApp() {
    final accounts = ref.read(accountsProvider);
    final assets = ref.read(assetsProvider);
    final investments = ref.read(investmentsProvider);
    final debts = ref.read(debtsProvider);

    // 1. Cash & Bank
    double totalCashBank = 0;
    for (final a in accounts) {
      totalCashBank += a.balance;
    }

    // 2. Gold/Silver and Liquid Assets
    double totalAssets = 0;
    for (final a in assets) {
      totalAssets += a.currentValue;
    }

    // 3. Investments & Stocks
    double totalInvestments = 0;
    for (final i in investments) {
      totalInvestments += i.currentValue;
    }

    // 4. Receivables (Lent money) & Payables (Borrowed debts)
    double totalReceivables = 0;
    double totalPayables = 0;
    for (final d in debts) {
      if (!d.isSettled) {
        final remaining = (d.amount - d.paidAmount).clamp(0, d.amount);
        if (d.type == DebtType.lent) {
          totalReceivables += remaining;
        } else {
          totalPayables += remaining;
        }
      }
    }

    setState(() {
      _cashBankCtrl.text = totalCashBank.round().toString();
      _goldSilverCtrl.text = totalAssets.round().toString();
      _investmentsCtrl.text = totalInvestments.round().toString();
      _receivablesCtrl.text = totalReceivables.round().toString();
      _debtsPayableCtrl.text = totalPayables.round().toString();
    });

    if (!_resultCtrl.isAnimating) {
      _resultCtrl.forward(from: 0.0);
    }
  }

  double _val(TextEditingController ctrl) {
    return double.tryParse(ctrl.text.replaceAll(',', '')) ?? 0.0;
  }

  _ZakatComputation _compute() {
    final goldPricePerBhori = _val(_goldPriceCtrl);
    final silverPricePerBhori = _val(_silverPriceCtrl);

    // Nisab Threshold:
    // Gold: 7.5 Bhori (87.48 grams)
    // Silver: 52.5 Bhori (612.36 grams)
    final double nisabThreshold = _nisabStandard == NisabStandard.gold
        ? (7.5 * goldPricePerBhori)
        : (52.5 * silverPricePerBhori);

    final double grossWealth = _val(_cashBankCtrl) +
        _val(_goldSilverCtrl) +
        _val(_investmentsCtrl) +
        _val(_businessStockCtrl) +
        _val(_receivablesCtrl);

    final double totalLiabilities = _val(_debtsPayableCtrl) + _val(_dueBillsCtrl);
    final double netZakatableWealth = (grossWealth - totalLiabilities).clamp(0.0, double.infinity);

    final bool isEligible = netZakatableWealth >= nisabThreshold && nisabThreshold > 0;
    final double zakatDue = isEligible ? (netZakatableWealth * 0.025) : 0.0;

    return _ZakatComputation(
      grossWealth: grossWealth,
      totalLiabilities: totalLiabilities,
      netZakatableWealth: netZakatableWealth,
      nisabThreshold: nisabThreshold,
      isEligible: isEligible,
      zakatDue: zakatDue,
    );
  }

  String _fmt(double v) {
    return NumberFormat('#,##,###').format(v.round());
  }

  void _recordZakatExpense(double amount) {
    if (amount <= 0) return;

    final dummyTx = TransactionModel(
      id: '',
      amount: (amount * 100).round(),
      type: TransactionType.expense,
      categoryId: 'donation',
      accountId: 'acc_cash',
      date: DateTime.now(),
      note: 'যাকাত পরিশোধ (Zakat Payment)',
    );

    context.push('/add-transaction', extra: dummyTx);
  }

  @override
  Widget build(BuildContext context) {
    const currency = '৳';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final res = _compute();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.t('zakat_calculator_title')),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero Zakat Due Card ──────────────────────────────────
            SliverToBoxAdapter(
              child: _anim(
                index: 1,
                child: _buildHeroCard(context, isDark, primary, currency, res),
              ),
            ),

            // ── Nisab Standard Selector & Market Rates ───────────────
            SliverToBoxAdapter(
              child: _anim(
                index: 2,
                child: _buildNisabCard(context, isDark, primary, currency, res),
              ),
            ),

            // ── Zakatable Assets Section ─────────────────────────────
            SliverToBoxAdapter(
              child: _anim(
                index: 3,
                child: _buildAssetsCard(context, isDark, primary, currency),
              ),
            ),

            // ── Deductible Liabilities Section ───────────────────────
            SliverToBoxAdapter(
              child: _anim(
                index: 4,
                child: _buildLiabilitiesCard(context, isDark, currency),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }



  Widget _buildHeroCard(
    BuildContext context,
    bool isDark,
    Color primary,
    String currency,
    _ZakatComputation res,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF14532D), const Color(0xFF052E16)]
              : [const Color(0xFF15803D), const Color(0xFF166534)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15803D).withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  context.t('total_zakat_due_2_5').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: res.isEligible
                      ? const Color(0xFF22C55E).withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: res.isEligible ? const Color(0xFF86EFAC) : Colors.white30,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      res.isEligible ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      res.isEligible ? context.t('nisab_reached') : context.t('below_nisab'),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$currency${_fmt(res.zakatDue)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),

          // Sub Stats
          Row(
            children: [
              Expanded(
                child: _heroSubStat(
                  label: context.t('net_zakatable_wealth'),
                  value: '$currency${_fmt(res.netZakatableWealth)}',
                  dotColor: Colors.white,
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.15)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _heroSubStat(
                    label: context.t('nisab_threshold'),
                    value: '$currency${_fmt(res.nisabThreshold)}',
                    dotColor: const Color(0xFFFDE047),
                  ),
                ),
              ),
            ],
          ),

          if (res.zakatDue > 0) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _recordZakatExpense(res.zakatDue),
                icon: const Icon(Icons.volunteer_activism_rounded, size: 16),
                label: Text(context.t('record_zakat_payment')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF15803D),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroSubStat({
    required String label,
    required String value,
    required Color dotColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildNisabCard(
    BuildContext context,
    bool isDark,
    Color primary,
    String currency,
    _ZakatComputation res,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                context.t('nisab_benchmark'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChoiceChip(
                    label: Text(context.t('silver_standard')),
                    selected: _nisabStandard == NisabStandard.silver,
                    selectedColor: primary,
                    backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _nisabStandard == NisabStandard.silver
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onSelected: (v) {
                      if (v) setState(() => _nisabStandard = NisabStandard.silver);
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(context.t('gold_standard')),
                    selected: _nisabStandard == NisabStandard.gold,
                    selectedColor: primary,
                    backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _nisabStandard == NisabStandard.gold
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onSelected: (v) {
                      if (v) setState(() => _nisabStandard = NisabStandard.gold);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nisabStandard == NisabStandard.silver
                          ? context.t('silver_price_bhori')
                          : context.t('gold_price_bhori'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nisabStandard == NisabStandard.silver
                          ? _silverPriceCtrl
                          : _goldPriceCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: Container(
                          width: 34,
                          alignment: Alignment.center,
                          child: Text(
                            currency,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primary),
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('nisab_quantity'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _nisabStandard == NisabStandard.silver
                            ? '52.5 Bhori (612.36g)'
                            : '7.5 Bhori (87.48g)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
  }

  Widget _buildAssetsCard(
    BuildContext context,
    bool isDark,
    Color primary,
    String currency,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppColors.success),
              ),
              const SizedBox(width: 10),
              Text(
                context.t('zakatable_assets'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _inputItem(
            context: context,
            controller: _cashBankCtrl,
            label: context.t('cash_and_bank_balances'),
            currency: currency,
            isDark: isDark,
          ),
          _inputItem(
            context: context,
            controller: _goldSilverCtrl,
            label: context.t('gold_silver_holdings'),
            currency: currency,
            isDark: isDark,
          ),
          _inputItem(
            context: context,
            controller: _investmentsCtrl,
            label: context.t('investments_stocks_mutual_funds'),
            currency: currency,
            isDark: isDark,
          ),
          _inputItem(
            context: context,
            controller: _businessStockCtrl,
            label: context.t('business_inventory_goods'),
            currency: currency,
            isDark: isDark,
          ),
          _inputItem(
            context: context,
            controller: _receivablesCtrl,
            label: context.t('money_lent_receivable'),
            currency: currency,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLiabilitiesCard(
    BuildContext context,
    bool isDark,
    String currency,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.money_off_rounded, size: 16, color: AppColors.error),
              ),
              const SizedBox(width: 10),
              Text(
                context.t('deductible_liabilities'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _inputItem(
            context: context,
            controller: _debtsPayableCtrl,
            label: context.t('debts_and_loans_due'),
            currency: currency,
            isDark: isDark,
          ),
          _inputItem(
            context: context,
            controller: _dueBillsCtrl,
            label: context.t('due_utility_living_expenses'),
            currency: currency,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _inputItem({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String currency,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixText: currency,
                  prefixStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZakatComputation {
  final double grossWealth;
  final double totalLiabilities;
  final double netZakatableWealth;
  final double nisabThreshold;
  final bool isEligible;
  final double zakatDue;

  const _ZakatComputation({
    required this.grossWealth,
    required this.totalLiabilities,
    required this.netZakatableWealth,
    required this.nisabThreshold,
    required this.isEligible,
    required this.zakatDue,
  });
}

