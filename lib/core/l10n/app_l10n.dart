import 'package:flutter/material.dart';

class AppL10n {
  AppL10n(this.locale);

  final Locale locale;

  static AppL10n of(BuildContext context) {
    return AppL10n(Localizations.localeOf(context));
  }

  static const _values = <String, Map<String, String>>{
    'analytics': {'en': 'Analytics', 'bn': 'বিশ্লেষণ'},
    'dashboard': {'en': 'Dashboard', 'bn': 'ড্যাশবোর্ড'},
    'good_morning': {'en': 'Good morning', 'bn': 'সুপ্রভাত'},
    'good_afternoon': {'en': 'Good afternoon', 'bn': 'শুভ অপরাহ্ন'},
    'good_evening': {'en': 'Good evening', 'bn': 'শুভ সন্ধ্যা'},
    'total_balance': {'en': 'Total Balance', 'bn': 'মোট ব্যালেন্স'},
    'income': {'en': 'Income', 'bn': 'আয়'},
    'expense': {'en': 'Expense', 'bn': 'ব্যয়'},
    'net_savings': {'en': 'Net Savings', 'bn': 'নিট সঞ্চয়'},
    'savings_rate': {'en': 'Savings Rate', 'bn': 'সঞ্চয়ের হার'},
    'deficit': {'en': 'Deficit', 'bn': 'ঘাটতি'},
    'saved_percent': {'en': '{value}% saved', 'bn': '{value}% সঞ্চয়'},
    'accounts': {'en': 'Accounts', 'bn': 'অ্যাকাউন্টস'},
    'no_accounts': {'en': 'No accounts', 'bn': 'কোনো অ্যাকাউন্ট নেই'},
    'add_first_account': {
      'en': 'Add your first account',
      'bn': 'প্রথম অ্যাকাউন্ট যোগ করুন'
    },
    'accounts_count': {
      'en': '{count} accounts',
      'bn': '{count} অ্যাকাউন্ট'
    },
    'cash': {'en': 'Cash', 'bn': 'ক্যাশ'},
    'online': {'en': 'Online', 'bn': 'অনলাইন'},
    'transfer': {'en': 'Transfer', 'bn': 'ট্রান্সফার'},
    'debts': {'en': 'Debts', 'bn': 'ঋণ'},
    'to_receive': {'en': 'To receive', 'bn': 'পাওনা'},
    'to_pay': {'en': 'To pay', 'bn': 'দেনা'},
    'transfer_funds': {'en': 'Transfer Funds', 'bn': 'ফান্ড ট্রান্সফার'},
    'amount': {'en': 'Amount', 'bn': 'পরিমাণ'},
    'enter_valid_amount': {
      'en': 'Enter a valid amount',
      'bn': 'সঠিক পরিমাণ লিখুন'
    },
    'insufficient_balance': {
      'en': 'Insufficient balance',
      'bn': 'অপর্যাপ্ত ব্যালেন্স'
    },
    'confirm_transfer': {
      'en': 'Confirm Transfer',
      'bn': 'ট্রান্সফার নিশ্চিত করুন'
    },
    'category_breakdown': {
      'en': 'Category Breakdown',
      'bn': 'ক্যাটাগরি বিশ্লেষণ'
    },
    'no_expense_month': {
      'en': 'No expense data for this month',
      'bn': 'এই মাসে কোনো ব্যয়ের তথ্য নেই'
    },
    'daily_expense_heatmap': {
      'en': 'Daily Expense Heatmap',
      'bn': 'দৈনিক ব্যয়ের হিটম্যাপ'
    },
    'less': {'en': 'Less', 'bn': 'কম'},
    'more': {'en': 'More', 'bn': 'বেশি'},
    'no_transactions': {'en': 'No transactions', 'bn': 'কোনো লেনদেন নেই'},
    'view_all': {'en': 'View All', 'bn': 'সব দেখুন'},
    'add_transaction': {'en': 'Add Transaction', 'bn': 'লেনদেন যোগ করুন'},
    'daily_trend': {'en': 'Daily Trend', 'bn': 'দৈনিক ধারা'},
    'income_vs_expense': {
      'en': 'Income vs Expense — {month}',
      'bn': 'আয় বনাম ব্যয় — {month}'
    },
    'settings': {'en': 'Settings', 'bn': 'সেটিংস'},
    'customize_experience': {
      'en': 'Customize your experience',
      'bn': 'আপনার অভিজ্ঞতা কাস্টমাইজ করুন'
    },
    'add_your_name': {'en': 'Add your name', 'bn': 'আপনার নাম যোগ করুন'},
    'tap_complete_profile': {
      'en': 'Tap to complete profile',
      'bn': 'প্রোফাইল সম্পূর্ণ করতে ট্যাপ করুন'
    },
    'appearance': {'en': 'Appearance', 'bn': 'অ্যাপিয়ারেন্স'},
    'notifications': {'en': 'Notifications', 'bn': 'নোটিফিকেশন'},
    'general': {'en': 'General', 'bn': 'সাধারণ'},
    'security_privacy': {
      'en': 'Security & Privacy',
      'bn': 'নিরাপত্তা ও গোপনীয়তা'
    },
    'data_sync': {'en': 'Data & Sync', 'bn': 'ডেটা ও সিঙ্ক'},
    'about': {'en': 'About', 'bn': 'সম্পর্কে'},
    'planning_tools': {'en': 'Planning & Tools', 'bn': 'পরিকল্পনা ও টুলস'},
    'manage_categories': {'en': 'Manage Categories', 'bn': 'ক্যাটাগরি ম্যানেজ'},
    'manage_categories_desc': {
      'en': 'Edit, reorder and merge categories',
      'bn': 'ক্যাটাগরি সম্পাদনা, সাজান বা মার্জ করুন'
    },
    'manage_budgets': {'en': 'Manage Budgets', 'bn': 'বাজেট ম্যানেজ'},
    'manage_budgets_desc': {
      'en': 'Create and adjust monthly budgets',
      'bn': 'মাসিক বাজেট তৈরি ও সমন্বয় করুন'
    },
    'rollover_budget': {'en': 'Budget Rollover', 'bn': 'বাজেট রোলওভার'},
    'rollover_budget_desc': {
      'en': 'Carry remaining budget to next month',
      'bn': 'বাকি বাজেট পরের মাসে বহন করুন'
    },
    'dark_mode': {'en': 'Dark Mode', 'bn': 'ডার্ক মোড'},
    'currently_dark': {'en': 'Currently dark', 'bn': 'বর্তমানে ডার্ক'},
    'currently_light': {'en': 'Currently light', 'bn': 'বর্তমানে লাইট'},
    'accent_color': {'en': 'Accent Color', 'bn': 'অ্যাকসেন্ট রঙ'},
    'personalize_color': {
      'en': 'Personalize app color',
      'bn': 'অ্যাপের রঙ ব্যক্তিগতকরণ করুন'
    },
    'currency': {'en': 'Currency', 'bn': 'মুদ্রা'},
    'hide_amounts': {'en': 'Hide Amounts', 'bn': 'পরিমাণ লুকান'},
    'privacy_balances': {
      'en': 'Privacy mode for balances',
      'bn': 'ব্যালেন্সের জন্য প্রাইভেসি মোড'
    },
    'compact_mode': {'en': 'Compact Mode', 'bn': 'কম্প্যাক্ট মোড'},
    'smaller_cards': {
      'en': 'Smaller cards and spacing',
      'bn': 'ছোট কার্ড ও কম স্পেসিং'
    },
    'push_notifications': {'en': 'Push Notifications', 'bn': 'পুশ নোটিফিকেশন'},
    'txn_reminder_alerts': {
      'en': 'Transaction & reminder alerts',
      'bn': 'লেনদেন ও রিমাইন্ডার অ্যালার্ট'
    },
    'weekly_report': {'en': 'Weekly Report', 'bn': 'সাপ্তাহিক রিপোর্ট'},
    'weekly_summary': {
      'en': 'Get weekly spending summary',
      'bn': 'সাপ্তাহিক খরচের সারাংশ পান'
    },
    'weekly_report_title': {'en': 'Weekly summary', 'bn': 'সাপ্তাহিক সারাংশ'},
    'weekly_report_body': {
      'en': 'Income {income}, Expense {expense}',
      'bn': 'আয় {income}, ব্যয় {expense}'
    },
    'weekly_report_empty': {
      'en': 'No transactions this week',
      'bn': 'এই সপ্তাহে কোনো লেনদেন নেই'
    },
    'weekly_report_channel': {
      'en': 'Weekly reports',
      'bn': 'সাপ্তাহিক রিপোর্ট'
    },
    'weekly_report_channel_desc': {
      'en': 'Weekly spending summary notifications',
      'bn': 'সাপ্তাহিক খরচের সারাংশ নোটিফিকেশন'
    },
    'notification_schedule': {
      'en': 'Notification Schedule',
      'bn': 'নোটিফিকেশন সময়সূচী'
    },
    'daily_reminder_time_value': {
      'en': 'Daily reminder at {time}',
      'bn': 'দৈনিক রিমাইন্ডার {time} এ'
    },
    'daily_reminder_time': {
      'en': 'Set daily reminder time',
      'bn': 'দৈনিক রিমাইন্ডারের সময় সেট করুন'
    },
    'daily_reminder_title': {'en': 'Daily reminder', 'bn': 'দৈনিক রিমাইন্ডার'},
    'daily_reminder_body': {
      'en': 'Don\'t forget to add today\'s transactions',
      'bn': 'আজকের লেনদেন যোগ করতে ভুলবেন না'
    },
    'daily_reminder_channel': {
      'en': 'Daily reminders',
      'bn': 'দৈনিক রিমাইন্ডার'
    },
    'daily_reminder_channel_desc': {
      'en': 'Daily transaction reminder notifications',
      'bn': 'দৈনিক লেনদেন রিমাইন্ডার নোটিফিকেশন'
    },
    'sms_auto_import': {'en': 'SMS Auto-Import', 'bn': 'এসএমএস অটো-ইমপোর্ট'},
    'import_sms': {
      'en': 'Import transactions from SMS',
      'bn': 'এসএমএস থেকে লেনদেন ইমপোর্ট করুন'
    },
    'sms_permission_denied': {
      'en': 'SMS permission denied',
      'bn': 'এসএমএস অনুমতি পাওয়া যায়নি'
    },
    'sms_import_mode': {'en': 'SMS Import Mode', 'bn': 'এসএমএস ইমপোর্ট মোড'},
    'language': {'en': 'Language', 'bn': 'ভাষা'},
    'english': {'en': 'English', 'bn': 'ইংরেজি'},
    'bangla': {'en': 'Bangla', 'bn': 'বাংলা'},
    'biometric_lock': {'en': 'Biometric Lock', 'bn': 'বায়োমেট্রিক লক'},
    'fingerprint_face': {
      'en': 'Fingerprint / Face ID',
      'bn': 'ফিঙ্গারপ্রিন্ট / ফেস আইডি'
    },
    'app_lock_pin': {'en': 'App Lock PIN', 'bn': 'অ্যাপ লক পিন'},
    'set_4_digit': {'en': 'Set a 4-digit PIN', 'bn': '৪ অংকের পিন সেট করুন'},
    'app_locked': {'en': 'App Locked', 'bn': 'অ্যাপ লকড'},
    'unlock': {'en': 'Unlock', 'bn': 'আনলক'},
    'unlock_with_biometrics': {
      'en': 'Unlock with biometrics',
      'bn': 'বায়োমেট্রিক দিয়ে আনলক'
    },
    'pin_incorrect': {'en': 'Incorrect PIN', 'bn': 'ভুল পিন'},
    'pin_set': {'en': 'PIN is set', 'bn': 'পিন সেট করা আছে'},
    'set_pin': {'en': 'Set PIN', 'bn': 'পিন সেট করুন'},
    'change_pin': {'en': 'Change PIN', 'bn': 'পিন পরিবর্তন করুন'},
    'remove_pin': {'en': 'Remove PIN', 'bn': 'পিন মুছুন'},
    'enter_pin': {'en': 'Enter PIN', 'bn': 'পিন লিখুন'},
    'confirm_pin': {'en': 'Confirm PIN', 'bn': 'পিন নিশ্চিত করুন'},
    'pin_saved': {'en': 'PIN saved', 'bn': 'পিন সেভ হয়েছে'},
    'pin_removed': {'en': 'PIN removed', 'bn': 'পিন মুছে ফেলা হয়েছে'},
    'pin_invalid': {'en': 'Enter a 4-digit PIN', 'bn': '৪ অংকের পিন লিখুন'},
    'pin_mismatch': {'en': 'PINs do not match', 'bn': 'পিন মিলছে না'},
    'auto_lock': {'en': 'Auto Lock', 'bn': 'অটো লক'},
    'lock_after_5': {
      'en': 'Lock after 5 minutes of inactivity',
      'bn': '৫ মিনিট নিষ্ক্রিয় থাকলে লক হবে'
    },
    'screenshot_protection': {
      'en': 'Screenshot Protection',
      'bn': 'স্ক্রিনশট সুরক্ষা'
    },
    'prevent_screenshots': {
      'en': 'Prevent screenshots',
      'bn': 'স্ক্রিনশট প্রতিরোধ করুন'
    },
    'backup_cloud': {'en': 'Backup to Cloud', 'bn': 'ক্লাউডে ব্যাকআপ'},
    'last_backup_never': {
      'en': 'Last backup: Never',
      'bn': 'শেষ ব্যাকআপ: কখনও নয়'
    },
    'backup_started': {
      'en': 'Backup started...',
      'bn': 'ব্যাকআপ শুরু হয়েছে...'
    },
    'backup_complete': {'en': 'Backup complete!', 'bn': 'ব্যাকআপ সম্পন্ন!'},
    'restore_cloud': {'en': 'Restore from Cloud', 'bn': 'ক্লাউড থেকে রিস্টোর'},
    'restore_data': {'en': 'Restore your data', 'bn': 'আপনার ডেটা রিস্টোর করুন'},
    'export_data': {'en': 'Export Data', 'bn': 'ডেটা এক্সপোর্ট'},
    'export_csv_json': {
      'en': 'Export as CSV or JSON',
      'bn': 'CSV বা JSON এ এক্সপোর্ট'
    },
    'import_data': {'en': 'Import Data', 'bn': 'ডেটা ইমপোর্ট'},
    'import_from_csv': {'en': 'Import from CSV', 'bn': 'CSV থেকে ইমপোর্ট'},
    'import_empty': {
      'en': 'No data found to import',
      'bn': 'ইমপোর্টের জন্য কোনো ডেটা নেই'
    },
    'import_complete': {
      'en': 'Imported {count} transactions',
      'bn': '{count}টি লেনদেন ইমপোর্ট হয়েছে'
    },
    'app_version': {'en': 'App Version', 'bn': 'অ্যাপ ভার্সন'},
    'select_currency': {'en': 'Select Currency', 'bn': 'মুদ্রা নির্বাচন করুন'},
    'sms_mode_title': {'en': 'SMS Import Mode', 'bn': 'এসএমএস ইমপোর্ট মোড'},
    'reminder_set_for': {
      'en': 'Reminder set for {time}',
      'bn': 'রিমাইন্ডার সেট হয়েছে {time}'
    },
    'select_language': {'en': 'Select Language', 'bn': 'ভাষা নির্বাচন করুন'},
    'pin_setup_soon': {
      'en': 'PIN setup coming soon!',
      'bn': 'পিন সেটআপ শীঘ্রই আসছে!'
    },
    'export_format': {
      'en': 'Choose export format:',
      'bn': 'এক্সপোর্ট ফরম্যাট বেছে নিন:'
    },
    'exporting_csv': {
      'en': 'Exporting as CSV...',
      'bn': 'CSV এক্সপোর্ট হচ্ছে...'
    },
    'exporting_json': {
      'en': 'Exporting as JSON...',
      'bn': 'JSON এক্সপোর্ট হচ্ছে...'
    },
    'restore_data_q': {'en': 'Restore Data?', 'bn': 'ডেটা রিস্টোর করবেন?'},
    'restore_overwrite': {
      'en': 'This will overwrite all local data with your cloud backup.',
      'bn': 'এটি আপনার ক্লাউড ব্যাকআপ দিয়ে সব লোকাল ডেটা ওভাররাইট করবে।'
    },
    'cancel': {'en': 'Cancel', 'bn': 'বাতিল'},
    'restore': {'en': 'Restore', 'bn': 'রিস্টোর'},
    'sign_out_q': {'en': 'Sign Out?', 'bn': 'সাইন আউট?'},
    'sign_out_confirm': {
      'en': 'Are you sure you want to sign out?',
      'bn': 'আপনি কি সাইন আউট করতে চান?'
    },
    'sign_out': {'en': 'Sign Out', 'bn': 'সাইন আউট'},
    'sign_out_subtitle': {
      'en': 'Log out of your account',
      'bn': 'আপনার অ্যাকাউন্ট থেকে লগ আউট করুন'
    },
    'rate_app': {'en': 'Rate the App', 'bn': 'অ্যাপ রেট করুন'},
    'love_rate_us': {
      'en': 'Love CashTrack? Rate us!',
      'bn': 'CashTrack ভালো লাগে? রেট দিন!'
    },
    'report_bug': {'en': 'Report a Bug', 'bn': 'বাগ রিপোর্ট করুন'},
    'help_improve': {
      'en': 'Help us improve',
      'bn': 'উন্নত করতে সাহায্য করুন'
    },
    'link_open_failed': {'en': 'Couldn\'t open link', 'bn': 'লিংক খোলা যায়নি'},
    'feature_not_supported_web': {
      'en': 'This feature is not supported on web',
      'bn': 'এই ফিচারটি ওয়েবে সমর্থিত নয়'
    },
    'biometric_not_supported': {
      'en': 'Biometric authentication not available',
      'bn': 'বায়োমেট্রিক প্রমাণীকরণ পাওয়া যায়নি'
    },
    'biometric_failed': {
      'en': 'Biometric authentication failed',
      'bn': 'বায়োমেট্রিক যাচাই ব্যর্থ হয়েছে'
    },
    'biometric_unlock_reason': {
      'en': 'Unlock CashTrack',
      'bn': 'CashTrack আনলক করুন'
    },
    'privacy_policy': {'en': 'Privacy Policy', 'bn': 'প্রাইভেসি পলিসি'},
    'data_handling': {
      'en': 'How we handle your data',
      'bn': 'আমরা আপনার ডেটা কীভাবে ব্যবহার করি'
    },
    'terms_service': {'en': 'Terms of Service', 'bn': 'সেবার শর্তাবলি'},
    'ask_before_adding': {
      'en': 'Ask before adding',
      'bn': 'যোগ করার আগে জিজ্ঞাসা'
    },
    'manual_review_sms': {
      'en': 'Manual review each SMS',
      'bn': 'প্রতিটি এসএমএস ম্যানুয়ালি রিভিউ'
    },
    'auto_silent': {'en': 'Auto silent', 'bn': 'অটো সাইলেন্ট'},
    'import_without_notif': {
      'en': 'Import without notifications',
      'bn': 'নোটিফিকেশন ছাড়াই ইমপোর্ট'
    },
    'auto_daily_summary': {
      'en': 'Auto + daily summary',
      'bn': 'অটো + দৈনিক সারাংশ'
    },
    'auto_import_digest': {
      'en': 'Auto import with daily digest',
      'bn': 'দৈনিক ডাইজেস্টসহ অটো ইমপোর্ট'
    },
    'one_minute': {'en': '1 minute', 'bn': '১ মিনিট'},
    'five_minutes': {'en': '5 minutes', 'bn': '৫ মিনিট'},
    'fifteen_minutes': {'en': '15 minutes', 'bn': '১৫ মিনিট'},
    'thirty_minutes': {'en': '30 minutes', 'bn': '৩০ মিনিট'},
    'never': {'en': 'Never', 'bn': 'কখনও নয়'},
    'planning': {'en': 'Planning', 'bn': 'পরিকল্পনা'},
    'calculator': {'en': 'Calculator', 'bn': 'ক্যালকুলেটর'},
    'notes': {'en': 'Notes', 'bn': 'নোটস'},
    'monthly_budget': {'en': 'Monthly Budget', 'bn': 'মাসিক বাজেট'},
    'used_percent': {'en': '{value}% used', 'bn': '{value}% ব্যবহার'},
    'tap_to_set_up': {'en': 'Tap to set up', 'bn': 'সেটআপ করতে ট্যাপ করুন'},
    'no_budget_set': {
      'en': 'No budget set for this month',
      'bn': 'এই মাসে কোনো বাজেট সেট নেই'
    },
    'set_budget_track': {
      'en': 'Set a budget to track your spending',
      'bn': 'খরচ ট্র্যাক করতে বাজেট সেট করুন'
    },
    'remaining': {'en': 'Remaining', 'bn': 'বাকি'},
    'budget': {'en': 'Budget', 'bn': 'বাজেট'},
    'spent': {'en': 'Spent', 'bn': 'খরচ হয়েছে'},
    'savings_goals': {'en': 'Savings Goals', 'bn': 'সেভিংস গোলস'},
    'active_goal_count': {
      'en': '{count} active goal{suffix}',
      'bn': '{count}টি সক্রিয় লক্ষ্য{suffix}'
    },
    'no_goals_yet': {'en': 'No goals yet', 'bn': 'এখনো কোনো লক্ষ্য নেই'},
    'add_goal': {'en': 'Add Goal', 'bn': 'লক্ষ্য যোগ করুন'},
    'overall_progress': {'en': 'Overall progress', 'bn': 'সামগ্রিক অগ্রগতি'},
    'more_goals': {'en': '+{count} more goals', 'bn': '+{count}টি আরও লক্ষ্য'},
    'debts_loans': {'en': 'Debts & Loans', 'bn': 'ঋণ ও ধার'},
    'to_receive_short': {'en': 'To receive', 'bn': 'পাওনা'},
    'to_pay_short': {'en': 'To pay', 'bn': 'দেনা'},
    'due_count': {'en': '{count} due', 'bn': '{count}টি বাকি'},
    'more_transactions': {
      'en': '+{count} more transactions',
      'bn': '+{count}টি আরও লেনদেন'
    },
    'expense_short': {'en': 'Exp', 'bn': 'ব্যয়'},
    'income_short': {'en': 'Inc', 'bn': 'আয়'},
    'active_goals': {'en': 'Active Goals', 'bn': 'সক্রিয় লক্ষ্য'},
    'completed_goals': {'en': 'Completed Goals', 'bn': 'সম্পন্ন লক্ষ্য'},
    'total_progress': {'en': 'Total Progress', 'bn': 'মোট অগ্রগতি'},
    'saved': {'en': 'Saved', 'bn': 'সঞ্চিত'},
    'target': {'en': 'Target', 'bn': 'লক্ষ্য'},
    'goals': {'en': 'Goals', 'bn': 'লক্ষ্যসমূহ'},
    'days_left': {'en': '{count} days left', 'bn': '{count} দিন বাকি'},
    'completed': {'en': 'Completed', 'bn': 'সম্পন্ন'},
    'percent_completed': {
      'en': '{value}% completed',
      'bn': '{value}% সম্পন্ন'
    },
    'to_go_amount': {'en': '{amount} to go', 'bn': '{amount} বাকি'},
    'add_money': {'en': 'Add Money', 'bn': 'টাকা যোগ করুন'},
    'details': {'en': 'Details', 'bn': 'বিস্তারিত'},
    'no_savings_goals': {
      'en': 'No savings goals yet',
      'bn': 'এখনো কোনো সেভিংস লক্ষ্য নেই'
    },
    'set_first_goal': {
      'en': 'Set your first goal and start saving!',
      'bn': 'প্রথম লক্ষ্য সেট করে সঞ্চয় শুরু করুন!'
    },
    'create_goal': {'en': 'Create Goal', 'bn': 'লক্ষ্য তৈরি করুন'},
    'create_savings_goal': {
      'en': 'Create Savings Goal',
      'bn': 'সেভিংস লক্ষ্য তৈরি করুন'
    },
    'goal_name': {'en': 'Goal Name', 'bn': 'লক্ষ্যের নাম'},
    'target_amount': {'en': 'Target Amount', 'bn': 'লক্ষ্যের পরিমাণ'},
    'set_deadline_optional': {
      'en': 'Set Deadline (Optional)',
      'bn': 'ডেডলাইন সেট করুন (ঐচ্ছিক)'
    },
    'create': {'en': 'Create', 'bn': 'তৈরি করুন'},
    'edit_savings_goal': {'en': 'Edit Savings Goal', 'bn': 'সেভিংস লক্ষ্য সম্পাদনা'},
    'goal_created_success': {
      'en': 'Goal created successfully!',
      'bn': 'লক্ষ্য সফলভাবে তৈরি হয়েছে!'
    },
    'goal_updated_success': {
      'en': 'Goal updated successfully!',
      'bn': 'লক্ষ্য সফলভাবে আপডেট হয়েছে!'
    },
    'update': {'en': 'Update', 'bn': 'আপডেট'},
    'add_money_to': {'en': 'Add Money to {name}', 'bn': '{name}-এ টাকা যোগ করুন'},
    'add': {'en': 'Add', 'bn': 'যোগ করুন'},
    'added_amount_to_goal': {
      'en': 'Added {amount} to {name}',
      'bn': '{name}-এ {amount} যোগ হয়েছে'
    },
    'deadline': {'en': 'Deadline', 'bn': 'ডেডলাইন'},
    'edit_goal': {'en': 'Edit Goal', 'bn': 'লক্ষ্য সম্পাদনা'},
    'across_all_accounts': {
      'en': 'Across all accounts',
      'bn': 'সব অ্যাকাউন্ট মিলিয়ে'
    },
    'add_account': {'en': 'Add Account', 'bn': 'অ্যাকাউন্ট যোগ করুন'},
    'new_account': {'en': 'New Account', 'bn': 'নতুন অ্যাকাউন্ট'},
    'type': {'en': 'Type', 'bn': 'ধরন'},
    'name_english': {'en': 'Name (English)', 'bn': 'নাম (ইংরেজি)'},
    'name_bangla': {'en': 'Name (Bangla)', 'bn': 'নাম (বাংলা)'},
    'initial_balance': {'en': 'Initial Balance', 'bn': 'প্রাথমিক ব্যালেন্স'},
    'edit_account': {'en': 'Edit Account', 'bn': 'অ্যাকাউন্ট সম্পাদনা'},
    'delete_account': {'en': 'Delete Account', 'bn': 'অ্যাকাউন্ট মুছুন'},
    'delete_account_confirm': {
      'en': 'Are you sure you want to delete "{name}"?',
      'bn': 'আপনি কি নিশ্চিত "{name}" মুছতে চান?'
    },
    'account_deleted': {'en': 'Account deleted', 'bn': 'অ্যাকাউন্ট মুছে ফেলা হয়েছে'},
    'balance': {'en': 'Balance', 'bn': 'ব্যালেন্স'},
    'edit': {'en': 'Edit', 'bn': 'সম্পাদনা'},
    'delete': {'en': 'Delete', 'bn': 'মুছুন'},
    'close': {'en': 'Close', 'bn': 'বন্ধ'},
    'bank': {'en': 'Bank', 'bn': 'ব্যাংক'},
    'mfs': {'en': 'MFS', 'bn': 'এমএফএস'},
    'total_budget': {'en': 'Total Budget', 'bn': 'মোট বাজেট'},
    'over': {'en': 'Over', 'bn': 'অতিরিক্ত'},
    'no_budgets_month': {
      'en': 'No budgets for this month',
      'bn': 'এই মাসে কোনো বাজেট নেই'
    },
    'create_first_budget': {
      'en': 'Create your first budget to track spending',
      'bn': 'খরচ ট্র্যাক করতে প্রথম বাজেট তৈরি করুন'
    },
    'create_budget': {'en': 'Create Budget', 'bn': 'বাজেট তৈরি করুন'},
    'create_expense_category_first': {
      'en': 'Please create an expense category first',
      'bn': 'আগে একটি ব্যয় ক্যাটাগরি তৈরি করুন'
    },
    'edit_budget': {'en': 'Edit Budget', 'bn': 'বাজেট সম্পাদনা'},
    'budget_amount': {'en': 'Budget Amount', 'bn': 'বাজেটের পরিমাণ'},
    'suggested_amount': {
      'en': 'Suggested: {amount}',
      'bn': 'প্রস্তাবিত: {amount}'
    },
    'use': {'en': 'Use', 'bn': 'ব্যবহার করুন'},
    'enter_valid_category_amount': {
      'en': 'Enter a valid category and amount',
      'bn': 'সঠিক ক্যাটাগরি ও পরিমাণ লিখুন'
    },
    'budget_created_success': {
      'en': 'Budget created successfully',
      'bn': 'বাজেট সফলভাবে তৈরি হয়েছে!'
    },
    'budget_updated_success': {
      'en': 'Budget updated successfully',
      'bn': 'বাজেট সফলভাবে আপডেট হয়েছে!'
    },
    'delete_budget': {'en': 'Delete Budget', 'bn': 'বাজেট মুছুন'},
    'delete_budget_confirm': {
      'en': 'This budget entry will be removed.',
      'bn': 'এই বাজেট এন্ট্রি মুছে যাবে।'
    },
    'budget_deleted': {'en': 'Budget deleted', 'bn': 'বাজেট মুছে ফেলা হয়েছে'},
    'your_name': {'en': 'Your Name', 'bn': 'আপনার নাম'},
    'personal_info': {'en': 'Personal Info', 'bn': 'ব্যক্তিগত তথ্য'},
    'additional_info': {'en': 'Additional Info', 'bn': 'অতিরিক্ত তথ্য'},
    'recent_activity': {'en': 'Recent Activity', 'bn': 'সাম্প্রতিক কার্যকলাপ'},
    'full_name': {'en': 'Full Name', 'bn': 'পূর্ণ নাম'},
    'not_set': {'en': 'Not set', 'bn': 'সেট করা নেই'},
    'occupation': {'en': 'Occupation', 'bn': 'পেশা'},
    'date_of_birth': {'en': 'Date of Birth', 'bn': 'জন্মতারিখ'},
    'about_me': {'en': 'About Me', 'bn': 'আমার সম্পর্কে'},
    'tap_add_bio': {
      'en': 'Tap to add a short bio...',
      'bn': 'ছোট একটি বায়ো যোগ করতে ট্যাপ করুন...'
    },
    'this_month_income': {'en': 'This Month In', 'bn': 'এই মাসের আয়'},
    'transactions': {'en': 'Transactions', 'bn': 'লেনদেন'},
    'new_transaction': {'en': 'New Transaction', 'bn': 'নতুন লেনদেন'},
    'edit_transaction': {'en': 'Edit Transaction', 'bn': 'লেনদেন সম্পাদনা'},
    'update_transaction': {
      'en': 'Update Transaction',
      'bn': 'লেনদেন আপডেট করুন'
    },
    'save_transaction': {'en': 'Save Transaction', 'bn': 'লেনদেন সেভ করুন'},
    'paste_sms': {'en': 'Paste SMS', 'bn': 'এসএমএস পেস্ট করুন'},
    'paste_sms_hint': {
      'en': 'Paste the transaction SMS here',
      'bn': 'এখানে লেনদেনের এসএমএস পেস্ট করুন'
    },
    'use_sms': {'en': 'Use SMS', 'bn': 'এসএমএস ব্যবহার করুন'},
    'sms_parsed_review': {
      'en': 'SMS parsed — please review',
      'bn': 'এসএমএস পার্স হয়েছে — অনুগ্রহ করে রিভিউ করুন'
    },
    'category': {'en': 'Category', 'bn': 'ক্যাটাগরি'},
    'account': {'en': 'Account', 'bn': 'অ্যাকাউন্ট'},
    'date': {'en': 'Date', 'bn': 'তারিখ'},
    'note': {'en': 'Note', 'bn': 'নোট'},
    'add_note': {'en': 'Add note...', 'bn': 'নোট যোগ করুন'},
    'select': {'en': 'Select', 'bn': 'নির্বাচন করুন'},
    'select_category': {'en': 'Select Category', 'bn': 'ক্যাটাগরি নির্বাচন করুন'},
    'select_account': {'en': 'Select Account', 'bn': 'অ্যাকাউন্ট নির্বাচন করুন'},
    'select_category_prompt': {
      'en': 'Select a category',
      'bn': 'ক্যাটাগরি নির্বাচন করুন'
    },
    'select_account_prompt': {
      'en': 'Select an account',
      'bn': 'অ্যাকাউন্ট নির্বাচন করুন'
    },
    'updated': {'en': 'Updated!', 'bn': 'আপডেট হয়েছে!'},
    'error_with_detail': {'en': 'Error: {error}', 'bn': 'ত্রুটি: {error}'},
    'no_transactions_yet': {
      'en': 'No transactions yet',
      'bn': 'এখনো কোনো লেনদেন নেই'
    },
    'unlocked': {'en': 'Unlocked', 'bn': 'আনলক হয়েছে'},
    'profile_photo': {'en': 'Profile Photo', 'bn': 'প্রোফাইল ছবি'},
    'choose_from_gallery': {
      'en': 'Choose from gallery',
      'bn': 'গ্যালারি থেকে বাছাই করুন'
    },
    'take_photo': {'en': 'Take a photo', 'bn': 'ছবি তুলুন'},
    'remove_photo': {'en': 'Remove photo', 'bn': 'ছবি সরান'},
    'photo_updated': {'en': 'Photo updated!', 'bn': 'ছবি আপডেট হয়েছে!'},
    'photo_removed': {'en': 'Photo removed', 'bn': 'ছবি সরানো হয়েছে'},
    'edit_field': {'en': 'Edit {label}', 'bn': '{label} সম্পাদনা'},
    'save_changes': {'en': 'Save Changes', 'bn': 'পরিবর্তন সংরক্ষণ করুন'},
    'field_updated': {'en': '{label} updated', 'bn': '{label} আপডেট হয়েছে'},
    'ach_first_tx': {'en': 'First Transaction', 'bn': 'প্রথম লেনদেন'},
    'ach_first_tx_desc': {
      'en': 'Logged your first transaction',
      'bn': 'আপনার প্রথম লেনদেন যুক্ত হয়েছে'
    },
    'ach_budget_tracker': {'en': 'Budget Tracker', 'bn': 'বাজেট ট্র্যাকার'},
    'ach_budget_tracker_desc': {
      'en': 'Added your first budget',
      'bn': 'আপনার প্রথম বাজেট যোগ হয়েছে'
    },
    'ach_power_user': {'en': 'Power User', 'bn': 'পাওয়ার ইউজার'},
    'ach_power_user_desc': {
      'en': '50+ transactions logged',
      'bn': '৫০+ লেনদেন রেকর্ড হয়েছে'
    },
    'ach_savings_master': {'en': 'Savings Master', 'bn': 'সঞ্চয় মাস্টার'},
    'ach_savings_master_desc': {
      'en': 'Saved 20%+ for a month',
      'bn': 'এক মাসে ২০%+ সঞ্চয়'
    },
    'total_income': {'en': 'Total Income', 'bn': 'মোট আয়'},
    'total_expense': {'en': 'Total Expense', 'bn': 'মোট ব্যয়'},
    'today': {'en': 'Today', 'bn': 'আজ'},
    'yesterday': {'en': 'Yesterday', 'bn': 'গতকাল'},
    'no_transactions_found': {
      'en': 'No transactions found',
      'bn': 'কোনো লেনদেন পাওয়া যায়নি'
    },
    'try_adjust_filters': {
      'en': 'Try adjusting your filters',
      'bn': 'ফিল্টার সমন্বয় করে দেখুন'
    },
    'add_first_transaction': {
      'en': 'Add your first transaction',
      'bn': 'প্রথম লেনদেন যোগ করুন'
    },
    'filter': {'en': 'Filter', 'bn': 'ফিল্টার'},
    'date_range': {'en': 'Date Range', 'bn': 'তারিখ পরিসর'},
    'select_date_range': {'en': 'Select date range', 'bn': 'তারিখ পরিসর নির্বাচন করুন'},
    'clear_date_filter': {'en': 'Clear date filter', 'bn': 'তারিখ ফিল্টার মুছুন'},
    'transaction_deleted': {
      'en': 'Transaction deleted',
      'bn': 'লেনদেন মুছে ফেলা হয়েছে'
    },
    'add_new_category': {'en': 'Add New Category', 'bn': 'নতুন ক্যাটাগরি যোগ করুন'},
    'add_category_type': {
      'en': 'Add {type} Category',
      'bn': '{type} ক্যাটাগরি যোগ করুন'
    },
    'select_icon': {'en': 'Select Icon:', 'bn': 'আইকন নির্বাচন করুন:'},
    'select_color': {'en': 'Select Color:', 'bn': 'রঙ নির্বাচন করুন:'},
    'category_name_english': {
      'en': 'Category Name (English)',
      'bn': 'ক্যাটাগরির নাম (ইংরেজি)'
    },
    'category_name_bangla': {
      'en': 'Category Name (Bangla)',
      'bn': 'ক্যাটাগরির নাম (বাংলা)'
    },
    'category_added_success': {
      'en': 'Category added successfully',
      'bn': 'ক্যাটাগরি সফলভাবে যোগ হয়েছে'
    },
    'edit_category': {'en': 'Edit Category', 'bn': 'ক্যাটাগরি সম্পাদনা'},
    'category_updated_success': {
      'en': 'Category updated successfully',
      'bn': 'ক্যাটাগরি সফলভাবে আপডেট হয়েছে'
    },
    'delete_category': {'en': 'Delete Category', 'bn': 'ক্যাটাগরি মুছুন'},
    'delete_category_confirm': {
      'en': 'Are you sure you want to delete "{name}"?',
      'bn': 'আপনি কি নিশ্চিত "{name}" মুছতে চান?'
    },
    'category_deleted': {'en': 'Category deleted', 'bn': 'ক্যাটাগরি মুছে ফেলা হয়েছে'},
    'debt_added_success': {
      'en': 'Debt added successfully',
      'bn': 'ঋণ সফলভাবে যোগ হয়েছে'
    },
    'debt_updated_success': {
      'en': 'Debt updated successfully',
      'bn': 'ঋণ সফলভাবে আপডেট হয়েছে'
    },
    'payment_added_success': {
      'en': 'Payment added successfully',
      'bn': 'পরিশোধ সফলভাবে যোগ হয়েছে'
    },
    'add_debt_loan': {'en': 'Add Debt Loan', 'bn': 'ঋণ/ধার যোগ করুন'},
    'add_debt_or_loan': {'en': 'Add Debt Or Loan', 'bn': 'ঋণ বা ধার যোগ করুন'},
    'add_payment': {'en': 'Add Payment', 'bn': 'পরিশোধ যোগ করুন'},
    'address': {'en': 'Address', 'bn': 'ঠিকানা'},
    'ai_assistant': {'en': 'AI Assistant', 'bn': 'এআই সহকারী'},
    'ai_empty_subtitle': {
      'en': 'AI Empty Subtitle',
      'bn': 'আপনার খরচ সম্পর্কে স্মার্ট পরামর্শ নিন'
    },
    'ai_empty_title': {
      'en': 'AI Empty Title',
      'bn': 'প্রশ্ন করুন বা ইনসাইট নিন'
    },
    'ai_input_hint': {'en': 'AI Input Hint', 'bn': 'আপনার প্রশ্ন লিখুন...'},
    'ai_key_not_configured': {
      'en': 'AI Key Not Configured',
      'bn': 'এআই কনফিগার করা নেই'
    },
    'ai_month_snapshot': {
      'en': 'AI Month Snapshot',
      'bn':
          'এই মাসের সংক্ষিপ্ত চিত্র: আয় {income}, ব্যয় {expense}, সঞ্চয় {savings}।'
    },
    'ai_no_tx_month': {'en': 'AI No Tx Month', 'bn': 'এই মাসে কোনো লেনদেন নেই'},
    'ai_suggestion_income_vs_expense': {
      'en': 'AI Suggestion Income Vs Expense',
      'bn': 'এই মাসে আয় বনাম ব্যয়'
    },
    'aio_suggestion_over_budget': {
      'en': 'Aio Suggestion Over Budget',
      'bn': 'কোন কোন ক্যাটাগরি বাজেটের বেশি?'
    },
    'aio_suggestion_saving_tips': {
      'en': 'Aio Suggestion Saving Tips',
      'bn': 'সঞ্চয় বাড়ানোর টিপস দাও'
    },
    'aio_suggestion_spending': {
      'en': 'Aio Suggestion Spending',
      'bn': 'খরচের সারাংশ দাও'
    },
    'aio_suggestion_top_category': {
      'en': 'Aio Suggestion Top Category',
      'bn': 'সবচেয়ে বেশি খরচের ক্যাটাগরি কোনটি?'
    },
    'aio_tip_budget_used': {
      'en': 'Aio Tip Budget Used',
      'bn': 'আপনার বাজেটের {percent}% ব্যবহার হয়েছে'
    },
    'aio_tip_no_expense': {
      'en': 'Aio Tip No Expense',
      'bn': 'আজ কোনো ব্যয় রেকর্ড হয়নি'
    },
    'aio_tip_over_budget': {
      'en': 'Aio Tip Over Budget',
      'bn': '{category} ক্যাটাগরিতে বাজেট ছাড়িয়েছে'
    },
    'aio_tip_spent_so_far': {
      'en': 'Aio Tip Spent So Far',
      'bn': 'এই মাসে এখন পর্যন্ত {amount} খরচ হয়েছে'
    },
    'ai_welcome': {
      'en': 'AI Welcome',
      'bn': 'আপনার খরচ নিয়ে কিছু জানতে চান? জিজ্ঞাসা করুন।'
    },
    'ai_service_not_configured': {
      'en': 'AI service is not configured. Please set GEMINI_API_KEY.',
      'bn': 'এআই সার্ভিস কনফিগার করা নেই। অনুগ্রহ করে GEMINI_API_KEY সেট করুন।'
    },
    'ai_service_error_backend': {
      'en': 'AI service error. Please check your backend configuration.',
      'bn':
          'এআই সার্ভিসে সমস্যা হয়েছে। অনুগ্রহ করে ব্যাকএন্ড কনফিগারেশন চেক করুন।'
    },
    'ai_service_error_api_key': {
      'en': 'AI service error. Please check your Gemini API key.',
      'bn':
          'এআই সার্ভিসে সমস্যা হয়েছে। অনুগ্রহ করে আপনার Gemini API কী চেক করুন।'
    },
    'ai_service_no_response': {
      'en': 'No response from AI service.',
      'bn': 'এআই সার্ভিস থেকে কোনো উত্তর পাওয়া যায়নি।'
    },
    'ai_context_currency': {
      'en': 'Currency: {currency}',
      'bn': 'মুদ্রা: {currency}'
    },
    'ai_context_today': {'en': 'Today: {date}', 'bn': 'আজ: {date}'},
    'ai_context_this_month': {
      'en': 'This month ({month}):',
      'bn': 'এই মাস ({month}):'
    },
    'ai_context_income_line': {
      'en': '- Income: {amount}',
      'bn': '- আয়: {amount}'
    },
    'ai_context_expense_line': {
      'en': '- Expense: {amount}',
      'bn': '- ব্যয়: {amount}'
    },
    'ai_context_net_line': {'en': '- Net: {amount}', 'bn': '- নিট: {amount}'},
    'ai_context_top_expense_line': {
      'en': '- Top expense: {value}',
      'bn': '- সর্বোচ্চ ব্যয়: {value}'
    },
    'ai_context_top_income_line': {
      'en': '- Top income: {value}',
      'bn': '- সর্বোচ্চ আয়: {value}'
    },
    'ai_context_accounts': {'en': 'Accounts:', 'bn': 'অ্যাকাউন্টসমূহ:'},
    'ai_context_balance_line': {
      'en': '- Balance: {amount} ({count} accounts)',
      'bn': '- ব্যালেন্স: {amount} ({count} অ্যাকাউন্ট)'
    },
    'ai_context_budgets': {'en': 'Budgets:', 'bn': 'বাজেটসমূহ:'},
    'ai_context_budget_set_line': {
      'en': '- Set: {amount}',
      'bn': '- সেট: {amount}'
    },
    'ai_context_budget_spent_line': {
      'en': '- Spent: {amount}',
      'bn': '- খরচ: {amount}'
    },
    'ai_context_budget_remaining_line': {
      'en': '- Remaining: {amount}',
      'bn': '- বাকি: {amount}'
    },
    'ai_context_recent': {
      'en': 'Recent transactions:',
      'bn': 'সাম্প্রতিক লেনদেন:'
    },
    'ai_context_tx_line': {
      'en': '- {type}: {amount} ({category}) on {date}',
      'bn': '- {type}: {amount} ({category}) তারিখে {date}'
    },
    'alert': {'en': 'Alert', 'bn': 'অ্যালার্ট'},
    'alerts_count': {'en': 'Alerts Count', 'bn': '{count}টি অ্যালার্ট'},
    'all_clear': {'en': 'All Clear', 'bn': 'সব ঠিক আছে'},
    'amount_paid': {'en': 'Amount Paid', 'bn': 'পরিশোধিত পরিমাণ'},
    'app_name': {'en': 'App Name', 'bn': 'CashTrack'},
    'ask': {'en': 'Ask', 'bn': 'জিজ্ঞাসা করুন'},
    'asset': {'en': 'Asset', 'bn': 'সম্পদ'},
    'average_per_day': {'en': 'Average Per Day', 'bn': 'গড় প্রতিদিন'},
    'bio': {'en': 'Bio', 'bn': 'বায়ো'},
    'borrowed': {'en': 'Borrowed', 'bn': 'ধার'},
    'budget_categories': {'en': 'Budget Categories', 'bn': 'বাজেট ক্যাটাগরি'},
    'budget_exceeded': {'en': 'Budget Exceeded', 'bn': 'বাজেট ছাড়িয়েছে'},
    'budget_nearly_full': {
      'en': 'Budget Nearly Full',
      'bn': 'বাজেট প্রায় পূর্ণ'
    },
    'budget_used_percent': {
      'en': 'Budget Used Percent',
      'bn': 'ব্যবহৃত: {value}%'
    },
    'budget_vs_actual': {'en': 'Budget Vs Actual', 'bn': 'বাজেট বনাম বাস্তব'},
    'budget_vs_actual_desc': {
      'en': 'Budget Vs Actual Desc',
      'bn': 'বাজেটের সাথে ব্যয় তুলনা করুন'
    },
    'budget_vs_actual_report': {
      'en': 'Budget Vs Actual Report',
      'bn': 'বাজেট বনাম বাস্তব রিপোর্ট'
    },
    'cash_flow': {'en': 'Cash Flow', 'bn': 'ক্যাশ ফ্লো'},
    'cash_flow_desc': {'en': 'Cash Flow Desc', 'bn': 'নগদ প্রবাহের সারসংক্ষেপ'},
    'cash_in': {'en': 'Cash In', 'bn': 'আয়'},
    'cash_out': {'en': 'Cash Out', 'bn': 'ব্যয়'},
    'cashtrack_report': {'en': 'Cashtrack Report', 'bn': 'CashTrack রিপোর্ট'},
    'categories': {'en': 'Categories', 'bn': 'ক্যাটাগরি'},
    'caught_up': {'en': 'Caught Up', 'bn': 'সব আপডেট আছে'},
    'clear_date': {'en': 'Clear Date', 'bn': 'তারিখ মুছুন'},
    'continue': {'en': 'Continue', 'bn': 'চালিয়ে যান'},
    'current_value': {'en': 'Current Value', 'bn': 'বর্তমান মূল্য'},
    'custom': {'en': 'Custom', 'bn': 'কাস্টম'},
    'debt_due_body': {
      'en': 'Debt Due Body',
      'bn': '{name} এর {amount} {date} এর মধ্যে পরিশোধযোগ্য।'
    },
    'debt_due_line': {
      'en': '{type} — Due: {date}',
      'bn': '{type} — শেষ তারিখ: {date}'
    },
    'debt_due_soon': {'en': 'Debt Due Soon', 'bn': 'শীঘ্রই পরিশোধযোগ্য ঋণ'},
    'debt_form_hint': {'en': 'Debt Form Hint', 'bn': 'কে কাকে কত টাকা'},
    'debt_summary': {'en': 'Debt Summary', 'bn': 'ঋণ সারাংশ'},
    'debt_summary_desc': {
      'en': 'Debt Summary Desc',
      'bn': 'ঋণ ও পরিশোধের সারাংশ'
    },
    'due_date': {'en': 'Due Date', 'bn': 'শেষ তারিখ'},
    'edit_debt_loan': {'en': 'Edit Debt Loan', 'bn': 'ঋণ/ধার সম্পাদনা'},
    'edit_note': {'en': 'Edit Note', 'bn': 'নোট সম্পাদনা'},
    'email': {'en': 'Email', 'bn': 'ইমেইল'},
    'enter_valid_person_amount': {
      'en': 'Enter Valid Person Amount',
      'bn': 'সঠিক নাম ও পরিমাণ লিখুন'
    },
    'error': {'en': 'Error', 'bn': 'ত্রুটি'},
    'expense_breakdown': {'en': 'Expense Breakdown', 'bn': 'ব্যয় বিশ্লেষণ'},
    'expense_report': {'en': 'Expense Report', 'bn': 'ব্যয় রিপোর্ট'},
    'expense_report_desc': {
      'en': 'Expense Report Desc',
      'bn': 'ব্যয়ের সারাংশ দেখুন'
    },
    'expense_transactions': {
      'en': 'Expense Transactions',
      'bn': 'ব্যয় লেনদেন'
    },
    'export': {'en': 'Export', 'bn': 'এক্সপোর্ট'},
    'export_as_format': {
      'en': 'Export As Format',
      'bn': '{format} হিসেবে এক্সপোর্ট'
    },
    'export_failed': {'en': 'Export Failed', 'bn': 'এক্সপোর্ট ব্যর্থ হয়েছে'},
    'field_1': {'en': 'Field 1', 'bn': 'ফিল্ড ১'},
    'field_2': {'en': 'Field 2', 'bn': 'ফিল্ড ২'},
    'field_3': {'en': 'Field 3', 'bn': 'ফিল্ড ৩'},
    'file_saved': {'en': 'File Saved', 'bn': 'ফাইল সেভ হয়েছে: {file}'},
    'generated_on': {'en': 'Generated On', 'bn': 'তৈরির তারিখ'},
    'i_owe_someone': {'en': 'I Owe Someone', 'bn': 'আমি কারও কাছে বাকি'},
    'income_breakdown': {'en': 'Income Breakdown', 'bn': 'আয় বিশ্লেষণ'},
    'income_statement': {'en': 'Income Statement', 'bn': 'আয় বিবরণী'},
    'income_statement_desc': {
      'en': 'Income Statement Desc',
      'bn': 'আপনার আয় সংক্ষেপে দেখুন'
    },
    'income_transactions': {'en': 'Income Transactions', 'bn': 'আয় লেনদেন'},
    'invested_amount': {'en': 'Invested Amount', 'bn': 'বিনিয়োগের পরিমাণ'},
    'investment_portfolio': {
      'en': 'Investment Portfolio',
      'bn': 'বিনিয়োগ পোর্টফোলিও'
    },
    'investment_portfolio_desc': {
      'en': 'Investment Portfolio Desc',
      'bn': 'বিনিয়োগের সারাংশ'
    },
    'login_failed': {'en': 'Login failed: {error}', 'bn': 'লগইন ব্যর্থ: {error}'},
    'low_balance': {'en': 'Low Balance', 'bn': 'কম ব্যালেন্স'},
    'low_balance_body': {
      'en': 'Low Balance Body',
      'bn': 'আপনার ব্যালেন্স কমে যাচ্ছে। খরচ নিয়ন্ত্রণ করুন।'
    },
    'month': {'en': 'Month', 'bn': 'মাস'},
    'monthly_summary': {'en': 'Monthly Summary', 'bn': 'মাসিক সারাংশ'},
    'monthly_summary_desc': {
      'en': 'Monthly Summary Desc',
      'bn': 'মাসিক আয় ও ব্যয়'
    },
    'need_to_pay': {'en': 'Need To Pay', 'bn': 'দিতে হবে'},
    'net_flow': {'en': 'Net Flow', 'bn': 'নিট প্রবাহ'},
    'net_label': {'en': 'Net Label', 'bn': 'নিট'},
    'new_note': {'en': 'New Note', 'bn': 'নতুন নোট'},
    'no': {'en': 'No', 'bn': 'না'},
    'no_alerts': {'en': 'No Alerts', 'bn': 'কোনো অ্যালার্ট নেই'},
    'no_budget_entries_period': {
      'en': 'No Budget Entries Period',
      'bn': 'এই সময়ে কোনো বাজেট এন্ট্রি নেই'
    },
    'no_content': {'en': 'No Content', 'bn': 'কোনো কনটেন্ট নেই'},
    'no_debt_records': {
      'en': 'No Debt Records',
      'bn': 'এখনো কোনো ঋণ রেকর্ড নেই'
    },
    'no_due_date': {'en': 'No Due Date', 'bn': 'কোনো নির্দিষ্ট তারিখ নেই'},
    'no_matches_found': {
      'en': 'No Matches Found',
      'bn': 'কোনো মিল পাওয়া যায়নি'
    },
    'no_notes_yet': {'en': 'No Notes Yet', 'bn': 'এখনো কোনো নোট নেই'},
    'no_transactions_period': {
      'en': 'No Transactions Period',
      'bn': 'এই সময়ে কোনো লেনদেন নেই'
    },
    'no_type_data': {'en': 'No Type Data', 'bn': 'এই ধরনের কোনো ডেটা নেই'},
    'not_configured': {'en': 'Not Configured', 'bn': 'কনফিগার করা নেই'},
    'note_saved': {'en': 'Note Saved', 'bn': 'নোট সেভ হয়েছে'},
    'on_track': {'en': 'On Track', 'bn': 'ঠিক পথে'},
    'over_budget': {'en': 'Over Budget', 'bn': 'বাজেটের বেশি'},
    'paid': {'en': 'Paid', 'bn': 'পরিশোধিত'},
    'paid_of_total': {'en': '{paid} / {total} paid', 'bn': '{paid} / {total} পরিশোধিত'},
    'payment': {'en': 'Payment', 'bn': 'পরিশোধ'},
    'period_range': {'en': 'Period Range', 'bn': '{start} - {end}'},
    'person': {'en': 'Person', 'bn': 'ব্যক্তি'},
    'person_name': {'en': 'Person Name', 'bn': 'ব্যক্তির নাম'},
    'phone': {'en': 'Phone', 'bn': 'ফোন'},
    'quick_reports': {'en': 'Quick Reports', 'bn': 'কুইক রিপোর্টস'},
    'recent_transactions': {
      'en': 'Recent Transactions',
      'bn': 'সাম্প্রতিক লেনদেন'
    },
    'record_deleted': {'en': 'Record Deleted', 'bn': 'রেকর্ড মুছে ফেলা হয়েছে'},
    'remaining_amount': {'en': 'Remaining: {amount}', 'bn': 'বাকি: {amount}'},
    'replace_sample_values': {
      'en': 'Replace Sample Values',
      'bn': 'উদাহরণ মান প্রতিস্থাপন করুন'
    },
    'report_period': {'en': 'Report Period', 'bn': 'রিপোর্ট সময়কাল'},
    'report_templates': {'en': 'Report Templates', 'bn': 'রিপোর্ট টেমপ্লেট'},
    'reports_export': {'en': 'Reports Export', 'bn': 'রিপোর্টস ও এক্সপোর্ট'},
    'return_percent': {'en': 'Return Percent', 'bn': 'রিটার্ন %'},
    'sample_asset': {'en': 'Sample Asset', 'bn': 'উদাহরণ সম্পদ'},
    'sample_name': {'en': 'Sample Name', 'bn': 'নাম'},
    'save': {'en': 'Save', 'bn': 'সেভ করুন'},
    'save_note': {'en': 'Save Note', 'bn': 'নোট সেভ করুন'},
    'search': {'en': 'Search', 'bn': 'সার্চ'},
    'search_hint': {'en': 'Search Hint', 'bn': 'লেনদেন খুঁজুন'},
    'select_date_range_first': {
      'en': 'Select Date Range First',
      'bn': 'সবার আগে তারিখ পরিসর নির্বাচন করুন'
    },
    'settled': {'en': 'Settled', 'bn': 'পরিশোধিত'},
    'share': {'en': 'Share', 'bn': 'শেয়ার'},
    'share_report': {'en': 'Share Report', 'bn': 'রিপোর্ট শেয়ার করুন'},
    'sign_in_continue': {
      'en': 'Your data stays on your device',
      'bn': 'আপনার ডেটা আপনার ডিভাইসেই থাকবে'
    },
    'smart_insight': {'en': 'Smart Insight', 'bn': 'স্মার্ট ইনসাইট'},
    'someone_owes_me': {'en': 'Someone Owes Me', 'bn': 'কেউ আমার কাছে বাকি'},
    'start_typing_to_search': {
      'en': 'Start Typing To Search',
      'bn': 'খুঁজতে টাইপ করা শুরু করুন'
    },
    'summary': {'en': 'Summary', 'bn': 'সারাংশ'},
    'tax_deductible': {'en': 'Tax Deductible', 'bn': 'কর-ছাড়যোগ্য'},
    'tax_report': {'en': 'Tax Report', 'bn': 'ট্যাক্স রিপোর্ট'},
    'tax_report_desc': {
      'en': 'Tax Report Desc',
      'bn': 'ট্যাক্স হিসাবের সারাংশ'
    },
    'template_generation_failed': {
      'en': 'Template Generation Failed',
      'bn': 'টেমপ্লেট তৈরি ব্যর্থ হয়েছে'
    },
    'template_saved': {'en': 'Template Saved', 'bn': 'টেমপ্লেট সেভ হয়েছে'},
    'template_share_text': {
      'en': 'Template Share Text',
      'bn': 'এই রিপোর্টটি দেখুন'
    },
    'template_title': {'en': 'Template Title', 'bn': 'টেমপ্লেট শিরোনাম'},
    'this_month': {'en': 'This Month', 'bn': 'এই মাস'},
    'title': {'en': 'Title', 'bn': 'শিরোনাম'},
    'total': {'en': 'Total', 'bn': 'মোট'},
    'total_amount': {'en': 'Total Amount', 'bn': 'মোট পরিমাণ'},
    'total_budget_label': {'en': 'Total Budget Label', 'bn': 'মোট বাজেট'},
    'total_expense_label': {'en': 'Total Expense Label', 'bn': 'মোট ব্যয়'},
    'total_income_label': {'en': 'Total Income Label', 'bn': 'মোট আয়'},
    'total_spent_label': {'en': 'Total Spent Label', 'bn': 'মোট খরচ'},
    'total_transactions': {'en': 'Total Transactions', 'bn': 'মোট লেনদেন'},
    'track_debt_tip': {'en': 'Track Debt Tip', 'bn': 'ঋণ ও ধার ট্র্যাক করুন'},
    'unsupported_export_format': {
      'en': 'Unsupported Export Format',
      'bn': 'অসমর্থিত এক্সপোর্ট ফরম্যাট'
    },
    'unsupported_template_format': {
      'en': 'Unsupported Template Format',
      'bn': 'অসমর্থিত টেমপ্লেট ফরম্যাট'
    },
    'untitled': {'en': 'Untitled', 'bn': 'শিরোনামহীন'},
    'utilities': {'en': 'Utilities', 'bn': 'ইউটিলিটি'},
    'utilization': {'en': 'Utilization', 'bn': 'ব্যবহার হার'},
    'variance': {'en': 'Variance', 'bn': 'ভেরিয়েন্স'},
    'variance_label': {'en': 'Variance Label', 'bn': 'ভেরিয়েন্স'},
    'will_receive': {'en': 'Will Receive', 'bn': 'পাবেন'},
    'write_something': {'en': 'Write Something', 'bn': 'কিছু লিখুন'},
    'actual_spent': {'en': 'Actual Spent', 'bn': 'বাস্তবে খরচ'},
    'ai_suggestion_over_budget': {
      'en': 'AI Suggestion Over Budget',
      'bn': 'কোন কোন ক্যাটাগরি বাজেটের বেশি?'
    },
    'ai_suggestion_saving_tips': {
      'en': 'AI Suggestion Saving Tips',
      'bn': 'সঞ্চয় বাড়ানোর টিপস দাও'
    },
    'ai_suggestion_spending': {
      'en': 'AI Suggestion Spending',
      'bn': 'খরচের সারাংশ দাও'
    },
    'ai_suggestion_top_category': {
      'en': 'AI Suggestion Top Category',
      'bn': 'সবচেয়ে বেশি খরচের ক্যাটাগরি কোনটি?'
    },
    'ai_tip_budget_used': {
      'en': 'AI Tip Budget Used',
      'bn': 'আপনার বাজেটের {percent}% ব্যবহার হয়েছে'
    },
    'ai_tip_no_expense': {
      'en': 'AI Tip No Expense',
      'bn': 'আজ কোনো ব্যয় রেকর্ড হয়নি'
    },
    'ai_tip_over_budget': {
      'en': 'AI Tip Over Budget',
      'bn': '{category} ক্যাটাগরিতে বাজেট ছাড়িয়েছে'
    },
    'ai_tip_spent_so_far': {
      'en': 'AI Tip Spent So Far',
      'bn': 'এই মাসে এখন পর্যন্ত {amount} খরচ হয়েছে'
    },
    'app_version_detail': {
      'en': 'v1.0.0 (Build 1)',
      'bn': 'ভার্সন 1.0.0 (বিল্ড 1)'
    },
    'csv': {'en': 'CSV', 'bn': 'CSV'},
    'json': {'en': 'JSON', 'bn': 'JSON'},
    'unknown_initial': {'en': 'U', 'bn': '?'},
    'none': {'en': 'None', 'bn': 'কোনোটি নেই'},
    'bill_reminder_title': {'en': 'Bill Reminder', 'bn': 'বিল রিমাইন্ডার'},
    'bill_reminder_body': {
      'en': '{name} is due in 3 days. Amount: {amount}',
      'bn': '{name} এর পরিশোধের আর ৩ দিন বাকি। পরিমাণ: {amount}'
    },
    'bill_reminders_channel': {'en': 'Bill Reminders', 'bn': 'বিল রিমাইন্ডার'},
    'bill_reminders_channel_desc': {
      'en': 'Reminders for upcoming bill payments',
      'bn': 'আসন্ন বিল পরিশোধের রিমাইন্ডার'
    },
    'budget_alert_title': {'en': 'Budget Alert', 'bn': 'বাজেট সতর্কতা'},
    'budget_alert_body': {
      'en':
          'You\'ve spent {percent}% of your {category} budget ({spent} / {budget})',
      'bn': 'আপনি {category} বাজেটের {percent}% খরচ করেছেন ({spent} / {budget})'
    },
    'low_balance_alert_title': {
      'en': 'Low Balance Alert',
      'bn': 'কম ব্যালেন্স সতর্কতা'
    },
    'low_balance_alert_body': {
      'en': 'Your {account} balance is low: {amount}',
      'bn': 'আপনার {account} ব্যালেন্স কম: {amount}'
    },
    'debt_payment_due_title': {
      'en': 'Debt Payment Due',
      'bn': 'ঋণ পরিশোধ বাকি'
    },
    'debt_collection_due_title': {
      'en': 'Debt Collection Due',
      'bn': 'ঋণ আদায় বাকি'
    },
    'debt_payment_action_pay': {'en': 'Pay', 'bn': 'পরিশোধ করুন'},
    'debt_payment_action_collect': {'en': 'Collect', 'bn': 'আদায় করুন'},
    'debt_due_tomorrow': {'en': '{body} tomorrow', 'bn': '{body} আগামীকাল'},
    'debt_due_today': {'en': '{body} today', 'bn': '{body} আজ'},
    'debt_reminders_channel': {'en': 'Debt Reminders', 'bn': 'ঋণ রিমাইন্ডার'},
    'debt_reminders_channel_desc': {
      'en': 'Reminders for upcoming debt due dates',
      'bn': 'আসন্ন ঋণ পরিশোধ/আদায়ের রিমাইন্ডার'
    },
    'budget_alerts_channel': {'en': 'Budget Alerts', 'bn': 'বাজেট সতর্কতা'},
    'budget_alerts_channel_desc': {
      'en': 'Budget threshold warnings',
      'bn': 'বাজেট সীমা সতর্কবার্তা'
    },
    'sms_daily_summary_title': {
      'en': 'SMS Daily Summary',
      'bn': 'এসএমএস দৈনিক সারাংশ'
    },
    'sms_daily_summary_single': {
      'en': '1 transaction auto-imported today ({amount})',
      'bn': 'আজ ১টি লেনদেন স্বয়ংক্রিয়ভাবে ইমপোর্ট হয়েছে ({amount})'
    },
    'sms_daily_summary_multi': {
      'en': '{count} transactions auto-imported today ({amount})',
      'bn': 'আজ {count}টি লেনদেন স্বয়ংক্রিয়ভাবে ইমপোর্ট হয়েছে ({amount})'
    },
    'sms_tx_detected_title': {
      'en': 'SMS Transaction Detected',
      'bn': 'এসএমএস লেনদেন শনাক্ত'
    },
    'sms_tx_detected_body': {
      'en': '{action} {amount} - Tap to confirm or edit',
      'bn': '{action} {amount} - নিশ্চিত বা সম্পাদনা করতে ট্যাপ করুন'
    },
    'sms_action_received': {'en': 'Received', 'bn': 'প্রাপ্ত'},
    'sms_action_spent': {'en': 'Spent', 'bn': 'খরচ'},
    'debt_reminder_body': {
      'en': '{action} {amount} with {name}',
      'bn': '{name} এর সাথে {amount} {action}'
    },
    'transaction_entry': {'en': 'Transaction Entry', 'bn': 'লেনদেন এন্ট্রি'},
    'hide_amounts_on_hint': {
      'en': 'Amounts are now hidden across the app',
      'bn': 'অ্যাপ জুড়ে পরিমাণ এখন লুকানো আছে'
    },
    'hide_amounts_off_hint': {
      'en': 'Amounts are now visible across the app',
      'bn': 'অ্যাপ জুড়ে পরিমাণ এখন দৃশ্যমান'
    },
    'voice_transaction_input': {
      'en': 'Voice Input',
      'bn': 'ভয়েস ইনপুট'
    },
    'receipt_photo_option': {
      'en': 'Receipt Photo',
      'bn': 'রিসিপ্ট ছবি'
    },
    'gemini_api_key': {
      'en': 'Gemini API Key',
      'bn': 'জেমিনি এপিআই কী'
    },
    'gemini_key_desc': {
      'en': 'Configure AI assistant',
      'bn': 'এআই সহকারী কনফিগার করুন'
    },
    'gemini_key_info': {
      'en': 'Enter your Gemini API key to enable the AI assistant feature.',
      'bn': 'এআই সহকারী ফিচার চালু করতে আপনার জেমিনি এপিআই কী দিন।'
    },
    'api_key_saved': {
      'en': 'API key saved',
      'bn': 'এপিআই কী সেভ হয়েছে'
    },
    'login_tagline': {
      'en': 'Your personal finance companion\nfor smart money management',
      'bn': 'আপনার ব্যক্তিগত অর্থ ব্যবস্থাপনার\nস্মার্ট সহচর'
    },
    'login_feature_track': {'en': 'Track', 'bn': 'ট্র্যাক'},
    'login_feature_save': {'en': 'Save', 'bn': 'সঞ্চয়'},
    'login_feature_ai': {'en': 'AI', 'bn': 'এআই'},
    'get_started': {'en': 'Get Started', 'bn': 'শুরু করুন'},
    'continue_guest': {
      'en': 'Continue as Guest',
      'bn': 'গেস্ট হিসেবে চালিয়ে যান'
    },
    'login_terms_hint': {
      'en': 'By continuing, you agree to our Terms of Service\nand Privacy Policy',
      'bn': 'চালিয়ে যাওয়ার মানে আপনি আমাদের সেবার শর্তাবলী\nও গোপনীয়তা নীতি মেনে নিচ্ছেন'
    },
    'continue_with_email': {'en': 'Continue with Email', 'bn': 'ইমেইল দিয়ে চালিয়ে যান'},
    'continue_with_phone': {'en': 'Continue with Phone', 'bn': 'ফোন দিয়ে চালিয়ে যান'},
    'or': {'en': 'or', 'bn': 'অথবা'},
    'email_sign_in': {'en': 'Sign in with Email', 'bn': 'ইমেইল দিয়ে সাইন ইন'},
    'create_account': {'en': 'Create Account', 'bn': 'অ্যাকাউন্ট তৈরি করুন'},
    'password': {'en': 'Password', 'bn': 'পাসওয়ার্ড'},
    'sign_in': {'en': 'Sign In', 'bn': 'সাইন ইন'},
    'sign_up': {'en': 'Sign Up', 'bn': 'সাইন আপ'},
    'already_have_account': {'en': 'Already have an account? Sign in', 'bn': 'অ্যাকাউন্ট আছে? সাইন ইন করুন'},
    'create_new_account': {'en': "Don't have an account? Sign up", 'bn': 'অ্যাকাউন্ট নেই? সাইন আপ করুন'},
    'fill_all_fields': {'en': 'Please fill all fields', 'bn': 'সব ফিল্ড পূরণ করুন'},
    'phone_sign_in': {'en': 'Sign in with Phone', 'bn': 'ফোন দিয়ে সাইন ইন'},
    'phone_number': {'en': 'Phone Number', 'bn': 'ফোন নম্বর'},
    'send_otp': {'en': 'Send OTP', 'bn': 'OTP পাঠান'},
    'enter_valid_phone': {'en': 'Enter a valid phone number', 'bn': 'সঠিক ফোন নম্বর দিন'},
    'otp_sent_to': {'en': 'OTP sent to {phone}', 'bn': '{phone} এ OTP পাঠানো হয়েছে'},
    'enter_otp': {'en': 'Enter OTP', 'bn': 'OTP দিন'},
    'verify_otp': {'en': 'Verify OTP', 'bn': 'OTP যাচাই করুন'},
    'enter_valid_otp': {'en': 'Enter valid 6-digit OTP', 'bn': 'সঠিক ৬ সংখ্যার OTP দিন'},
  };
String t(String key, {Map<String, String>? params}) {
    final lang = locale.languageCode == 'bn' ? 'bn' : 'en';
    final map = _values[key];
    if (map == null) return key;
    var text = map[lang] ?? map['en'] ?? key;
    if (params != null) {
      params.forEach((k, v) => text = text.replaceAll('{$k}', v));
    }
    return text;
  }
}

extension AppL10nExt on BuildContext {
  String t(String key, {Map<String, String>? params}) {
    return AppL10n.of(this).t(key, params: params);
  }
}
