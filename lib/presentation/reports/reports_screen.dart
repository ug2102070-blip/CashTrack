// lib/presentation/reports/reports_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/transaction_model.dart';
import '../providers/app_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTimeRange? _selectedDateRange;
  String _selectedFormat = 'PDF';
  static const _rangeThisMonth = 'this_month';
  static const _rangeLastMonth = 'last_month';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.t('reports_export')),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Selector
            _buildDateRangeCard(),

            // Quick Reports
            _buildSectionHeader(context.t('quick_reports')),
            _buildQuickReportsList(),

            // Export Options
            _buildSectionHeader(context.t('export_data')),
            _buildExportOptions(),

            // Report Templates
            _buildSectionHeader(context.t('report_templates')),
            _buildReportTemplates(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeCard() {
    final start = _selectedDateRange?.start;
    final end = _selectedDateRange?.end;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                context.t('report_period'),
                style: AppTextStyles.body1.copyWith(color: Colors.white70),
              ),
              const Icon(Icons.calendar_month, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            start != null && end != null
                ? '${DateFormat('MMM dd, yyyy').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}'
                : context.t('select_date_range'),
            style: AppTextStyles.h4.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectQuickRange(_rangeThisMonth),
                  icon: const Icon(Icons.today, size: 18),
                  label: Text(context.t('this_month')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectCustomRange,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(context.t('custom')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: AppTextStyles.h5),
    );
  }

  Widget _buildQuickReportsList() {
    return Column(
      children: [
        _buildQuickReportCard(
          context.t('income_statement'),
          context.t('income_statement_desc'),
          Icons.trending_up,
          AppColors.success,
          () => _generateReport('income'),
        ),
        _buildQuickReportCard(
          context.t('expense_report'),
          context.t('expense_report_desc'),
          Icons.trending_down,
          AppColors.error,
          () => _generateReport('expense'),
        ),
        _buildQuickReportCard(
          context.t('cash_flow'),
          context.t('cash_flow_desc'),
          Icons.swap_horiz,
          AppColors.info,
          () => _generateReport('cashflow'),
        ),
        _buildQuickReportCard(
          context.t('budget_vs_actual'),
          context.t('budget_vs_actual_desc'),
          Icons.bar_chart,
          AppColors.warning,
          () => _generateReport('budget'),
        ),
      ],
    );
  }

  Widget _buildQuickReportCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        tileColor: Theme.of(context).colorScheme.surface,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        trailing:
          Icon(Icons.chevron_right,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('export_format'), style: AppTextStyles.body1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['PDF', 'CSV', 'Excel'].map((format) {
              final isSelected = _selectedFormat == format;
              return ChoiceChip(
                label: Text(format),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFormat = format);
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exportData,
              icon: const Icon(Icons.file_download),
              label: Text(
                context.t('export_as_format', params: {
                  'format': _selectedFormat,
                }),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _shareReport,
              icon: const Icon(Icons.share),
              label: Text(context.t('share_report')),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTemplates() {
    return Column(
      children: [
        _buildTemplateCard(
          'monthly_summary',
          context.t('monthly_summary'),
          context.t('monthly_summary_desc'),
          Icons.calendar_today,
          const Color(0xFF8B5CF6),
        ),
        _buildTemplateCard(
          'tax_report',
          context.t('tax_report'),
          context.t('tax_report_desc'),
          Icons.receipt_long,
          const Color(0xFFEF4444),
        ),
        _buildTemplateCard(
          'investment_portfolio',
          context.t('investment_portfolio'),
          context.t('investment_portfolio_desc'),
          Icons.trending_up,
          const Color(0xFF10B981),
        ),
        _buildTemplateCard(
          'debt_summary',
          context.t('debt_summary'),
          context.t('debt_summary_desc'),
          Icons.account_balance,
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(
    String templateId,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.body1
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _downloadTemplate(templateId),
          ),
        ],
      ),
    );
  }

  void _selectQuickRange(String range) {
    final now = DateTime.now();
    DateTimeRange dateRange;

    switch (range) {
      case _rangeThisMonth:
        dateRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
        break;
      case _rangeLastMonth:
        dateRange = DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0),
        );
        break;
      default:
        return;
    }

    setState(() => _selectedDateRange = dateRange);
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _generateReport(String type) {
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('select_date_range_first'))),
      );
      return;
    }

    final transactions = ref.read(transactionsProvider);
    final filtered = _filterTransactions(transactions);
    final incomeTransactions =
        filtered.where((t) => t.type == TransactionType.income).toList();
    final expenseTransactions =
        filtered.where((t) => t.type == TransactionType.expense).toList();
    final settings = ref.read(settingsProvider);
    final currency = (settings['currency'] as String?) ?? '\u09F3';
    final budgets = ref.read(budgetsProvider);

    final rangedBudgets = _getRangedBudgets(budgets, _selectedDateRange!);

    final dayCount = _selectedDateRange!.end
            .difference(_selectedDateRange!.start)
            .inDays +
        1;

    final totalIncome = _sumAmount(incomeTransactions);
    final totalExpense = _sumAmount(expenseTransactions);
    final totalBudget = rangedBudgets.fold<double>(0, (sum, b) => sum + b.amount);
    final totalBudgetSpent =
        rangedBudgets.fold<double>(0, (sum, b) => sum + b.spent);
    final overBudgetCount = rangedBudgets
        .where((b) => b.amount > 0 && b.spent > b.amount)
        .length;

    late final String reportTitle;
    late final List<List<String>> stats;

    switch (type) {
      case 'income':
        final avgPerDay =
            dayCount > 0 ? totalIncome / dayCount : totalIncome;
        reportTitle = context.t('income_statement');
        stats = [
          [
            context.t('income_transactions'),
            incomeTransactions.length.toString()
          ],
          [
            context.t('total_income'),
            '$currency ${totalIncome.toStringAsFixed(2)}'
          ],
          [
            context.t('average_per_day'),
            '$currency ${avgPerDay.toStringAsFixed(2)}'
          ],
        ];
        break;
      case 'expense':
        final avgPerDay =
            dayCount > 0 ? totalExpense / dayCount : totalExpense;
        reportTitle = context.t('expense_report');
        stats = [
          [
            context.t('expense_transactions'),
            expenseTransactions.length.toString()
          ],
          [
            context.t('total_expense'),
            '$currency ${totalExpense.toStringAsFixed(2)}'
          ],
          [
            context.t('average_per_day'),
            '$currency ${avgPerDay.toStringAsFixed(2)}'
          ],
        ];
        break;
      case 'budget':
        final utilization =
            totalBudget > 0 ? (totalBudgetSpent / totalBudget) * 100 : 0.0;
        final onTrackCount = rangedBudgets
            .where((b) => b.amount > 0 && b.spent <= b.amount)
            .length;
        reportTitle = context.t('budget_vs_actual');
        stats = [
          [
            context.t('budget_categories'),
            rangedBudgets.length.toString()
          ],
          [
            context.t('total_budget'),
            '$currency ${totalBudget.toStringAsFixed(2)}'
          ],
          [
            context.t('actual_spent'),
            '$currency ${totalBudgetSpent.toStringAsFixed(2)}'
          ],
          [
            context.t('utilization'),
            '${utilization.toStringAsFixed(1)}%'
          ],
          [context.t('over_budget'), overBudgetCount.toString()],
          [context.t('on_track'), onTrackCount.toString()],
        ];
        break;
      default:
        reportTitle = context.t('cash_flow');
        stats = [
          [context.t('total_transactions'), filtered.length.toString()],
          [context.t('cash_in'), '$currency ${totalIncome.toStringAsFixed(2)}'],
          [context.t('cash_out'), '$currency ${totalExpense.toStringAsFixed(2)}'],
          [
            context.t('net_flow'),
            '$currency ${(totalIncome - totalExpense).toStringAsFixed(2)}'
          ],
        ];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reportTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('period_range', params: {
                'start': DateFormat('MMM dd').format(_selectedDateRange!.start),
                'end': DateFormat('MMM dd').format(_selectedDateRange!.end),
              }),
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: 16),
            ...stats.map((entry) => _buildReportStat(entry[0], entry[1])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('close')),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportData(reportType: type);
            },
            icon: const Icon(Icons.download),
            label: Text(context.t('export')),
          ),
        ],
      ),
    );
  }

  double _sumAmount(List<TransactionModel> transactions) {
    return transactions.fold<double>(0, (sum, t) => sum + t.amount);
  }

  Widget _buildReportStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(value,
              style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<File?> _exportData({
    bool returnFileOnly = false,
    String? reportType,
  }) async {
    if (_selectedDateRange == null) {
      if (!returnFileOnly && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('select_date_range_first'))),
        );
      }
      return null;
    }

    try {
      final transactions = ref.read(transactionsProvider);
      final filtered = _filterTransactions(transactions);
      final reportFiltered =
          _filterTransactionsByReportType(filtered, reportType);
      final budgets = ref.read(budgetsProvider);
      final categories = ref.read(categoriesProvider);
      final settings = ref.read(settingsProvider);
      final rawCurrency = (settings['currency'] as String?) ?? '\u09F3';
      // PDF fonts don't support Bengali taka sign (৳) — use 'Tk' for PDF
      final pdfCurrency = (rawCurrency == '\u09F3' || rawCurrency == '৳')
          ? 'Tk'
          : rawCurrency;
      final currency = (_selectedFormat == 'PDF') ? pdfCurrency : rawCurrency;
      final l10n = AppL10n.of(context);
      final Map<String, String> categoryNames = {
        for (final c in categories) c.id: c.name,
      };
      final dir = await getTemporaryDirectory();
      final rangedBudgets = _getRangedBudgets(budgets, _selectedDateRange!);
      final budgetRows = reportType == 'budget'
          ? _buildBudgetComparisonRows(
              rangedBudgets: rangedBudgets,
              expenseTransactions: reportFiltered,
              categoryNames: categoryNames,
            )
          : const <_BudgetComparisonRow>[];

      File file;
      if (_selectedFormat == 'PDF') {
        final pdf = reportType == 'budget'
            ? _buildBudgetComparisonPdf(budgetRows, currency, l10n)
            : _buildPdf(reportFiltered, categoryNames, currency, l10n);
        final fileName =
            'cashtrack_${reportType ?? 'report'}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
        final filePath = '${dir.path}/$fileName';
        file = File(filePath);
        await file.writeAsBytes(await pdf.save());
      } else if (_selectedFormat == 'CSV') {
        final fileName =
            'cashtrack_${reportType ?? 'report'}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
        final filePath = '${dir.path}/$fileName';
        file = File(filePath);
        final csv = reportType == 'budget'
            ? _buildBudgetComparisonCsv(budgetRows, currency)
            : _buildCsv(reportFiltered, categoryNames, currency);
        await file.writeAsString(csv);
      } else if (_selectedFormat == 'Excel') {
        final fileName =
            'cashtrack_${reportType ?? 'report'}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
        final filePath = '${dir.path}/$fileName';
        file = File(filePath);
        final bytes = reportType == 'budget'
            ? _buildBudgetComparisonExcel(budgetRows, currency)
            : _buildExcel(reportFiltered, categoryNames, currency);
        await file.writeAsBytes(bytes, flush: true);
      } else {
        if (!returnFileOnly && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.t('unsupported_export_format'))),
            );
        }
        return null;
      }

      if (!returnFileOnly && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.t('file_saved', params: {
                'file': file.path.split('/').last,
              }),
            ),
            action: SnackBarAction(
              label: context.t('share'),
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(file.path)],
                    text: context.t('cashtrack_report'),
                  ),
                );
              },
            ),
          ),
        );
      }
      return file;
    } catch (e) {
      if (!returnFileOnly && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.t('export_failed', params: {'error': '$e'}),
            ),
          ),
        );
      }
      return null;
    }
  }

  List<BudgetModel> _getRangedBudgets(
    List<BudgetModel> budgets,
    DateTimeRange range,
  ) {
    final startMonth = DateTime(range.start.year, range.start.month, 1);
    final endMonth = DateTime(range.end.year, range.end.month, 1);

    return budgets.where((b) {
      final month = DateTime(b.month.year, b.month.month, 1);
      return !month.isBefore(startMonth) && !month.isAfter(endMonth);
    }).toList();
  }

  List<_BudgetComparisonRow> _buildBudgetComparisonRows({
    required List<BudgetModel> rangedBudgets,
    required List<TransactionModel> expenseTransactions,
    required Map<String, String> categoryNames,
  }) {
    final rows = <_BudgetComparisonRow>[];
    for (final budget in rangedBudgets) {
      final spentFromTransactions = expenseTransactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.categoryId == budget.categoryId &&
              t.date.year == budget.month.year &&
              t.date.month == budget.month.month)
          .fold<double>(0, (sum, t) => sum + t.amount);

      final spent = spentFromTransactions > 0 ? spentFromTransactions : budget.spent;
      final variance = budget.amount - spent;
      final utilization = budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;

      rows.add(
        _BudgetComparisonRow(
          month: DateFormat('yyyy-MM').format(budget.month),
          category: categoryNames[budget.categoryId] ?? budget.categoryId,
          budgetAmount: budget.amount,
          spentAmount: spent,
          variance: variance,
          utilization: utilization,
        ),
      );
    }

    rows.sort((a, b) {
      final monthCompare = a.month.compareTo(b.month);
      if (monthCompare != 0) return monthCompare;
      return a.category.compareTo(b.category);
    });

    return rows;
  }

  pw.Document _buildBudgetComparisonPdf(
    List<_BudgetComparisonRow> rows,
    String currency,
    AppL10n l10n,
  ) {
    final pdf = pw.Document();
    final totalBudget = rows.fold<double>(0, (sum, r) => sum + r.budgetAmount);
    final totalSpent = rows.fold<double>(0, (sum, r) => sum + r.spentAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Text(
            l10n.t('budget_vs_actual_report'),
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            l10n.t('period_range', params: {
              'start':
                  DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start),
              'end': DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end),
            }),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            l10n.t('total_budget_label', params: {
              'amount': '$currency ${totalBudget.toStringAsFixed(2)}',
            }),
          ),
          pw.Text(
            l10n.t('total_spent_label', params: {
              'amount': '$currency ${totalSpent.toStringAsFixed(2)}',
            }),
          ),
          pw.Text(
            l10n.t('variance_label', params: {
              'amount':
                  '$currency ${(totalBudget - totalSpent).toStringAsFixed(2)}',
            }),
          ),
          pw.SizedBox(height: 14),
          if (rows.isEmpty)
            pw.Text(l10n.t('no_budget_entries_period')),
          if (rows.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: [
                l10n.t('month'),
                l10n.t('category'),
                l10n.t('budget'),
                l10n.t('spent'),
                l10n.t('variance'),
                l10n.t('utilization'),
              ],
              data: rows
                  .map(
                    (r) => [
                      r.month,
                      r.category,
                      '$currency ${r.budgetAmount.toStringAsFixed(2)}',
                      '$currency ${r.spentAmount.toStringAsFixed(2)}',
                      '$currency ${r.variance.toStringAsFixed(2)}',
                      '${r.utilization.toStringAsFixed(1)}%',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
        ],
      ),
    );

    return pdf;
  }

  String _buildBudgetComparisonCsv(
    List<_BudgetComparisonRow> rows,
    String currency,
  ) {
    final table = <List<String>>[
      [
        context.t('month'),
        context.t('category'),
        context.t('budget'),
        context.t('spent'),
        context.t('variance'),
        context.t('utilization'),
      ],
      ...rows.map((r) => [
            r.month,
            r.category,
            '$currency ${r.budgetAmount.toStringAsFixed(2)}',
            '$currency ${r.spentAmount.toStringAsFixed(2)}',
            '$currency ${r.variance.toStringAsFixed(2)}',
            '${r.utilization.toStringAsFixed(1)}%',
          ]),
    ];
    return const ListToCsvConverter().convert(table);
  }

  List<int> _buildBudgetComparisonExcel(
    List<_BudgetComparisonRow> rows,
    String currency,
  ) {
    final excel = xl.Excel.createExcel();
    final sheet = excel['BudgetVsActual'];

    sheet.appendRow([
      xl.TextCellValue(context.t('month')),
      xl.TextCellValue(context.t('category')),
      xl.TextCellValue(context.t('budget')),
      xl.TextCellValue(context.t('spent')),
      xl.TextCellValue(context.t('variance')),
      xl.TextCellValue(context.t('utilization')),
    ]);

    for (final r in rows) {
      sheet.appendRow([
        xl.TextCellValue(r.month),
        xl.TextCellValue(r.category),
        xl.TextCellValue('$currency ${r.budgetAmount.toStringAsFixed(2)}'),
        xl.TextCellValue('$currency ${r.spentAmount.toStringAsFixed(2)}'),
        xl.TextCellValue('$currency ${r.variance.toStringAsFixed(2)}'),
        xl.TextCellValue('${r.utilization.toStringAsFixed(1)}%'),
      ]);
    }

    return excel.encode() ?? <int>[];
  }

  List<TransactionModel> _filterTransactionsByReportType(
    List<TransactionModel> transactions,
    String? reportType,
  ) {
    switch (reportType) {
      case 'income':
        return transactions
            .where((t) => t.type == TransactionType.income)
            .toList();
      case 'expense':
      case 'budget':
        return transactions
            .where((t) => t.type == TransactionType.expense)
            .toList();
      case 'cashflow':
      default:
        return transactions;
    }
  }

  pw.Document _buildPdf(
    List<TransactionModel> transactions,
    Map<String, String> categoryNames,
    String currency,
    AppL10n l10n,
  ) {
    final pdf = pw.Document(
      author: 'CashTrack by Jahid Hasan',
      creator: 'CashTrack App',
      title: l10n.t('cashtrack_report'),
    );

    double totalIncome = 0;
    double totalExpense = 0;
    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else if (t.type == TransactionType.expense) {
        totalExpense += t.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (_) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'CashTrack',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF2D7A7B),
                  ),
                ),
                pw.Text(
                  l10n.t('period_range', params: {
                    'start': DateFormat('MMM dd, yyyy')
                        .format(_selectedDateRange!.start),
                    'end': DateFormat('MMM dd, yyyy')
                        .format(_selectedDateRange!.end),
                  }),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.Divider(
              color: const PdfColor.fromInt(0xFF2D7A7B),
              thickness: 2,
            ),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (_) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by CashTrack — Developed by Jahid Hasan',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          pw.Text(l10n.t('summary'),
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(l10n.t('total_income_label', params: {
            'amount': '$currency ${totalIncome.toStringAsFixed(2)}',
          })),
          pw.Text(l10n.t('total_expense_label', params: {
            'amount': '$currency ${totalExpense.toStringAsFixed(2)}',
          })),
          pw.Text(
              l10n.t('net_label', params: {
            'amount':
                '$currency ${(totalIncome - totalExpense).toStringAsFixed(2)}',
          })),
          pw.SizedBox(height: 16),
          pw.Text(l10n.t('transactions'),
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (transactions.isEmpty)
            pw.Text(l10n.t('no_transactions_period')),
          if (transactions.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: [
                l10n.t('date'),
                l10n.t('type'),
                l10n.t('category'),
                l10n.t('amount'),
                l10n.t('note')
              ],
              data: transactions.map((t) {
                final type =
                    t.type == TransactionType.income ? l10n.t('income') : l10n.t('expense');
                final date = DateFormat('yyyy-MM-dd').format(t.date);
                final amount =
                    (t.type == TransactionType.expense ? '-' : '') +
                        t.amount.toStringAsFixed(2);
                return [
                  date,
                  type,
                  categoryNames[t.categoryId] ?? t.categoryId,
                  '$currency $amount',
                  t.note ?? '—',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerLeft,
              },
            ),
        ],
      ),
    );

    return pdf;
  }

  Future<void> _shareReport() async {
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('select_date_range_first'))),
      );
      return;
    }

    final AppL10n l10n = AppL10n.of(context);
    final file = await _exportData(returnFileOnly: true);
    if (file == null || !context.mounted) return;
    final String shareText = l10n.t('cashtrack_report');

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: shareText,
      ),
    );
  }

  List<TransactionModel> _filterTransactions(
      List<TransactionModel> transactions) {
    final filtered = transactions.where((t) {
      final d = t.date;
      return d.isAfter(
              _selectedDateRange!.start.subtract(const Duration(days: 1))) &&
          d.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return filtered;
  }

  String _buildCsv(
    List<TransactionModel> transactions,
    Map<String, String> categoryNames,
    String currency,
  ) {
    final rows = <List<String>>[
      [
        context.t('date'),
        context.t('type'),
        context.t('category'),
        context.t('amount'),
        context.t('note')
      ],
      ...transactions.map((t) {
        final type =
            t.type == TransactionType.income ? context.t('income') : context.t('expense');
        final date = DateFormat('yyyy-MM-dd').format(t.date);
        final amount =
            (t.type == TransactionType.expense ? '-' : '') +
                t.amount.toStringAsFixed(2);
        return [
          date,
          type,
          categoryNames[t.categoryId] ?? t.categoryId,
          '$currency $amount',
          t.note ?? '?',
        ];
      }),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  List<int> _buildExcel(
    List<TransactionModel> transactions,
    Map<String, String> categoryNames,
    String currency,
  ) {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Report'];

    sheet.appendRow([
      xl.TextCellValue(context.t('date')),
      xl.TextCellValue(context.t('type')),
      xl.TextCellValue(context.t('category')),
      xl.TextCellValue(context.t('amount')),
      xl.TextCellValue(context.t('note')),
    ]);

    for (final t in transactions) {
      final type =
          t.type == TransactionType.income ? context.t('income') : context.t('expense');
      final date = DateFormat('yyyy-MM-dd').format(t.date);
      final amount =
          (t.type == TransactionType.expense ? '-' : '') +
              t.amount.toStringAsFixed(2);
      sheet.appendRow([
        xl.TextCellValue(date),
        xl.TextCellValue(type),
        xl.TextCellValue(categoryNames[t.categoryId] ?? t.categoryId),
        xl.TextCellValue('$currency $amount'),
        xl.TextCellValue(t.note ?? '?'),
      ]);
    }

    final bytes = excel.encode();
    return bytes ?? <int>[];
  }

  Future<void> _downloadTemplate(String templateId) async {
    try {
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileBase = _templateFileBase(templateId);
      final templateTitle = _templateTitle(templateId);
      late final File file;

      if (_selectedFormat == 'PDF') {
        final pdf = _buildTemplatePdf(templateId, templateTitle);
        file = File('${dir.path}/${fileBase}_$stamp.pdf');
        await file.writeAsBytes(await pdf.save());
      } else if (_selectedFormat == 'CSV') {
        final csv = _buildTemplateCsv(templateId);
        file = File('${dir.path}/${fileBase}_$stamp.csv');
        await file.writeAsString(csv);
      } else if (_selectedFormat == 'Excel') {
        final bytes = _buildTemplateExcel(templateId);
        file = File('${dir.path}/${fileBase}_$stamp.xlsx');
        await file.writeAsBytes(bytes, flush: true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('unsupported_template_format'))),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t('template_saved', params: {
              'file': file.path.split('/').last,
            }),
          ),
          action: SnackBarAction(
            label: context.t('share'),
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  files: [XFile(file.path)],
                  text: context.t('template_share_text', params: {
                    'name': templateTitle,
                  }),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t('template_generation_failed', params: {'error': '$e'}),
          ),
        ),
      );
    }
  }

  String _templateTitle(String templateId) {
    switch (templateId) {
      case 'monthly_summary':
        return context.t('monthly_summary');
      case 'tax_report':
        return context.t('tax_report');
      case 'investment_portfolio':
        return context.t('investment_portfolio');
      case 'debt_summary':
        return context.t('debt_summary');
      default:
        return templateId;
    }
  }

  String _templateFileBase(String template) {
    return template.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  pw.Document _buildTemplatePdf(String templateId, String templateTitle) {
    final pdf = pw.Document();
    final rows = _templateRows(templateId);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Text(
            context.t('template_title', params: {'name': templateTitle}),
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            context.t('generated_on', params: {
              'time': DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now()),
            }),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            context.t('replace_sample_values'),
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: rows.first,
            data: rows.skip(1).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    return pdf;
  }

  String _buildTemplateCsv(String templateId) {
    final rows = _templateRows(templateId);
    return const ListToCsvConverter().convert(rows);
  }

  List<int> _buildTemplateExcel(String templateId) {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Template'];
    final rows = _templateRows(templateId);

    for (final row in rows) {
      sheet.appendRow(row.map(xl.TextCellValue.new).toList());
    }

    return excel.encode() ?? <int>[];
  }

  List<List<String>> _templateRows(String templateId) {
    switch (templateId) {
      case 'monthly_summary':
        return [
          [
            context.t('month'),
            context.t('income'),
            context.t('expense'),
            context.t('net_savings'),
            context.t('notes'),
          ],
          ['2026-02', '0', '0', '0', ''],
        ];
      case 'tax_report':
        return [
          [
            context.t('date'),
            context.t('type'),
            context.t('category'),
            context.t('amount'),
            context.t('tax_deductible'),
            context.t('notes'),
          ],
          [
            '2026-02-01',
            context.t('expense'),
            context.t('utilities'),
            '0',
            context.t('no'),
            '',
          ],
        ];
      case 'investment_portfolio':
        return [
          [
            context.t('asset'),
            context.t('invested_amount'),
            context.t('current_value'),
            context.t('return_percent'),
            context.t('notes'),
          ],
          [context.t('sample_asset'), '0', '0', '0', ''],
        ];
      case 'debt_summary':
        return [
          [
            context.t('person'),
            context.t('type'),
            context.t('total_amount'),
            context.t('paid'),
            context.t('remaining'),
            context.t('due_date'),
          ],
          [
            context.t('sample_name'),
            context.t('borrowed'),
            '0',
            '0',
            '0',
            '2026-12-31',
          ],
        ];
      default:
        return [
          [context.t('field_1'), context.t('field_2'), context.t('field_3')],
          ['', '', ''],
        ];
    }
  }
}

class _BudgetComparisonRow {
  const _BudgetComparisonRow({
    required this.month,
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
    required this.variance,
    required this.utilization,
  });

  final String month;
  final String category;
  final double budgetAmount;
  final double spentAmount;
  final double variance;
  final double utilization;
}




