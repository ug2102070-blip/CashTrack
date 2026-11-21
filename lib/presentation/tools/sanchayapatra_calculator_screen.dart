// lib/presentation/tools/sanchayapatra_calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/investment_model.dart';
import '../providers/app_providers.dart';

enum SanchayaScheme {
  paribar, // Paribar (5-Yr)
  threeMonth, //3-Month Profit (3-Yr)
  fiveYearGeneral, // Bangladesh 5-Yr
    
  pensioner, // Pensioner (5-Yr)
}

class SanchayapatraCalculatorScreen extends ConsumerStatefulWidget {
  const SanchayapatraCalculatorScreen({super.key});

  @override
  ConsumerState<SanchayapatraCalculatorScreen> createState() =>
      _SanchayapatraCalculatorScreenState();
}

class _SanchayapatraCalculatorScreenState
    extends ConsumerState<SanchayapatraCalculatorScreen>
    with TickerProviderStateMixin {
  final _amountController = TextEditingController(text: '');

  SanchayaScheme _selectedScheme = SanchayaScheme.paribar;
  double _investAmount = 0;

  late AnimationController _entryCtrl;
  late AnimationController _resultCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const List<int> _delays = [0, 70, 140, 210, 280, 350];

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
    _amountController.dispose();
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
    final amt = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    setState(() {
      _investAmount = amt;
    });

    if (!_resultCtrl.isAnimating) {
      _resultCtrl.forward(from: 0.0);
    }
  }

  _SanchayaResult _computeResult() {
    if (_investAmount <= 0) {
      return const _SanchayaResult(
        tenureYears: 5,
        isMonthlyPayout: true,
        grossPayoutPerPeriod: 0,
        netPayoutPerPeriod: 0,
        totalNetProfit: 0,
        effectiveRate: 0,
        aitTaxRate: 0,
        aitPerPeriod: 0,
        rulesSummary: '',
      );
    }

    double slab1Rate = 0;
    double slab2Rate = 0;
    double slab3Rate = 0;
    int tenureYears = 5;
    bool isMonthly = true;
    String rules = '';

    switch (_selectedScheme) {
      case SanchayaScheme.paribar:
        tenureYears = 5;
        isMonthly = true;
        slab1Rate = 11.52;
        slab2Rate = 10.50;
        slab3Rate = 9.50;
        rules = 'Eligible: Women (18+), Disabled or Males aged 65+. Max single limit:  345 Lakhs, joint:  31 Crore.';
        break;
      case SanchayaScheme.threeMonth:
        tenureYears =3;
        isMonthly = false; // Quarterly
        slab1Rate = 11.04;
        slab2Rate = 10.00;
        slab3Rate = 9.00;
        rules = 'Eligible: All adult Bangladeshi citizens. Payout every3 months. Max single limit:  330 Lakhs, joint:  360 Lakhs.';
        break;
      case SanchayaScheme.fiveYearGeneral:
        tenureYears = 5;
        isMonthly = false; // Maturity payout
        slab1Rate = 11.28;
        slab2Rate = 10.30;
        slab3Rate = 9.30;
        rules = 'Eligible: All adult citizens and recognized institutions. Payout at 5-year maturity with compounding profit.';
        break;
      case SanchayaScheme.pensioner:
        tenureYears = 5;
        isMonthly = false; // Quarterly
        slab1Rate = 11.76;
        slab2Rate = 10.75;
        slab3Rate = 9.75;
        rules = 'Eligible: Retired govt/semi-govt/autonomous/military employees and deceased pensioner family. Payout every3 months.';
        break;
    }

    // Tiered slab weighted rate calculation
    double totalAnnualProfit = 0;
    if (_investAmount <= 1500000) {
      totalAnnualProfit = _investAmount * (slab1Rate / 100);
    } else if (_investAmount <= 3000000) {
      final s1 = 1500000 * (slab1Rate / 100);
      final s2 = (_investAmount - 1500000) * (slab2Rate / 100);
      totalAnnualProfit = s1 + s2;
    } else {
      final s1 = 1500000 * (slab1Rate / 100);
      final s2 = 1500000 * (slab2Rate / 100);
      final s3 = (_investAmount - 3000000) * (slab3Rate / 100);
      totalAnnualProfit = s1 + s2 + s3;
    }

    final effectiveRate = (_investAmount > 0)
        ? (totalAnnualProfit / _investAmount) * 100
        : slab1Rate;

    // AIT: 5% if total investment <= 5 Lakhs, 10% if > 5 Lakhs
    final aitRate = _investAmount <= 500000 ? 0.05 : 0.10;
    final totalAnnualTax = totalAnnualProfit * aitRate;
    final totalAnnualNetProfit = totalAnnualProfit - totalAnnualTax;

    double grossPerPeriod;
    double netPerPeriod;
    double aitPerPeriod;

    if (_selectedScheme == SanchayaScheme.paribar) {
      // Monthly payout
      grossPerPeriod = totalAnnualProfit / 12.0;
      aitPerPeriod = totalAnnualTax / 12.0;
      netPerPeriod = totalAnnualNetProfit / 12.0;
    } else if (_selectedScheme == SanchayaScheme.threeMonth ||
        _selectedScheme == SanchayaScheme.pensioner) {
      // Quarterly payout (every3 months)
      grossPerPeriod = totalAnnualProfit / 4.0;
      aitPerPeriod = totalAnnualTax / 4.0;
      netPerPeriod = totalAnnualNetProfit / 4.0;
    } else {
      // 5-Year General at maturity
      grossPerPeriod = totalAnnualProfit;
      aitPerPeriod = totalAnnualTax;
      netPerPeriod = totalAnnualNetProfit;
    }

    final totalNetProfit = totalAnnualNetProfit * tenureYears;

    return _SanchayaResult(
      tenureYears: tenureYears,
      isMonthlyPayout: isMonthly,
      grossPayoutPerPeriod: grossPerPeriod,
      netPayoutPerPeriod: netPerPeriod,
      totalNetProfit: totalNetProfit,
      effectiveRate: effectiveRate,
      aitTaxRate: aitRate * 100,
      aitPerPeriod: aitPerPeriod,
      rulesSummary: rules,
    );
  }

  String _fmt(double v) {
    return NumberFormat('#,##,###').format(v.round());
  }

  Future<void> _saveAsInvestment(double investAmount, double totalProfit) async {
    String defaultName = 'Sanchayapatra';
    switch (_selectedScheme) {
      case SanchayaScheme.paribar:
        defaultName = 'Paribar Sanchayapatra';
        break;
      case SanchayaScheme.threeMonth:
        defaultName = '3-Month Profit Sanchayapatra';
        break;
      case SanchayaScheme.fiveYearGeneral:
        defaultName = 'Bangladesh Sanchayapatra';
        break;
      case SanchayaScheme.pensioner:
        defaultName = 'Pensioner Sanchayapatra';
        break;
    }

    final nameCtrl = TextEditingController(text: defaultName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.t('save_as_investment'), style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t('save_sanchaya_desc'), style: const TextStyle(fontSize: 13)),
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
      final res = _computeResult();
      final model = InvestmentModel(
        id: const Uuid().v4(),
        name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : defaultName,
        type: InvestmentType.fixedDeposit,
        investedAmount: investAmount.round(),
        currentValue: investAmount.round(),
        expectedReturn: totalProfit.round(),
        startDate: now,
        maturityDate: DateTime(now.year + res.tenureYears, now.month, now.day),
        note: 'Sanchayapatra: $defaultName, Rate: ${res.effectiveRate.toStringAsFixed(2)}%, AIT: ${res.aitTaxRate.toInt()}%',
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
    final result = _computeResult();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.t('sanchayapatra_calculator_title')),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            //  Scheme Selector 
            SliverToBoxAdapter(
              child: _anim(index: 1, child: _buildSchemeSelector(context, isDark, primary)),
            ),

            //  Hero Profit Card 
            SliverToBoxAdapter(
              child: _anim(
                index: 2,
                child: _buildHeroCard(context, isDark, primary, currency, result),
              ),
            ),

            //  Investment Amount Input 
            SliverToBoxAdapter(
              child: _anim(
                index:3,
                child: _buildInputCard(context, isDark, primary, currency),
              ),
            ),

            //  Rules & Slab Rate Info 
            SliverToBoxAdapter(
              child: _anim(
                index: 4,
                child: _buildInfoCard(context, isDark, primary, currency, result),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }



  Widget _buildSchemeSelector(BuildContext context, bool isDark, Color primary) {
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _schemeChip(
            scheme: SanchayaScheme.paribar,
            label: context.t('scheme_paribar'),
            isDark: isDark,
            primary: primary,
          ),
          _schemeChip(
            scheme: SanchayaScheme.threeMonth,
            label: context.t('scheme_three_month'),
            isDark: isDark,
            primary: primary,
          ),
          _schemeChip(
            scheme: SanchayaScheme.pensioner,
            label: context.t('scheme_pensioner'),
            isDark: isDark,
            primary: primary,
          ),
          _schemeChip(
            scheme: SanchayaScheme.fiveYearGeneral,
            label: context.t('scheme_general_5yr'),
            isDark: isDark,
            primary: primary,
          ),
        ],
      ),
    );
  }

  Widget _schemeChip({
    required SanchayaScheme scheme,
    required String label,
    required bool isDark,
    required Color primary,
  }) {
    final isSelected = _selectedScheme == scheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        selected: isSelected,
        selectedColor: primary,
        backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedScheme = scheme);
            _recalculate();
          }
        },
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    bool isDark,
    Color primary,
    String currency,
    _SanchayaResult result,
  ) {
    String payoutLabel = context.t('net_monthly_profit');
    if (_selectedScheme == SanchayaScheme.threeMonth ||
        _selectedScheme == SanchayaScheme.pensioner) {
      payoutLabel = context.t('net_quarterly_profit');
    } else if (_selectedScheme == SanchayaScheme.fiveYearGeneral) {
      payoutLabel = context.t('net_maturity_profit');
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
              : [const Color(0xFF059669), const Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: isDark ? 0.3 : 0.25),
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
                payoutLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 1.0,
                ),
              ),
              if (_investAmount > 0)
                GestureDetector(
                  onTap: () => _saveAsInvestment(_investAmount, result.totalNetProfit),
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
            '$currency${_fmt(result.netPayoutPerPeriod)}',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),

          // Sub Stats Row
          Row(
            children: [
              Expanded(
                child: _heroSubStat(
                  label: context.t('effective_rate'),
                  value: '${result.effectiveRate.toStringAsFixed(2)}% p.a.',
                  dotColor: Colors.white,
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.15)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _heroSubStat(
                    label: context.t('total_profit_${result.tenureYears}yr'),
                    value: '+$currency${_fmt(result.totalNetProfit)}',
                    dotColor: const Color(0xFF6EE7B7),
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
            offset: const Offset(0,3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('investment_amount'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
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
              hintText: 'e.g. 100000',
              filled: true,
              fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Amount Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                100000, 200000, 500000, 1000000, 1500000, 2500000, 4500000
              ].map((amt) {
                final isSelected = _investAmount.round() == amt;
                final label = amt >= 100000
                    ? '${(amt / 100000).toStringAsFixed(0)} Lakh'
                    : '$currency$amt';
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(
                      label,
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
                      _amountController.text = amt.toString();
                      _recalculate();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    bool isDark,
    Color primary,
    String currency,
    _SanchayaResult result,
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
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info_outline_rounded, size: 16, color: primary),
              ),
              const SizedBox(width: 10),
              Text(
                context.t('scheme_details_and_tax'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.rulesSummary,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
          const SizedBox(height: 10),
          _infoRow(
            context,
            title: context.t('gross_payout'),
            value: '$currency${_fmt(result.grossPayoutPerPeriod)}',
          ),
          const SizedBox(height: 6),
          _infoRow(
            context,
            title: '${context.t("source_tax_ait")} (${result.aitTaxRate.toInt()}%)',
            value: '-$currency${_fmt(result.aitPerPeriod)}',
            valueColor: AppColors.error,
          ),
          const SizedBox(height: 6),
          _infoRow(
            context,
            title: context.t('net_payout'),
            value: '$currency${_fmt(result.netPayoutPerPeriod)}',
            valueColor: AppColors.success,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required String title,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SanchayaResult {
  final int tenureYears;
  final bool isMonthlyPayout;
  final double grossPayoutPerPeriod;
  final double netPayoutPerPeriod;
  final double totalNetProfit;
  final double effectiveRate;
  final double aitTaxRate;
  final double aitPerPeriod;
  final String rulesSummary;

  const _SanchayaResult({
    required this.tenureYears,
    required this.isMonthlyPayout,
    required this.grossPayoutPerPeriod,
    required this.netPayoutPerPeriod,
    required this.totalNetProfit,
    required this.effectiveRate,
    required this.aitTaxRate,
    required this.aitPerPeriod,
    required this.rulesSummary,
  });
}

