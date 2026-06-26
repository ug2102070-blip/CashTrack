import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class EmiCalculatorScreen extends StatefulWidget {
  const EmiCalculatorScreen({super.key});

  @override
  State<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends State<EmiCalculatorScreen>
    with TickerProviderStateMixin {
  final _loanController = TextEditingController();
  final _interestController = TextEditingController();
  final _tenureController = TextEditingController();

  double _loanAmount = 0;
  int _tenureMonths = 0;

  List<EmiScheduleRow> _schedule = [];

  // Animation controllers
  late AnimationController _entryCtrl;
  late AnimationController _resultCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const List<int> _delays = [0, 80, 160, 240, 320, 400, 480];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

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
    _loanController.dispose();
    _interestController.dispose();
    _tenureController.dispose();
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
    final loan = double.tryParse(_loanController.text.replaceAll(',', '')) ?? 0;
    final rate =
        double.tryParse(_interestController.text.replaceAll(',', '')) ?? 0;
    final tenure = int.tryParse(_tenureController.text) ?? 0;

    setState(() {
      _loanAmount = loan;
      _tenureMonths = tenure;
      _schedule = _buildSchedule(loan, rate, tenure);
    });

    if (_schedule.isNotEmpty && _resultCtrl.status != AnimationStatus.completed) {
      _resultCtrl.forward();
    }
  }

  List<EmiScheduleRow> _buildSchedule(
      double loan, double annualRate, int months) {
    if (loan <= 0 || months <= 0) return [];

    final monthlyRate = annualRate / 1200;
    final emi = monthlyRate > 0
        ? loan *
            monthlyRate *
            pow(1 + monthlyRate, months) /
            (pow(1 + monthlyRate, months) - 1)
        : loan / months;
    var balance = loan;
    final rows = <EmiScheduleRow>[];

    for (var i = 1; i <= months; i++) {
      final interest = balance * monthlyRate;
      final principal = (emi - interest).clamp(0.0, balance);
      final nextBalance = (balance - principal).clamp(0.0, double.infinity);
      rows.add(EmiScheduleRow(
        month: i,
        emi: emi,
        principal: principal,
        interest: interest,
        balance: nextBalance,
      ));
      balance = nextBalance;
    }

    return rows;
  }

  String _formatMoney(double value) {
    return NumberFormat.currency(symbol: '', decimalDigits: 2).format(value);
  }

  String _fmtShort(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    const currency = '৳';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthlyEmi = _schedule.isNotEmpty ? _schedule.first.emi : 0.0;
    final totalPayment =
        _schedule.fold<double>(0, (sum, row) => sum + row.emi);
    final totalInterest = totalPayment - _loanAmount;
    final principalPercent =
        totalPayment > 0 ? (_loanAmount / totalPayment) : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Custom AppBar ──────────────────────────────────────
            SliverToBoxAdapter(
              child: _anim(
                index: 0,
                child: _buildAppBar(context, isDark),
              ),
            ),

            // ── Hero Summary Card ──────────────────────────────────
            SliverToBoxAdapter(
              child: _anim(
                index: 1,
                child: _buildHeroCard(
                  context, isDark, currency,
                  monthlyEmi, totalInterest, totalPayment,
                  principalPercent,
                ),
              ),
            ),

            // ── Input Fields ───────────────────────────────────────
            SliverToBoxAdapter(
              child: _anim(
                index: 2,
                child: _buildInputSection(context, isDark),
              ),
            ),

            // ── Loan Breakdown Card ────────────────────────────────
            if (_schedule.isNotEmpty)
              SliverToBoxAdapter(
                child: _anim(
                  index: 3,
                  child: _buildBreakdownCard(
                    context, isDark, currency,
                    totalPayment, totalInterest, principalPercent,
                  ),
                ),
              ),

            // ── Schedule or Empty State ────────────────────────────
            if (_schedule.isEmpty)
              SliverToBoxAdapter(
                child: _anim(
                  index: 4,
                  child: _buildEmptyState(context, isDark),
                ),
              )
            else ...[
              // Schedule header
              SliverToBoxAdapter(
                child: _anim(
                  index: 4,
                  child: _buildScheduleHeader(context, isDark),
                ),
              ),
              // Schedule list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final row = _schedule[index];
                    return _anim(
                      index: 5,
                      child: _buildScheduleItem(
                          context, isDark, currency, row, index),
                    );
                  },
                  childCount: _schedule.length,
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── Custom AppBar ─────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Icon + title
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF0891B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.calculate_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('emi_calculator'),
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  context.t('calculate_emi'),
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Summary Card ─────────────────────────────────────────────────────
  Widget _buildHeroCard(
    BuildContext context, bool isDark, String currency,
    double monthlyEmi, double totalInterest, double totalPayment,
    double principalPercent,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF0891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chip label
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 13),
                const SizedBox(width: 6),
                Text(
                  context.t('monthly_emi'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Big EMI value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _schedule.isNotEmpty
                    ? _formatMoney(monthlyEmi)
                    : '0.00',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _heroStat(
                  context.t('total_interest'),
                  '$currency${_fmtShort(totalInterest)}',
                  Icons.trending_up_rounded,
                ),
                _heroDivider(),
                _heroStat(
                  context.t('total_payment'),
                  '$currency${_fmtShort(totalPayment)}',
                  Icons.account_balance_wallet_rounded,
                ),
                _heroDivider(),
                _heroStat(
                  context.t('tenure_months'),
                  _tenureMonths > 0 ? '$_tenureMonths' : '–',
                  Icons.calendar_month_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  // ── Input Section ─────────────────────────────────────────────────────────
  Widget _buildInputSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          _buildInputField(
            context,
            isDark: isDark,
            icon: Icons.account_balance_rounded,
            iconColor: const Color(0xFF10B981),
            iconBgColor: isDark
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : const Color(0xFFD1FAE5),
            controller: _loanController,
            label: context.t('loan_amount'),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _recalculate(),
            prefix: '৳',
          ),
          const SizedBox(height: 10),
          _buildInputField(
            context,
            isDark: isDark,
            icon: Icons.percent_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBgColor: isDark
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                : const Color(0xFFEDE9FE),
            controller: _interestController,
            label: context.t('interest_rate'),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _recalculate(),
            suffix: '%',
          ),
          const SizedBox(height: 10),
          _buildInputField(
            context,
            isDark: isDark,
            icon: Icons.date_range_rounded,
            iconColor: const Color(0xFF3B82F6),
            iconBgColor: isDark
                ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                : const Color(0xFFDBEAFE),
            controller: _tenureController,
            label: context.t('tenure_months'),
            keyboardType: TextInputType.number,
            onChanged: (_) => _recalculate(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
    required void Function(String) onChanged,
    String? prefix,
    String? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.45),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                prefixText: prefix != null ? '$prefix ' : null,
                prefixStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
                suffixText: suffix,
                suffixStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: iconColor.withValues(alpha: 0.7),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ── Loan Breakdown Card ───────────────────────────────────────────────────
  Widget _buildBreakdownCard(
    BuildContext context, bool isDark, String currency,
    double totalPayment, double totalInterest, double principalPercent,
  ) {
    final interestPercent = 1 - principalPercent;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.donut_small_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                context.t('loan_breakdown'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (principalPercent * 100).round().clamp(1, 99),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF7C3AED),
                            Color(0xFF9D6FFF),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (interestPercent * 100).round().clamp(1, 99),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF0891B2),
                            Color(0xFF22D3EE),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Legend + values
          Row(
            children: [
              _breakdownItem(
                context,
                color: const Color(0xFF7C3AED),
                label: context.t('principal_amount'),
                value: '$currency${_formatMoney(_loanAmount)}',
                percent: '${(principalPercent * 100).toStringAsFixed(1)}%',
              ),
              const SizedBox(width: 16),
              _breakdownItem(
                context,
                color: const Color(0xFF0891B2),
                label: context.t('interest_amount'),
                value: '$currency${_formatMoney(totalInterest)}',
                percent: '${(interestPercent * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownItem(
    BuildContext context, {
    required Color color,
    required String label,
    required String value,
    required String percent,
  }) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              percent,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  const Color(0xFF0891B2).withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 36,
              color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.t('emi_empty_title'),
            style: AppTextStyles.h5.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.t('emi_empty_subtitle'),
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Schedule Header ───────────────────────────────────────────────────────
  Widget _buildScheduleHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.table_chart_rounded,
                size: 14, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(width: 9),
          Text(
            context.t('emi_schedule'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
              letterSpacing: -0.1,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_schedule.length} ${context.t('tenure_months').toLowerCase()}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Schedule Item ─────────────────────────────────────────────────────────
  Widget _buildScheduleItem(
    BuildContext context, bool isDark, String currency,
    EmiScheduleRow row, int index,
  ) {
    final isLast = index == _schedule.length - 1;
    final principalPercent = row.emi > 0 ? row.principal / row.emi : 0.0;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, isLast ? 0 : 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.06 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Month badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7C3AED).withValues(alpha: 0.12),
                      const Color(0xFF0891B2).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF7C3AED)
                        .withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${row.month}',
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      context.t('month_label'),
                      style: TextStyle(
                        color: const Color(0xFF7C3AED)
                            .withValues(alpha: 0.6),
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // EMI amount + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currency${_formatMoney(row.emi)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${context.t('principal')}: $currency${_formatMoney(row.principal)}  •  ${context.t('interest')}: $currency${row.interest.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency${_fmtShort(row.balance)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: row.balance <= 0
                          ? AppColors.success
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    context.t('emi_balance'),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mini progress bar (principal vs interest)
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 3,
              child: Row(
                children: [
                  Expanded(
                    flex: (principalPercent * 100).round().clamp(1, 99),
                    child: Container(
                      color: const Color(0xFF7C3AED)
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  Expanded(
                    flex:
                        ((1 - principalPercent) * 100).round().clamp(1, 99),
                    child: Container(
                      color: const Color(0xFF0891B2)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmiScheduleRow {
  final int month;
  final double emi;
  final double principal;
  final double interest;
  final double balance;

  EmiScheduleRow({
    required this.month,
    required this.emi,
    required this.principal,
    required this.interest,
    required this.balance,
  });
}
