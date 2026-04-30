import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:cashtrack/data/models/account_model.dart';
import 'package:cashtrack/data/models/asset_model.dart';
import 'package:cashtrack/data/models/budget_model.dart';
import 'package:cashtrack/data/models/category_model.dart';
import 'package:cashtrack/data/models/debt_model.dart';
import 'package:cashtrack/data/models/goal_model.dart';
import 'package:cashtrack/data/models/investment_model.dart';
import 'package:cashtrack/data/models/transaction_model.dart';
import 'package:cashtrack/data/models/user_model.dart';
import 'package:cashtrack/data/repositories/account_repository.dart';
import 'package:cashtrack/data/repositories/budget_repository.dart';
import 'package:cashtrack/data/repositories/category_repository.dart';
import 'package:cashtrack/data/repositories/transaction_repository.dart';

bool _hivePathInitialized = false;

/// Registers all Hive type adapters used by the app (same order as [main.dart]).
void registerCashtrackHiveAdapters() {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TransactionModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(TransactionTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(RecurringTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(CategoryModelAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(CategoryTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(AccountModelAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(AccountTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(BudgetModelAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(GoalModelAdapter());
  }
  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(DebtModelAdapter());
  }
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(DebtTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(AssetModelAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(InvestmentModelAdapter());
  }
  if (!Hive.isAdapterRegistered(13)) {
    Hive.registerAdapter(InvestmentTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(14)) {
    Hive.registerAdapter(UserModelAdapter());
  }
  if (!Hive.isAdapterRegistered(15)) {
    Hive.registerAdapter(UserSettingsAdapter());
  }
  if (!Hive.isAdapterRegistered(16)) {
    Hive.registerAdapter(UserStatsAdapter());
  }
}

/// Minimal Hive setup for repository unit tests (transactions only).
Future<void> initializeHiveForTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  if (!_hivePathInitialized) {
    final tempDir = await Directory.systemTemp.createTemp('cashtrack_test_');
    Hive.init(tempDir.path);
    _hivePathInitialized = true;
  }

  registerCashtrackHiveAdapters();
}

/// Hive + core repositories used by widget tests that need categories, accounts, etc.
Future<void> initializeCashtrackRepositoriesForWidgetTest() async {
  await initializeHiveForTests();

  if (!Hive.isBoxOpen('settingsBox')) {
    await Hive.openBox('settingsBox');
  }

  await CategoryRepository().init();
  await AccountRepository().init();
  await TransactionRepository().init();
  await BudgetRepository().init();
}
