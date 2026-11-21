// lib/presentation/tools/dps_calculator_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/investment_model.dart';
import '../providers/app_providers.dart';

class DpsCalculatorScreen extends ConsumerStatefulWidget {
  const DpsCalculatorScreen({super.key});

  @override
  ConsumerState<DpsCalculatorScreen> createState() => _DpsCalculatorScreenState();
}

class _DpsCalculatorScreenState extends ConsumerState<DpsCalculatorScreen>
    with TickerProviderStateMixin {
  final _depositController = TextEditingController(text: '5000');
  final _interestController = TextEditingController(text: '8.5');

  int _selectedYears = 5;
  bool _hasTin = true; // 5% AIT with TIN/return, 10% without

  double _monthlyDeposit = 5000;
  double _annualRate = 8.5;

  late AnimationController _entryCtrl;
  late AnimationController _resultCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const List<int> _delays = [0, 70, 140, 210, 280, 350, 420];

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
  }

  @override
  void dispose() {
    _depositController.dispose();
    _interestController.dispose();
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

  void _recalculate() {
    final deposit = double.tryParse(_depositController.text.replaceAll(',', '')) ?? 0;
    final rate = double.tryParse(_interestController.text.replaceAll(',', '')) ?? 0;

    setState(() {
      _monthlyDeposit = deposit;
      _annualRate = rate;
    });

    if (!_resultCtrl.isAnimating) {
      _resultCtrl.forward(from: 0.0);
    }
  }

  /// Accurate monthly compound DPS formula
  /// Total M = P * [ ((1 + r/12)^n - 1) / (r/12) ] * (1 + r/12)
  _DpsResult _calculateDps() {
    final int months = _selectedYears * 12;
    if (_monthlyDeposit <= 0 || months <= 0) {
      return const _DpsResult(
        totalDeposit: 0,
        grossProfit: 0,
        aitTax: 0,
        netMaturityAmount: 0,
        schedule: [],
      );
    }

    final double monthlyRate = _annualRate / 1200.0;
    double grossMaturity;

    if (monthlyRate > 0) {
      grossMaturity = _monthlyDeposit *
          ((pow(1 + monthlyRate, months) - 1) / monthlyRate) *
          (1 + monthlyRate);
    } else {
      grossMaturity = _monthlyDeposit * months;
    }

    final double totalDeposit = _monthlyDeposit * months;
    final double grossProfit = (grossMaturity - totalDeposit).clamp(0.0, double.infinity);
    final double taxRate = _hasTin ? 0.05 : 0.10;
    final double aitTax = grossProfit * taxRate;
    final double netMaturity = grossMaturity - aitTax;

    // Yearly schedule
    final List<_DpsYearRow> schedule = [];
    for (int y = 1; y <= _selectedYears; y++) {
      final int m = y * 12;
      double yGross = 0;
      if (monthlyRate > 0) {
        yGross = _monthlyDeposit *
            ((pow(1 + monthlyRate, m) - 1) / monthlyRate) *
            (1 + monthlyRate);
      } else {
        yGross = _monthlyDeposit * m;
      }
      final double yDeposit = _monthlyDeposit * m;
      final double yProfit = (yGross - yDeposit).clamp(0.0, double.infinity);
      final double yTax = yProfit * taxRate;
      schedule.add(_DpsYearRow(
        year: y,
        deposit: yDeposit,
        interest: yProfit,
        netTotal: yGross - yTax,
      ));
    }

    return _DpsResult(
      totalDeposit: totalDeposit,
      grossProfit: grossProfit,
      aitTax: aitTax,
      netMaturityAmount: netMaturity,
      schedule: schedule,
    );
  }

  String _fmt(double v) {
    return NumberFormat('#,##,###').format(v.round());
  }

  Future<void> _saveAsInvestment(double totalDeposit, double netMaturity) async {
    final nameCtrl = TextEditingController(text: 'DPS ($_selectedYears Years)');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.t('save_as_investment'), style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t('save_dps_desc'), style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: context.t('investment_name'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDefault,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(context.t('save')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final now = DateTime.now();
      final model = InvestmentModel(
        id: const Uuid().v4(),
        name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'DPS',
        type: InvestmentType.dps,
        investedAmount: totalDeposit.round(),
        currentValue: totalDeposit.round(),
        expectedReturn: (netMaturity - totalDeposit).round(),
        startDate: now,
        maturityDate: DateTime(now.year + _selectedYears, now.month, now.day),
        note: 'Monthly: ৳${_fmt(_monthlyDeposit)}, Rate: $_annualRate%, AIT: ${_hasTin ? "5%" : "10%"}',
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(investmentsProvider.notifier).addInvestment(model);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(context.t('investment_saved_success')),
            ]),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const currency = '৳';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final result = _calculateDps();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.t('dps_calculator_title')),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero Output Card ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _anim(
                index: 1,
                child: _buildHeroCard(context, isDark, primary, currency, result),
              ),
            ),

            // ── Input Controls Card ──────────────────────────────────
            SliverToBoxAdapter(
              child: _anim(
                index: 2,
                child: _buildInputCard(context, isDark, primary, currency),
              ),
            ),

            // ── Tax / AIT Information Card ───────────────────────────
            SliverToBoxAdapter(
              child: _anim(
                index: 3,
                child: _buildTaxInfoCard(context, isDark, result, currency),
              ),
            ),

            // ── Yearly Breakdown Schedule ────────────────────────────
            if (result.schedule.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _anim(
                  index: 4,
                  child: _buildScheduleHeader(context, isDark),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildScheduleRow(
                      ctx, isDark, primary, currency, result.schedule[i],
                    ),
                    childCount: result.schedule.length,
                  ),
                ),
              ),
            ] else
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
    _DpsResult result,
  ) {
    final depositRatio = result.netMaturityAmount > 0
        ? (result.totalDeposit / result.netMaturityAmount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
              : [const Color(0xFF4F46E5), const Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.3 : 0.25),
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
              Text(
                context.t('net_maturity_amount').toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 1.0,
                ),
              ),
              if (result.totalDeposit > 0)
                GestureDetector(
                  onTap: () => _saveAsInvestment(result.totalDeposit, result.netMaturityAmount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bookmark_add_outlined, color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          context.t('add_to_investments'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$currency${_fmt(result.netMaturityAmount)}',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),

          // Visual Proportion Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (depositRatio * 100).round().clamp(1, 100),
                    child: Container(color: Colors.white),
                  ),
                  Expanded(
                    flex: ((1 - depositRatio) * 100).round().clamp(1, 100),
                    child: Container(color: const Color(0xFF34D399)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Sub Stats Row
          Row(
            children: [
              Expanded(
                child: _heroSubStat(
                  label: context.t('total_deposit'),
                  value: '$currency${_fmt(result.totalDeposit)}',
                  dotColor: Colors.white,
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.15)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _heroSubStat(
                    label: context.t('net_profit'),
                    value: '+$currency${_fmt(result.netMaturityAmount - result.totalDeposit)}',
                    dotColor: const Color(0xFF34D399),
                  ),
                ),
              ),
            ],
          ),
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
            fontSize: 14,
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

  Widget _buildInputCard(
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Deposit Field
          Text(
            context.t('monthly_deposit'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _depositController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _recalculate(),
            decoration: InputDecoration(
              prefixIcon: Container(
                width: 38,
                alignment: Alignment.center,
                child: Text(
                  currency,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ),
              hintText: '5,000',
              filled: true,
              fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),

          // Quick Deposit Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [1000, 2000, 5000, 10000, 20000, 50000].map((amt) {
                final isSelected = _monthlyDeposit.round() == amt;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(
                      '$currency${_fmt(amt.toDouble())}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    backgroundColor: isSelected
                        ? primary
                        : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide.none,
                    onPressed: () {
                      _depositController.text = amt.toString();
                      _recalculate();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Interest Rate Field
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('annual_interest_rate'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _interestController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _recalculate(),
                      decoration: InputDecoration(
                        suffixText: '%',
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      context.t('tenure_years'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedYears,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: [1, 2, 3, 4, 5, 7, 10].map((y) {
                            return DropdownMenuItem<int>(
                              value: y,
                              child: Text(
                                '$y ${context.t(y == 1 ? "year" : "years")}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedYears = val);
                              _recalculate();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // TIN / Tax Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 20,
                  color: _hasTin ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasTin ? context.t('has_tin_proof') : context.t('no_tin_proof'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _hasTin ? context.t('tax_rate_5') : context.t('tax_rate_10'),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _hasTin,
                  activeTrackColor: AppColors.success,
                  onChanged: (v) {
                    setState(() => _hasTin = v);
                    _recalculate();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxInfoCard(
    BuildContext context,
    bool isDark,
    _DpsResult result,
    String currency,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.gavel_rounded, size: 18, color: AppColors.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('gross_interest_and_ait'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${context.t("gross_profit")}: $currency${_fmt(result.grossProfit)} · ${context.t("source_tax")}: $currency${_fmt(result.aitTax)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-$currency${_fmt(result.aitTax)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.t('yearly_growth_schedule'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          Text(
            context.t('compound_growth'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(
    BuildContext context,
    bool isDark,
    Color primary,
    String currency,
    _DpsYearRow row,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'Y${row.year}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.t("deposit")}: $currency${_fmt(row.deposit)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '${context.t("interest")}: +$currency${_fmt(row.interest)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currency${_fmt(row.netTotal)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                context.t('net_balance'),
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DpsResult {
  final double totalDeposit;
  final double grossProfit;
  final double aitTax;
  final double netMaturityAmount;
  final List<_DpsYearRow> schedule;

  const _DpsResult({
    required this.totalDeposit,
    required this.grossProfit,
    required this.aitTax,
    required this.netMaturityAmount,
    required this.schedule,
  });
}

class _DpsYearRow {
  final int year;
  final double deposit;
  final double interest;
  final double netTotal;

  const _DpsYearRow({
    required this.year,
    required this.deposit,
    required this.interest,
    required this.netTotal,
  });
}

