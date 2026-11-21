import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive/hive.dart'; // Hive এর জন্য ইমপোর্ট প্রয়োজন
import 'package:firebase_auth/firebase_auth.dart' show User;
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
import '../../data/repositories/split_expense_repository.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/account_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/asset_model.dart';
import '../../data/models/investment_model.dart';
import '../../data/models/split_expense_model.dart';
import '../../core/utils/logger.dart';
import '../../services/auth_service.dart';
import '../../services/local_user_data_service.dart';
import '../../services/profile_store.dart';
import 'auth_providers.dart';

// ==========================================
// 0. AUTH STATE PROVIDER
// Login/logout হলে সব providers নতুন userId দিয়ে reload হবে
// ==========================================

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

/// Split Expense Repository Provider
final splitExpenseRepositoryProvider = Provider<SplitExpenseRepository>((ref) {
  return SplitExpenseRepository();
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

/// All Transactions Provider - auth change হলে নতুন userId দিয়ে reload হয়
final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<TransactionModel>>((ref) {
  // Watch auth state — when user changes, this provider rebuilds with new userId
  ref.watch(authUserIdProvider);
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

/// All Accounts Provider — auth change হলে নতুন userId দিয়ে reload হয়
final accountsProvider =
    StateNotifierProvider<AccountsNotifier, List<AccountModel>>((ref) {
  // Watch auth state — when user changes, this provider rebuilds
  ref.watch(authUserIdProvider);
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

  Future<void> updateBalance(String accountId, int newBalance) async {
    await _repository.init();
    await _repository.updateBalance(accountId, newBalance);
    loadAccounts();
  }

  Future<void> deleteAccount(String id) async {
    await _repository.init();
    await _repository.deleteAccount(id);
    loadAccounts();
  }

  int getTotalBalance() {
    return _repository.getTotalBalance();
  }
}

/// All Split Groups Provider
final splitGroupsProvider =
    StateNotifierProvider<SplitGroupsNotifier, List<SplitGroup>>((ref) {
  final repository = ref.watch(splitExpenseRepositoryProvider);
  return SplitGroupsNotifier(repository);
});

class SplitGroupsNotifier extends StateNotifier<List<SplitGroup>> {
  final SplitExpenseRepository _repository;

  SplitGroupsNotifier(this._repository) : super([]) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _repository.init();
    if (!mounted) return;
    loadGroups();
  }

  void loadGroups() {
    state = _repository.getAllGroups();
  }

  Future<void> addGroup(SplitGroup group) async {
    await _repository.init();
    await _repository.addGroup(group);
    loadGroups();
  }

  Future<void> updateGroup(SplitGroup group) async {
    await _repository.init();
    await _repository.updateGroup(group);
    loadGroups();
  }

  Future<void> deleteGroup(String id) async {
    await _repository.init();
    await _repository.deleteGroup(id);
    loadGroups();
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
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  return BudgetsNotifier(repository, transactionRepo);
});

/// BudgetsNotifier
class BudgetsNotifier extends StateNotifier<List<BudgetModel>> {
  final BudgetRepository _repository;
  final TransactionRepository _transactionRepository;
  String? _lastRolloverMonthKey;
  String? _rolloverInFlightForMonth;

  BudgetsNotifier(this._repository, this._transactionRepository) : super([]) {
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
    final previousStart = DateTime(previousMonth.year, previousMonth.month, 1);
    final previousEnd =
        DateTime(previousMonth.year, previousMonth.month + 1, 0, 23, 59, 59);
    final previousTransactions = _transactionRepository
        .getTransactionsByDateRange(previousStart, previousEnd);

    for (final previous in previousBudgets) {
      final spent = previousTransactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.categoryId == previous.categoryId)
          .fold<int>(0, (sum, t) => sum + t.amount);

      final carryAmount = (previous.amount - spent).clamp(0, previous.amount);
      if (carryAmount <= 0) continue;

      final current = getBudgetByCategory(previous.categoryId, month);
      if (current == null) {
        await addBudget(
          BudgetModel(
            id: 'budget_${month.year}_${month.month}_${previous.categoryId}_${DateTime.now().millisecondsSinceEpoch}',
            categoryId: previous.categoryId,
            amount: carryAmount,
            month: month,
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

      int nextAmount = (current.amount + delta).toInt();
      if (nextAmount < 0) nextAmount = 0;
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

  Future<void> updateProgress(String goalId, int newAmount) async {
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

  Future<void> updatePayment(String debtId, int paidAmount) async {
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

  Future<void> updateValue(String assetId, int newValue) async {
    await _repository.init();
    await _repository.updateValue(assetId, newValue);
    loadAssets();
  }

  Future<void> deleteAsset(String id) async {
    await _repository.init();
    await _repository.deleteAsset(id);
    loadAssets();
  }

  int getTotalAssetValue() {
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

  Future<void> updateValue(String investmentId, int newValue) async {
    await _repository.init();
    await _repository.updateCurrentValue(investmentId, newValue);
    loadInvestments();
  }

  Future<void> deleteInvestment(String id) async {
    await _repository.init();
    await _repository.deleteInvestment(id);
    loadInvestments();
  }

  int getTotalInvested() {
    return _repository.getTotalInvested();
  }

  int getTotalCurrentValue() {
    return _repository.getTotalCurrentValue();
  }

  int getTotalReturns() {
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

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  final monthTransactions = transactions.where((t) =>
      !t.isDeleted &&
      !t.date.isBefore(startOfMonth) &&
      !t.date.isAfter(endOfMonth));

  final monthIncome = monthTransactions
      .where((t) => t.type == TransactionType.income)
      .fold<int>(0, (sum, t) => sum + t.amount);
  final monthExpense = monthTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold<int>(0, (sum, t) => sum + t.amount);

  final totalIncome = transactions
      .where((t) => t.type == TransactionType.income && !t.isDeleted)
      .fold<int>(0, (sum, t) => sum + t.amount);
  final totalExpense = transactions
      .where((t) => t.type == TransactionType.expense && !t.isDeleted)
      .fold<int>(0, (sum, t) => sum + t.amount);
  final totalBalance =
      accounts.fold<int>(0, (sum, account) => sum + account.balance);

  return DashboardSummary(
    totalBalance: totalBalance,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    monthIncome: monthIncome,
    monthExpense: monthExpense,
    recentTransactions: sortedTransactions.take(10).toList(),
  );
});

/// Dashboard Summary Data Class
class DashboardSummary {
  final int totalBalance;
  final int totalIncome;
  final int totalExpense;
  final int monthIncome;
  final int monthExpense;
  final List<TransactionModel> recentTransactions;

  DashboardSummary({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    this.monthIncome = 0,
    this.monthExpense = 0,
    required this.recentTransactions,
  });

  /// Net savings this month
  int get netSavings => (monthIncome > 0 || monthExpense > 0)
      ? (monthIncome - monthExpense)
      : (totalIncome - totalExpense);

  /// Expense percentage
  double get expensePercentage {
    final inc =
        (monthIncome > 0 || monthExpense > 0) ? monthIncome : totalIncome;
    final exp =
        (monthIncome > 0 || monthExpense > 0) ? monthExpense : totalExpense;
    if (inc == 0) return 0;
    return (exp / inc) * 100;
  }

  /// Savings rate
  double get savingsRate {
    final inc =
        (monthIncome > 0 || monthExpense > 0) ? monthIncome : totalIncome;
    if (inc == 0) return 0;
    return (netSavings / inc) * 100;
  }
}

// ==========================================
// 11. ANALYTICS PROVIDERS
// Analytics screen এর জন্য
// ==========================================

/// Monthly Analytics Provider
final monthlyAnalyticsProvider =
    Provider.family<MonthlyAnalytics, DateTime>((ref, rawMonth) {
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  ref.watch(
      transactionsProvider); // ensure analytics rebuilds when transactions change

  final month = DateTime(rawMonth.year, rawMonth.month, 1);
  final startOfMonth = DateTime(month.year, month.month, 1);
  final endOfMonth = DateTime(month.year, month.month + 1, 0);

  final transactions =
      transactionRepo.getTransactionsByDateRange(startOfMonth, endOfMonth);

  final prevMonthDate = DateTime(month.year, month.month - 1, 1);
  final prevStart = DateTime(prevMonthDate.year, prevMonthDate.month, 1);
  final prevEnd = DateTime(prevMonthDate.year, prevMonthDate.month + 1, 0);
  final prevIncome =
      transactionRepo.getTotalIncome(start: prevStart, end: prevEnd);
  final prevExpense =
      transactionRepo.getTotalExpense(start: prevStart, end: prevEnd);

  return MonthlyAnalytics(
    month: month,
    transactions: transactions,
    totalIncome:
        transactionRepo.getTotalIncome(start: startOfMonth, end: endOfMonth),
    totalExpense:
        transactionRepo.getTotalExpense(start: startOfMonth, end: endOfMonth),
    previousIncome: prevIncome,
    previousExpense: prevExpense,
  );
});

/// Monthly Analytics Data Class
class MonthlyAnalytics {
  final DateTime month;
  final List<TransactionModel> transactions;
  final int totalIncome;
  final int totalExpense;
  final int previousIncome;
  final int previousExpense;

  MonthlyAnalytics({
    required this.month,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
    this.previousIncome = 0,
    this.previousExpense = 0,
  });

  int get netSavings => totalIncome - totalExpense;

  double get savingsRate =>
      totalIncome > 0 ? (netSavings / totalIncome * 100) : 0.0;

  /// Percentage change in expense compared to previous month:
  /// negative means spending decreased (good!), positive means spending increased.
  double? get expenseChangePercentage {
    if (previousExpense <= 0) return null;
    return ((totalExpense - previousExpense) / previousExpense) * 100;
  }

  /// Percentage change in income compared to previous month
  double? get incomeChangePercentage {
    if (previousIncome <= 0) return null;
    return ((totalIncome - previousIncome) / previousIncome) * 100;
  }

  /// Group transactions by category (excludes deleted)
  Map<String, int> getCategoryBreakdown(TransactionType type) {
    final Map<String, int> breakdown = {};

    for (var transaction
        in transactions.where((t) => t.type == type && !t.isDeleted)) {
      breakdown[transaction.categoryId] =
          (breakdown[transaction.categoryId] ?? 0) + transaction.amount;
    }

    return breakdown;
  }

  /// Group transactions by account (excludes deleted)
  Map<String, int> getAccountBreakdown(TransactionType type) {
    final Map<String, int> breakdown = {};

    for (var transaction
        in transactions.where((t) => t.type == type && !t.isDeleted)) {
      breakdown[transaction.accountId] =
          (breakdown[transaction.accountId] ?? 0) + transaction.amount;
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
          'smsPermissionDialogShown': false,
          'smsMode': 'daily_summary',
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
          'defaultRecurring': false,
          'defaultRecurringType': 'monthly',
          'dailyBudgetLimit': 0,
          'dailyBudgetRollover': false,
          'dailyBudgetStartDate': null,
          'pinnedAccounts': <String>[],
          'pinnedCategories': <String>[],
          'lastCloudBackupAt': null,
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
      'currency':
          _normalizeCurrency(box.get('currency', defaultValue: '৳') as String?),
      'smsTrack': box.get('smsTrack', defaultValue: false),
      'smsPermissionDialogShown':
          box.get('smsPermissionDialogShown', defaultValue: false),
      'smsMode': box.get('smsMode', defaultValue: 'daily_summary'),
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
      'defaultRecurring': box.get('defaultRecurring', defaultValue: false),
      'defaultRecurringType':
          box.get('defaultRecurringType', defaultValue: 'monthly'),
      'dailyBudgetLimit':
          (box.get('dailyBudgetLimit', defaultValue: 0) as num).toInt(),
      'dailyBudgetRollover':
          box.get('dailyBudgetRollover', defaultValue: false),
      'dailyBudgetStartDate': box.get('dailyBudgetStartDate'),
      'lastCloudBackupAt': box.get('lastCloudBackupAt') as String?,
      'pinnedAccounts':
          (box.get('pinnedAccounts', defaultValue: <String>[]) as List<dynamic>)
              .cast<String>(),
      'pinnedCategories': (box.get('pinnedCategories', defaultValue: <String>[])
              as List<dynamic>)
          .cast<String>(),
    };
  }

  /// অ্যাপ চালু হওয়ার সময় সেভ করা সেটিংস লোড করে
  Future<void> _loadSettings() async {
    final box = await _getBox();
    state = {
      'darkMode': box.get('darkMode', defaultValue: false),
      'currency':
          _normalizeCurrency(box.get('currency', defaultValue: '৳') as String?),
      'smsTrack': box.get('smsTrack', defaultValue: false),
      'smsPermissionDialogShown':
          box.get('smsPermissionDialogShown', defaultValue: false),
      'smsMode': box.get('smsMode', defaultValue: 'daily_summary'),
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
      'defaultRecurring': box.get('defaultRecurring', defaultValue: false),
      'defaultRecurringType':
          box.get('defaultRecurringType', defaultValue: 'monthly'),
      'dailyBudgetLimit':
          (box.get('dailyBudgetLimit', defaultValue: 0) as num).toInt(),
      'dailyBudgetRollover':
          box.get('dailyBudgetRollover', defaultValue: false),
      'dailyBudgetStartDate': box.get('dailyBudgetStartDate'),
      'lastCloudBackupAt': box.get('lastCloudBackupAt') as String?,
      'pinnedAccounts':
          (box.get('pinnedAccounts', defaultValue: <String>[]) as List<dynamic>)
              .cast<String>(),
      'pinnedCategories': (box.get('pinnedCategories', defaultValue: <String>[])
              as List<dynamic>)
          .cast<String>(),
    };
  }

  /// Rollover Budget পরিবর্তন করার জন্য (আপনার এরর দূর করতে এটি প্রয়োজন)
  Future<void> updateRolloverBudget(bool value) async {
    final box = await _getBox();
    await box.put('rolloverBudget', value);
    state = {...state, 'rolloverBudget': value};
  }

  Future<void> updateDefaultRecurring(bool value) async {
    final box = await _getBox();
    await box.put('defaultRecurring', value);
    state = {...state, 'defaultRecurring': value};
  }

  Future<void> updateDefaultRecurringType(String value) async {
    final box = await _getBox();
    await box.put('defaultRecurringType', value);
    state = {...state, 'defaultRecurringType': value};
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

  Future<void> updateSmsPermissionDialogShown(bool value) async {
    final box = await _getBox();
    await box.put('smsPermissionDialogShown', value);
    state = {...state, 'smsPermissionDialogShown': value};
  }

  Future<void> update(String key, dynamic value) async {
    final box = await _getBox();
    await box.put(key, value);
    state = {...state, key: value};
  }

  /// Re-reads every setting from Hive (after user data was erased/replaced).
  Future<void> reload() => _loadSettings();

  Future<void> updatePinnedCategories(List<String> pinnedIds) async {
    final box = await _getBox();
    await box.put('pinnedCategories', pinnedIds);
    state = {...state, 'pinnedCategories': pinnedIds};
  }

  Future<void> updatePinnedAccounts(List<String> pinnedIds) async {
    final box = await _getBox();
    await box.put('pinnedAccounts', pinnedIds);
    state = {...state, 'pinnedAccounts': pinnedIds};
  }
}

// ==========================================
// 13. USER PROFILE PROVIDER
// ==========================================
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, Map<String, String>>((ref) {
  return UserProfileNotifier();
});

class UserProfileNotifier extends StateNotifier<Map<String, String>> {
  UserProfileNotifier({ProfileStore? store})
      : _store = store ?? ProfileStore(),
        super(const {
          'fullName': '',
          'email': '',
          'phone': '',
          'dob': '',
          'photoBase64': '',
        }) {
    _loadProfile();
  }

  final ProfileStore _store;

  String? get _uid => AuthService().currentUser?.uid;

  Future<void> _loadProfile() async {
    final user = AuthService().currentUser;
    final uid = _uid;
    await _store.purgeRetiredFields(uid);
    final stored = await _store.read(uid);
    final displayName = user?.displayName?.trim() ?? '';

    state = {
      ...stored,
      'fullName': stored['fullName']!.isNotEmpty
          ? stored['fullName']!
          : displayName,
      // The sign-in email is authoritative for registered users; a locally
      // edited copy must not diverge from the address used for password reset.
      'email': accountEmailOf(user) ?? stored['email']!,
    };
  }

  /// Non-empty sign-in email of a registered (non-anonymous) user, else null.
  static String? accountEmailOf(User? user) {
    if (user == null || user.isAnonymous) return null;
    final email = user.email?.trim();
    return (email == null || email.isEmpty) ? null : email;
  }

  /// Persists a single profile field. Throws [ArgumentError] for unknown keys
  /// and [StateError] when trying to change a sign-in managed email.
  Future<void> updateField(String field, String value) async {
    if (!ProfileStore.storageKeys.containsKey(field)) {
      throw ArgumentError.value(field, 'field', 'Unknown profile field');
    }
    if (field == 'email' &&
        accountEmailOf(AuthService().currentUser) != null) {
      throw StateError('Email is managed by the sign-in account');
    }
    await _store.write(_uid, field, value);
    state = {...state, field: value};
  }

  Future<void> updateProfilePhoto(String photoBase64) =>
      updateField('photoBase64', photoBase64);

  Future<void> clearProfilePhoto() => updateField('photoBase64', '');

  /// Reloads profile data from Hive (call after sign-in to load user-specific data).
  Future<void> reloadProfile() async {
    await _loadProfile();
  }
}

// ==========================================
// LOCAL DATA RELOAD
// ==========================================

/// Keeps in-memory providers in step with Hive when local data is replaced
/// wholesale (account switch erase, cloud pull, restore). Watched once from
/// the app root; has no state of its own.
final localDataReloadProvider = Provider<void>((ref) {
  final sub = LocalUserDataService.instance.changes.listen((_) {
    ref.read(transactionsProvider.notifier).loadTransactions();
    ref.read(categoriesProvider.notifier).loadCategories();
    ref.read(accountsProvider.notifier).loadAccounts();
    ref.read(splitGroupsProvider.notifier).loadGroups();
    ref.read(budgetsProvider.notifier).loadBudgets();
    ref.read(goalsProvider.notifier).loadGoals();
    ref.read(debtsProvider.notifier).loadDebts();
    ref.read(assetsProvider.notifier).loadAssets();
    ref.read(investmentsProvider.notifier).loadInvestments();
    ref.read(settingsProvider.notifier).reload();
    ref.read(userProfileProvider.notifier).reloadProfile();
  });
  ref.onDispose(sub.cancel);
});
