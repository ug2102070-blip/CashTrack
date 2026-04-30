class AppConstants {
  // App Info
  static const String appName = 'CashTrack';
  static const String appVersion = '1.0.0';
  static const String appPackage = 'com.cashtrack.app';

  // Currency
  static const String currencySymbol = '\u09F3';
  static const String currencyCode = 'BDT';
  static const String currencyName = 'Bangladeshi Taka';

  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String monthYearFormat = 'MMMM yyyy';

  // Limits
  static const int maxTransactionsPerPage = 20;
  static const int maxCategories = 50;
  static const double maxTransactionAmount = 9999999.99;
  static const int maxReceiptSize = 10 * 1024 * 1024;

  // Default Values
  static const String defaultAccountId = 'acc_cash';
  static const String defaultCategoryId = 'cat_others';
  static const double defaultBudget = 10000.0;

  // Keys for SharedPreferences
  static const String keyDarkMode = 'dark_mode';
  static const String keyLanguage = 'language';
  static const String keyAccentColor = 'accent_color';
  static const String keyCurrency = 'currency';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keySmsAutoImport = 'sms_auto_import';
  static const String keyRolloverBudget = 'rollover_budget';

  // Firebase Collection Names
  static const String collectionUsers = 'users';
  static const String collectionTransactions = 'transactions';
  static const String collectionCategories = 'categories';
  static const String collectionAccounts = 'accounts';
  static const String collectionBudgets = 'budgets';
  static const String collectionGoals = 'goals';
  static const String collectionDebts = 'debts';
  static const String collectionAssets = 'assets';
  static const String collectionInvestments = 'investments';

  // Notification Channel IDs
  static const String channelIdGeneral = 'general';
  static const String channelIdBudget = 'budget';
  static const String channelIdBills = 'bills';
  static const String channelIdReminders = 'reminders';

  // SMS Keywords for Auto-Import
  static const List<String> smsKeywords = [
    'bkash',
    'nagad',
    'rocket',
    'upay',
    'sure cash',
    'mycash',
    'ok wallet',
    'bank',
    'credited',
    'debited',
    'withdrawn',
    'deposited',
    'balance',
    'transaction',
  ];

  // Support
  static const String supportEmail = 'support@cashtrack.app';
  static const String appWebsiteUrl = 'https://cashtrack.app';
  static const String privacyPolicyUrl = 'https://cashtrack.app/privacy';
  static const String termsOfServiceUrl = 'https://cashtrack.app/terms';
}
