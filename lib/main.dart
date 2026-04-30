import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/l10n/app_l10n.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/security/app_lock_gate.dart';
import 'core/utils/logger.dart';
import 'services/ai_service.dart';
import 'services/screenshot_protection_service.dart';

// Import all repositories
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/account_repository.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/goal_repository.dart';
import 'data/repositories/debt_repository.dart';
import 'data/repositories/asset_repository.dart';
import 'data/repositories/investment_repository.dart';

// Import all models for Hive registration
import 'data/models/category_model.dart';
import 'data/models/account_model.dart';
import 'data/models/budget_model.dart';
import 'data/models/goal_model.dart';
import 'data/models/debt_model.dart';
import 'data/models/asset_model.dart';
import 'data/models/investment_model.dart';
import 'data/models/user_model.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('settingsBox');

  // সেটিংস বক্সটি ওপেন করুন যাতে শুরুতেই থিম চেক করা যায়
  // প্রোভাইডারে 'settingsBox' নাম ব্যবহার করা হয়েছে তাই এখানেও একই নাম থাকতে হবে
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(CategoryTypeAdapter());
  Hive.registerAdapter(AccountModelAdapter());
  Hive.registerAdapter(AccountTypeAdapter());
  Hive.registerAdapter(BudgetModelAdapter());
  Hive.registerAdapter(GoalModelAdapter());
  Hive.registerAdapter(DebtModelAdapter());
  Hive.registerAdapter(DebtTypeAdapter());
  Hive.registerAdapter(AssetModelAdapter());
  Hive.registerAdapter(InvestmentModelAdapter());
  Hive.registerAdapter(InvestmentTypeAdapter());
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(UserStatsAdapter());

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    AppLogger.w('Firebase init skipped/failure: $e');
  }

  await _initializeRepositories();

  // Pre-load API key from secure storage into memory cache.
  try {
    await AiService().init();
  } catch (e) {
    AppLogger.w('AiService init skipped: $e');
  }

  runApp(
    const ProviderScope(
      child: CashTrackApp(),
    ),
  );
}

Future<void> _initializeRepositories() async {
  final tasks = <(String, Future<void> Function())>[
    ('TransactionRepository', () => TransactionRepository().init()),
    ('CategoryRepository', () => CategoryRepository().init()),
    ('AccountRepository', () => AccountRepository().init()),
    ('BudgetRepository', () => BudgetRepository().init()),
    ('GoalRepository', () => GoalRepository().init()),
    ('DebtRepository', () => DebtRepository().init()),
    ('AssetRepository', () => AssetRepository().init()),
    ('InvestmentRepository', () => InvestmentRepository().init()),
  ];

  for (final task in tasks) {
    try {
      await task.$2();
      AppLogger.i('✅ ${task.$1} initialized');
    } catch (e) {
      AppLogger.e('${task.$1} initialization error: $e');
    }
  }
}

class CashTrackApp extends ConsumerWidget {
  const CashTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // settingsProvider থেকে গ্লোবাল সেটিংস স্টেট ওয়াচ করা হচ্ছে
    final settings = ref.watch(settingsProvider);
    final bool rolloverEnabled = settings['rolloverBudget'] == true;
    if (rolloverEnabled) {
      unawaited(
        ref.read(budgetsProvider.notifier).ensureMonthlyRollover(
              targetMonth: DateTime.now(),
              enabled: true,
            ),
      );
    }

    // ডিফল্ট ভ্যালুসহ সেটিংস লোড করা
    final bool isDarkMode = settings['darkMode'] ?? false;
    final bool screenshotProtection = settings['screenshotProtection'] == true;
    final int accentColorValue = settings['accentColor'] ?? 0xFF2D7A7B;
    final Color accentColor = Color(accentColorValue);
    final String language = (settings['language'] as String?) ?? 'en';
    final Locale appLocale =
        language == 'bn' ? const Locale('bn', 'BD') : const Locale('en');

    Intl.defaultLocale = appLocale.toString();

    unawaited(
      ScreenshotProtectionService.instance
          .apply(enabled: screenshotProtection),
    );

    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppL10n.of(ctx).t('app_name'),
      debugShowCheckedModeBanner: false,

      // AppTheme এর static method ব্যবহার করে ডাইনামিক লাইট থিম
      theme: AppTheme.getLightTheme(accentColor),

      // AppTheme এর static method ব্যবহার করে ডাইনামিক ডার্ক থিম
      darkTheme: AppTheme.getDarkTheme(accentColor),

      // প্রোভাইডার থেকে পাওয়া ডাটা অনুযায়ী থিম মোড সুইচ করা
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      locale: appLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('bn', 'BD'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      builder: (context, child) =>
          AppLockGate(child: child ?? const SizedBox.shrink()),
      routerConfig: appRouter,
    );
  }
}
