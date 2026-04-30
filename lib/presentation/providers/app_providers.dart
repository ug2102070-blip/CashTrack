import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive/hive.dart'; // Hive এর জন্য ইমপোর্ট প্রয়োজন
// আপনার প্রজেক্টের পাথ অনুযায়ী নিচের ইমপোর্টগুলো চেক করে নিবেন
// import '../../core/constants/storage_keys.dart';

import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/debt_repository.dart';
import '../../data/repositories/asset_repository.dart';
import '../../data/repositories/investment_repository.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/account_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/asset_model.dart';
import '../../data/models/investment_model.dart';
import '../../core/utils/logger.dart';
import '../../services/auth_service.dart';

// ==========================================
// 1. REPOSITORY PROVIDERS
// এগুলো repository instance provide করে
// ==========================================

/// Transaction Repository Provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

/// Category Repository Provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

/// Account Repository Provider
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

/// Budget Repository Provider
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

/// Goal Repository Provider
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

/// Debt Repository Provider
final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepository();
});

/// Asset Repository Provider
final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository();
});

/// Investment Repository Provider
final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  return InvestmentRepository();
});

// ==========================================
// 2. TRANSACTION PROVIDERS
// Transaction CRUD operations এর জন্য
// ==========================================

/// All Transactions Provider - StateNotifier দিয়ে state manage করে
final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<TransactionModel>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionsNotifier(repository);
});

/// TransactionsNotifier - Transaction state manage করে
class TransactionsNotifier extends StateNotifier<List<TransactionModel>> {
  final TransactionRepository _repository;

  TransactionsNotifier(this._repository) : super([]) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _repository.init();
    if (!mounted) return;
    loadTransactions();
  }

  /// Load all transactions from database
  void loadTransactions() {
    state = _repository.getAllTransactions();
  }

  /// Add new transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    await _repository.init();
    AppLogger.d('✅ Adding transaction: ${transaction.amount}');
    await _repository.addTransaction(transaction);
    loadTransactions();
    AppLogger.d('✅ Total transactions: ${state.length}');
  }

  /// Update existing transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _repository.init();
    await _repository.updateTransaction(transaction);
    loadTransactions();
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    await _repository.init();
    await _repository.deleteTransaction(id);
    loadTransactions();
  }

  /// Get recent transactions (limit)
  List<TransactionModel> getRecentTransactions({int limit = 10}) {
    return _repository.getRecentTransactions(limit: limit);
  }

  /// Get transactions by type
  List<TransactionModel> getByType(TransactionType type) {
    return _repository.getTransactionsByType(type);
  }

  /// Get transactions by date range
  List<TransactionModel> getByDateRange(DateTime start, DateTime end) {
    return _repository.getTransactionsByDateRange(start, end);
  }
}

// ==========================================
// 3. CATEGORY PROVIDERS
// Category management এর জন্য
// ==========================================

/// All Categories Provider
final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<CategoryModel>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoriesNotifier(repository);
});

/// CategoriesNotifier
class CategoriesNotifier extends StateNotifier<List<CategoryModel>> {
  final CategoryRepository _repository;

  CategoriesNotifier(this._repository) : super([]) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _repository.init();
    if (!mounted) return;
    loadCategories();
  }

  void loadCategories() {
    state = _repository.getAllCategories();
  }

  List<CategoryModel> getExpenseCategories() {
    return _repository.getExpenseCategories();
  }

  List<CategoryModel> getIncomeCategories() {
    return _repository.getIncomeCategories();
  }

  CategoryModel? getCategoryById(String id) {
    return _repository.getCategoryById(id);
  }

  Future<void> addCategory(CategoryModel category) async {
    await _repository.init();
    await _repository.addCategory(category);
    loadCategories();
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _repository.init();
    await _repository.updateCategory(category);
    loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.init();
    await _repository.deleteCategory(id);
    loadCategories();
  }
}

// ==========================================
// 4. ACCOUNT PROVIDERS
// Account management এর জন্য
// ==========================================

/// All Accounts Provider
final accountsProvider =
    StateNotifierProvider<AccountsNotifier, List<AccountModel>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return AccountsNotifier(repository);
});

/// AccountsNotifier
class AccountsNotifier extends StateNotifier<List<AccountModel>> {
  final AccountRepository _repository;

  AccountsNotifier(this._repository) : super([]) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _repository.init();
    if (!mounted) return;
    loadAccounts();
  }

  void loadAccounts() {
    state = _repository.getAllAccounts();
  }

  AccountModel? getAccountById(String id) {
    return _repository.getAccountById(id);
  }

  Future<void> addAccount(AccountModel account) async {
    await _repository.init();
    await _repository.addAccount(account);
    loadAccounts();
  }

  Future<void> updateAccount(AccountModel account) async {
    await _repository.init();
    await _repository.updateAccount(account);
    loadAccounts();
  }

  Future<void> updateBalance(String accountId, double newBalance) async {
    await _repository.init();
    await _repository.updateBalance(accountId, newBalance);
    loadAccounts();
  }

  Future<void> deleteAccount(String id) async {
    await _repository.init();
    await _repository.deleteAccount(id);
    loadAccounts();
  }

  double getTotalBalance() {
    return _repository.getTotalBalance();
  }
}

// ==========================================
// 5. BUDGET PROVIDERS
// Budget management এর জন্য
// ==========================================

/// All Budgets Provider
final budgetsProvider =
    StateNotifierProvider<BudgetsNotifier, List<BudgetModel>>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return BudgetsNotifier(repository);
});

/// BudgetsNotifier
class BudgetsNotifier extends StateNotifier<List<BudgetModel>> {
  final BudgetRepository _repository;
  String? _lastRolloverMonthKey;
  String? _rolloverInFlightForMonth;

  BudgetsNotifier(this._repository) : super([]) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _repository.init();
    if (!mounted) return;
    loadBudgets();
  }

  void loadBudgets() {
    state = _repository.getAllBudgets();
  }

  List<BudgetModel> getBudgetsForCurrentMonth() {
    return _repository.getBudgetsForMonth(DateTime.now());
  }

  List<BudgetModel> getBudgetsForMonth(DateTime month) {
    return _repository.getBudgetsForMonth(month);
  }

  BudgetModel? getBudgetByCategory(String categoryId, DateTime month) {
    try {
      return _repository.getBudgetByCategory(categoryId, month);
    } catch (e) {
      return null;
    }
  }

  Future<void> addBudget(BudgetModel budget) async {
    await _repository.addBudget(budget);
    loadBudgets();
  }

  Future<void> updateBudget(BudgetModel budget) async {
    await _repository.updateBudget(budget);
    loadBudgets();
  }

  Future<void> updateSpent(String budgetId, double newSpent) async {
    await _repository.updateSpent(budgetId, newSpent);
    loadBudgets();
  }

  Future<void> deleteBudget(String id) async {
    await _repository.deleteBudget(id);
    loadBudgets();
  }

  Future<void> ensureMonthlyRollover({
    required DateTime targetMonth,
    required bool enabled,
  }) async {
    if (!enabled) {
      _lastRolloverMonthKey = null;
      return;
    }

    final month = DateTime(targetMonth.year, targetMonth.month, 1);
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    if (_lastRolloverMonthKey == key || _rolloverInFlightForMonth == key) {
      _logRolloverDebug('skip: already handled/in-flight for $key');
      return;
    }

    _rolloverInFlightForMonth = key;
    try {
      _logRolloverDebug('start: $key');
      await applyMonthlyRollover(month);
      _lastRolloverMonthKey = key;
      _logRolloverDebug('done: $key');
    } finally {
      if (_rolloverInFlightForMonth == key) {
        _rolloverInFlightForMonth = null;
      }
    }
  }

  Future<void> applyMonthlyRollover(DateTime targetMonth) async {
    final month = DateTime(targetMonth.year, targetMonth.month, 1);
    final previousMonth = DateTime(month.year, month.month - 1, 1);
    final now = DateTime.now();
    var createdCount = 0;
    var updatedCount = 0;

    final previousBudgets = getBudgetsForMonth(previousMonth);
    for (final previous in previousBudgets) {
      final carryAmount =
          (previous.amount - previous.spent).clamp(0.0, previous.amount);
      if (carryAmount <= 0) continue;

      final current = getBudgetByCategory(previous.categoryId, month);
      if (current == null) {
        await addBudget(
          BudgetModel(
            id: 'budget_${month.year}_${month.month}_${previous.categoryId}_${DateTime.now().millisecondsSinceEpoch}',
            categoryId: previous.categoryId,
            amount: carryAmount,
            month: month,
            spent: 0,
            rollover: true,
            rolledAmount: carryAmount,
            createdAt: now,
            updatedAt: now,
          ),
        );
        createdCount++;
        continue;
      }

      final delta = carryAmount - current.rolledAmount;
      if (delta == 0) continue;

      final nextAmount = (current.amount + delta).clamp(0.0, double.infinity);
      await updateBudget(
        current.copyWith(
          amount: nextAmount,
          rollover: true,
          rolledAmount: carryAmount,
          updatedAt: now,
        ),
      );
      updatedCount++;
    }

    _logRolloverDebug(
      'month ${month.year}-${month.month.toString().padLeft(2, '0')}: '
      'created=$createdCount, updated=$updatedCount',
    );
  }

  void _logRolloverDebug(String message) {
    if (!kDebugMode) return;
    AppLogger.i('Budget rollover: $message');
  }
}

// ==========================================
// 6. GOAL PROVIDERS
// Savings goal management এর জন্য
// ==========================================

/// All Goals Provider
final goalsProvider =
    StateNotifierProvider<GoalsNotifier, List<GoalModel>>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GoalsNotifier(repository);
});

/// GoalsNotifier
class GoalsNotifier extends StateNotifier<List<GoalModel>> {
  final GoalRepository _repository;

  GoalsNotifier(this._repository) : super([]) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _repository.init();
    if (!mounted) return;
    loadGoals();
  }

  void loadGoals() {
    state = _repository.getAllGoals();
  }

  List<GoalModel> getActiveGoals() {
    return _repository.getActiveGoals();
  }

  GoalModel? getGoalById(String id) {
    return _repository.getGoalById(id);
  }

  Future<void> addGoal(GoalModel goal) async {
    await _repository.init();
    await _repository.addGoal(goal);
    loadGoals();
  }

  Future<void> updateGoal(GoalModel goal) async {
    await _repository.init();
    await _repository.updateGoal(goal);
    loadGoals();
  }

  Future<void> updateProgress(String goalId, double newAmount) async {
    await _repository.init();
    await _repository.updateProgress(goalId, newAmount);
    loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    await _repository.init();
    await _repository.deleteGoal(id);
    loadGoals();
  }
}

// ==========================================
// 7. DEBT PROVIDERS
// Debt/Loan management এর জন্য
// ==========================================

/// All Debts Provider
final debtsProvider =
    StateNotifierProvider<DebtsNotifier, List<DebtModel>>((ref) {
  final repository = ref.watch(debtRepositoryProvider);
  return DebtsNotifier(repository);
});

/// DebtsNotifier
class DebtsNotifier extends StateNotifier<List<DebtModel>> {
  final DebtRepository _repository;

  DebtsNotifier(this._repository) : super([]) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _repository.init();
    if (!mounted) return;
    loadDebts();
  }

  void loadDebts() {
    state = _repository.getAllDebts();
  }

  List<DebtModel> getActiveDebts() {
    return _repository.getActiveDebts();
  }

  List<DebtModel> getLentMoney() {
    return _repository.getLentMoney();
  }

  List<DebtModel> getBorrowedMoney() {
    return _repository.getBorrowedMoney();
  }

  Future<void> addDebt(DebtModel debt) async {
    await _repository.init();
    await _repository.addDebt(debt);
    loadDebts();
  }

  Future<void> updateDebt(DebtModel debt) async {
    await _repository.init();
    await _repository.updateDebt(debt);
    loadDebts();
  }

  Future<void> updatePayment(String debtId, double paidAmount) async {
    await _repository.init();
    await _repository.updatePayment(debtId, paidAmount);
    loadDebts();
  }

  Future<void> deleteDebt(String id) async {
    await _repository.init();
    await _repository.deleteDebt(id);
    loadDebts();
  }
}

// ==========================================
// 8. ASSET PROVIDERS
// Asset management এর জন্য
// ==========================================

/// All Assets Provider
final assetsProvider =
    StateNotifierProvider<AssetsNotifier, List<AssetModel>>((ref) {
  final repository = ref.watch(assetRepositoryProvider);
  return AssetsNotifier(repository);
});

/// AssetsNotifier
class AssetsNotifier extends StateNotifier<List<AssetModel>> {
  final AssetRepository _repository;

  AssetsNotifier(this._repository) : super([]) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _repository.init();
    if (!mounted) return;
    loadAssets();
  }

  void loadAssets() {
    state = _repository.getAllAssets();
  }

  AssetModel? getAssetById(String id) {
    return _repository.getAssetById(id);
  }

  Future<void> addAsset(AssetModel asset) async {
    await _repository.init();
    await _repository.addAsset(asset);
    loadAssets();
  }

  Future<void> updateAsset(AssetModel asset) async {
    await _repository.init();
    await _repository.updateAsset(asset);
    loadAssets();
  }

  Future<void> updateValue(String assetId, double newValue) async {
    await _repository.init();
    await _repository.updateValue(assetId, newValue);
    loadAssets();
  }

  Future<void> deleteAsset(String id) async {
    await _repository.init();
    await _repository.deleteAsset(id);
    loadAssets();
  }

  double getTotalAssetValue() {
    return _repository.getTotalAssetValue();
  }
}

// ==========================================
// 9. INVESTMENT PROVIDERS
// Investment management এর জন্য
// ==========================================

/// All Investments Provider
final investmentsProvider =
    StateNotifierProvider<InvestmentsNotifier, List<InvestmentModel>>((ref) {
  final repository = ref.watch(investmentRepositoryProvider);
  return InvestmentsNotifier(repository);
});

/// InvestmentsNotifier
class InvestmentsNotifier extends StateNotifier<List<InvestmentModel>> {
  final InvestmentRepository _repository;

  InvestmentsNotifier(this._repository) : super([]) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _repository.init();
    if (!mounted) return;
    loadInvestments();
  }

  void loadInvestments() {
    state = _repository.getAllInvestments();
  }

  List<InvestmentModel> getByType(InvestmentType type) {
    return _repository.getInvestmentsByType(type);
  }

  Future<void> addInvestment(InvestmentModel investment) async {
    await _repository.init();
    await _repository.addInvestment(investment);
    loadInvestments();
  }

  Future<void> updateInvestment(InvestmentModel investment) async {
    await _repository.init();
    await _repository.updateInvestment(investment);
    loadInvestments();
  }

  Future<void> updateValue(String investmentId, double newValue) async {
    await _repository.init();
    await _repository.updateCurrentValue(investmentId, newValue);
    loadInvestments();
  }

  Future<void> deleteInvestment(String id) async {
    await _repository.init();
    await _repository.deleteInvestment(id);
    loadInvestments();
  }

  double getTotalInvested() {
    return _repository.getTotalInvested();
  }

  double getTotalCurrentValue() {
    return _repository.getTotalCurrentValue();
  }

  double getTotalReturns() {
    return _repository.getTotalReturns();
  }

  double getReturnPercentage() {
    return _repository.getReturnPercentage();
  }
}

// ==========================================
// 10. DASHBOARD SUMMARY PROVIDER
// Dashboard এর জন্য aggregated data
// ==========================================

/// Dashboard Summary - Read-only computed data
final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final accounts = ref.watch(accountsProvider);
  final sortedTransactions = [...transactions]
    ..sort((a, b) => b.date.compareTo(a.date));

  final totalIncome = transactions
      .where((t) => t.type == TransactionType.income)
      .fold<double>(0, (sum, t) => sum + t.amount);
  final totalExpense = transactions
      .where((t) => t.type == TransactionType.expense)
      .fold<double>(0, (sum, t) => sum + t.amount);
  final totalBalance =
      accounts.fold<double>(0, (sum, account) => sum + account.balance);

  return DashboardSummary(
    totalBalance: totalBalance,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    recentTransactions: sortedTransactions.take(5).toList(),
  );
});

/// Dashboard Summary Data Class
class DashboardSummary {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final List<TransactionModel> recentTransactions;

  DashboardSummary({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.recentTransactions,
  });

  /// Net savings this month
  double get netSavings => totalIncome - totalExpense;

  /// Expense percentage
  double get expensePercentage {
    if (totalIncome == 0) return 0;
    return (totalExpense / totalIncome) * 100;
  }

  /// Savings rate
  double get savingsRate {
    if (totalIncome == 0) return 0;
    return (netSavings / totalIncome) * 100;
  }
}

// ==========================================
// 11. ANALYTICS PROVIDERS
// Analytics screen এর জন্য
// ==========================================

/// Monthly Analytics Provider
final monthlyAnalyticsProvider =
    Provider.family<MonthlyAnalytics, DateTime>((ref, month) {
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  ref.watch(
      transactionsProvider); // ensure analytics rebuilds when transactions change

  final startOfMonth = DateTime(month.year, month.month, 1);
  final endOfMonth = DateTime(month.year, month.month + 1, 0);

  final transactions =
      transactionRepo.getTransactionsByDateRange(startOfMonth, endOfMonth);

  return MonthlyAnalytics(
    month: month,
    transactions: transactions,
    totalIncome:
        transactionRepo.getTotalIncome(start: startOfMonth, end: endOfMonth),
    totalExpense:
        transactionRepo.getTotalExpense(start: startOfMonth, end: endOfMonth),
  );
});

/// Monthly Analytics Data Class
class MonthlyAnalytics {
  final DateTime month;
  final List<TransactionModel> transactions;
  final double totalIncome;
  final double totalExpense;

  MonthlyAnalytics({
    required this.month,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
  });

  double get netSavings => totalIncome - totalExpense;

  /// Group transactions by category
  Map<String, double> getCategoryBreakdown(TransactionType type) {
    final Map<String, double> breakdown = {};

    for (var transaction in transactions.where((t) => t.type == type)) {
      breakdown[transaction.categoryId] =
          (breakdown[transaction.categoryId] ?? 0) + transaction.amount;
    }

    return breakdown;
  }
}
// ==========================================
// 12. SETTINGS PROVIDER
// App Settings (Dark Mode, Currency, Accent Color, etc.) manage করার জন্য
// ==========================================

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  SettingsNotifier()
      : super({
          'darkMode': false,
          'currency': '\u09F3',
          'smsTrack': false,
          'smsMode': 'ask',
          'language': 'en',
          'accentColor': 0xFF2D7A7B,
          'compactMode': false,
          'notifications': true,
          'budgetAlerts': true,
          'weeklyReport': false,
          'biometricLock': false,
          'screenshotProtection': false,
          'dailyReminderTime': null,
          'autoLockMinutes': 5,
          'appLockPinSet': false,
          'monthStartDay': 1,
          'rolloverBudget': false, // ডিফল্ট ভ্যালু যোগ করা হলো
          'hideAmounts': false,
          'voiceTransactionInput': false,
          'receiptImageAttachment': false,
        }) {
    if (Hive.isBoxOpen('settingsBox')) {
      _loadSettingsSync();
    } else {
      _loadSettings();
    }
  }

  Future<Box> _getBox() async {
    if (Hive.isBoxOpen('settingsBox')) {
      return Hive.box('settingsBox');
    }
    return Hive.openBox('settingsBox');
  }

  void _loadSettingsSync() {
    final box = Hive.box('settingsBox');
    state = {
      'darkMode': box.get('darkMode', defaultValue: false),
      'currency': _normalizeCurrency(
          box.get('currency', defaultValue: '\u09F3') as String?),
      'smsTrack': box.get('smsTrack', defaultValue: false),
      'smsMode': box.get('smsMode', defaultValue: 'ask'),
      'language': box.get('language', defaultValue: 'en'),
      'accentColor': box.get('accentColor', defaultValue: 0xFF2D7A7B),
      'compactMode': box.get('compactMode', defaultValue: false),
      'notifications': box.get('notifications', defaultValue: true),
      'budgetAlerts': box.get('budgetAlerts', defaultValue: true),
      'weeklyReport': box.get('weeklyReport', defaultValue: false),
      'biometricLock': box.get('biometricLock', defaultValue: false),
      'screenshotProtection':
          box.get('screenshotProtection', defaultValue: false),
      'dailyReminderTime': box.get('dailyReminderTime'),
      'autoLockMinutes': box.get('autoLockMinutes', defaultValue: 5),
      'appLockPinSet': box.get('appLockPinSet', defaultValue: false),
      'monthStartDay': box.get('monthStartDay', defaultValue: 1),
      'rolloverBudget': box.get('rolloverBudget', defaultValue: false),
      'hideAmounts': box.get('hideAmounts', defaultValue: false),
      'voiceTransactionInput':
          box.get('voiceTransactionInput', defaultValue: false),
      'receiptImageAttachment':
          box.get('receiptImageAttachment', defaultValue: false),
    };
  }

  /// অ্যাপ চালু হওয়ার সময় সেভ করা সেটিংস লোড করে
  Future<void> _loadSettings() async {
    final box = await _getBox();
    state = {
      'darkMode': box.get('darkMode', defaultValue: false),
      'currency': _normalizeCurrency(
          box.get('currency', defaultValue: '\u09F3') as String?),
      'smsTrack': box.get('smsTrack', defaultValue: false),
      'smsMode': box.get('smsMode', defaultValue: 'ask'),
      'language': box.get('language', defaultValue: 'en'),
      'accentColor': box.get('accentColor', defaultValue: 0xFF2D7A7B),
      'compactMode': box.get('compactMode', defaultValue: false),
      'notifications': box.get('notifications', defaultValue: true),
      'budgetAlerts': box.get('budgetAlerts', defaultValue: true),
      'weeklyReport': box.get('weeklyReport', defaultValue: false),
      'biometricLock': box.get('biometricLock', defaultValue: false),
      'screenshotProtection':
          box.get('screenshotProtection', defaultValue: false),
      'dailyReminderTime': box.get('dailyReminderTime'),
      'autoLockMinutes': box.get('autoLockMinutes', defaultValue: 5),
      'appLockPinSet': box.get('appLockPinSet', defaultValue: false),
      'monthStartDay': box.get('monthStartDay', defaultValue: 1),
      'rolloverBudget':
          box.get('rolloverBudget', defaultValue: false), // লোড লজিক
      'hideAmounts': box.get('hideAmounts', defaultValue: false),
      'voiceTransactionInput':
          box.get('voiceTransactionInput', defaultValue: false),
      'receiptImageAttachment':
          box.get('receiptImageAttachment', defaultValue: false),
    };
  }

  /// Rollover Budget পরিবর্তন করার জন্য (আপনার এরর দূর করতে এটি প্রয়োজন)
  Future<void> updateRolloverBudget(bool value) async {
    final box = await _getBox();
    await box.put('rolloverBudget', value);
    state = {...state, 'rolloverBudget': value};
  }

  /// Accent Color পরিবর্তন করার জন্য
  Future<void> updateAccentColor(int colorValue) async {
    final box = await _getBox();
    await box.put('accentColor', colorValue);
    state = {...state, 'accentColor': colorValue};
  }

  /// Dark Mode পরিবর্তন করার জন্য
  Future<void> toggleDarkMode(bool value) async {
    final box = await _getBox();
    await box.put('darkMode', value);
    state = {...state, 'darkMode': value};
  }

  /// কারেন্সি (Currency) পরিবর্তন করার জন্য
  Future<void> updateCurrency(String currency) async {
    final box = await _getBox();
    await box.put('currency', currency);
    state = {...state, 'currency': currency};
  }

  String _normalizeCurrency(String? value) {
    if (value == null || value.isEmpty) return '\u09F3';
    if (value == '?') return '\u09F3';
    if (value == 'à§³') return '\u09F3';
    return value;
  }

  /// SMS ট্র্যাকিং অন/অফ করার জন্য
  Future<void> toggleSmsTrack(bool value) async {
    final box = await _getBox();
    await box.put('smsTrack', value);
    state = {...state, 'smsTrack': value};
  }

  /// ভাষা পরিবর্তন করার জন্য

  /// SMS auto-import mode (ask / silent / daily_summary)
  Future<void> updateSmsMode(String mode) async {
    final box = await _getBox();
    await box.put('smsMode', mode);
    state = {...state, 'smsMode': mode};
  }

  Future<void> updateLanguage(String langCode) async {
    final box = await _getBox();
    await box.put('language', langCode);
    state = {...state, 'language': langCode};
  }

  Future<void> toggleHideAmounts(bool value) async {
    final box = await _getBox();
    await box.put('hideAmounts', value);
    state = {...state, 'hideAmounts': value};
  }

  // Backward-compatible wrappers
  Future<void> updateDarkMode(bool value) async {
    await toggleDarkMode(value);
  }

  Future<void> updateHideAmounts(bool value) async {
    await toggleHideAmounts(value);
  }

  Future<void> updateSmsTrack(bool value) async {
    await toggleSmsTrack(value);
  }

  Future<void> update(String key, dynamic value) async {
    final box = await _getBox();
    await box.put(key, value);
    state = {...state, key: value};
  }
} //===================================
// USAGE EXAMPLES (Comment করে রাখা আছে)
// ==========================================

/*
// কিভাবে ব্যবহার করবেন:

// 1. Screen এ import করুন:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

// 2. ConsumerWidget/ConsumerStatefulWidget ব্যবহার করুন:
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // 3. Data read করুন:
    final transactions = ref.watch(transactionsProvider);
    final summary = ref.watch(dashboardSummaryProvider);

    // 4. Data modify করুন:
    final transactionNotifier = ref.read(transactionsProvider.notifier);
    transactionNotifier.addTransaction(myTransaction);

    return YourWidget();
  }
}

// ==========================================
// 13. USER PROFILE PROVIDER
// Profile data (name/email/phone/address) manage করার জন্য
// ==========================================

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, Map<String, String>>((ref) {
  return UserProfileNotifier();
});

class UserProfileNotifier extends StateNotifier<Map<String, String>> {
  UserProfileNotifier()
      : super({
          'fullName': '',
          'email': '',
          'phone': '',
          'address': '',
        }) {
    _loadProfile();
  }

  static const _boxName = 'settingsBox';
  static const _kFullName = 'profile_full_name';
  static const _kEmail = 'profile_email';
  static const _kPhone = 'profile_phone';
  static const _kAddress = 'profile_address';

  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return Hive.openBox(_boxName);
  }

  Future<void> _loadProfile() async {
    final box = await _getBox();
    final user = AuthService().currentUser;

    final fullName = (box.get(_kFullName) as String?)?.trim();
    final email = (box.get(_kEmail) as String?)?.trim();
    final phone = (box.get(_kPhone) as String?)?.trim();
    final address = (box.get(_kAddress) as String?)?.trim();

    state = {
      'fullName': (fullName == null || fullName.isEmpty)
          ? ((user?.displayName?.trim().isNotEmpty ?? false)
              ? user!.displayName!.trim()
              : '')
          : fullName,
      'email': (email == null || email.isEmpty)
          ? (user?.email?.trim() ?? '')
          : email,
      'phone': phone ?? '',
      'address': address ?? '',
    };
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    required String address,
  }) async {
    final box = await _getBox();
    await box.put(_kFullName, fullName);
    await box.put(_kEmail, email);
    await box.put(_kPhone, phone);
    await box.put(_kAddress, address);
    state = {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
    };
  }
}

*/

// ==========================================
// 13. USER PROFILE PROVIDER
// ==========================================
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, Map<String, String>>((ref) {
  return UserProfileNotifier();
});

class UserProfileNotifier extends StateNotifier<Map<String, String>> {
  UserProfileNotifier()
      : super({
          'fullName': '',
          'email': '',
          'phone': '',
          'address': '',
          'occupation': '',
          'bio': '',
          'dob': '',
          'photoBase64': '',
        }) {
    _loadProfile();
  }

  static const _boxName = 'settingsBox';
  static const _kFullName = 'profile_full_name';
  static const _kEmail = 'profile_email';
  static const _kPhone = 'profile_phone';
  static const _kAddress = 'profile_address';
  static const _kOccupation = 'profile_occupation';
  static const _kBio = 'profile_bio';
  static const _kDob = 'profile_dob';
  static const _kPhotoBase64 = 'profile_photo_base64';

  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return Hive.openBox(_boxName);
  }

  Future<void> _loadProfile() async {
    final box = await _getBox();
    final user = AuthService().currentUser;

    final fullName = (box.get(_kFullName) as String?)?.trim();
    final email = (box.get(_kEmail) as String?)?.trim();
    final phone = (box.get(_kPhone) as String?)?.trim();
    final address = (box.get(_kAddress) as String?)?.trim();
    final occupation = (box.get(_kOccupation) as String?)?.trim();
    final bio = (box.get(_kBio) as String?)?.trim();
    final dob = (box.get(_kDob) as String?)?.trim();
    final photoBase64 = (box.get(_kPhotoBase64) as String?)?.trim();

    state = {
      'fullName': (fullName == null || fullName.isEmpty)
          ? ((user?.displayName?.trim().isNotEmpty ?? false)
              ? user!.displayName!.trim()
              : '')
          : fullName,
      'email': (email == null || email.isEmpty)
          ? (user?.email?.trim() ?? '')
          : email,
      'phone': phone ?? '',
      'address': address ?? '',
      'occupation': occupation ?? '',
      'bio': bio ?? '',
      'dob': dob ?? '',
      'photoBase64': photoBase64 ?? '',
    };
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String occupation,
    required String bio,
    required String dob,
    String? photoBase64,
  }) async {
    final box = await _getBox();
    await box.put(_kFullName, fullName);
    await box.put(_kEmail, email);
    await box.put(_kPhone, phone);
    await box.put(_kAddress, address);
    await box.put(_kOccupation, occupation);
    await box.put(_kBio, bio);
    await box.put(_kDob, dob);
    if (photoBase64 != null) {
      await box.put(_kPhotoBase64, photoBase64);
    }
    state = {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'occupation': occupation,
      'bio': bio,
      'dob': dob,
      'photoBase64': photoBase64 ?? (state['photoBase64'] ?? ''),
    };
  }

  Future<void> updateProfilePhoto(String photoBase64) async {
    final box = await _getBox();
    await box.put(_kPhotoBase64, photoBase64);
    state = {...state, 'photoBase64': photoBase64};
  }

  Future<void> clearProfilePhoto() async {
    final box = await _getBox();
    await box.put(_kPhotoBase64, '');
    state = {...state, 'photoBase64': ''};
  }
}
