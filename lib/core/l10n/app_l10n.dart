import 'package:flutter/material.dart';

class AppL10n {
  AppL10n(this.locale);

  final Locale locale;

  static AppL10n of(BuildContext context) {
    return AppL10n(Localizations.localeOf(context));
  }

  static const _values = <String, Map<String, String>>{
    'error_required_field': {'en': 'This field is required', 'bn': 'এই ফিল্ডটি আবশ্যক'},
    'error_required_field_named': {'en': '{field} is required', 'bn': '{field} আবশ্যক'},
    'error_invalid_email': {'en': 'Invalid email address', 'bn': 'ইমেইল ঠিকানা সঠিক নয়'},
    'error_invalid_phone': {'en': 'Invalid phone number', 'bn': 'ফোন নম্বর সঠিক নয়'},
    'error_invalid_amount': {'en': 'Invalid amount', 'bn': 'পরিমাণ সঠিক নয়'},
    'error_amount_exceeds_max': {'en': 'Amount exceeds the maximum allowed', 'bn': 'পরিমাণ অনুমোদিত সীমার চেয়ে বেশি'},
    'analytics': {'en': 'Analytics', 'bn': 'বিশ্লেষণ'},
    'dashboard': {'en': 'Dashboard', 'bn': 'ড্যাশবোর্ড'},
    'good_morning': {'en': 'Good morning', 'bn': 'সুপ্রভাত'},
    'good_afternoon': {'en': 'Good afternoon', 'bn': 'শুভ অপরাহ্ন'},
    'good_evening': {'en': 'Good evening', 'bn': 'শুভ সন্ধ্যা'},
    'good_night': {'en': 'Good night', 'bn': 'শুভ রাত্রি'},
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
    'accounts_count': {'en': '{count} accounts', 'bn': '{count} অ্যাকাউন্ট'},
    'cash': {'en': 'Cash', 'bn': 'ক্যাশ'},
    'bank': {'en': 'Bank', 'bn': 'ব্যাংক'},
    'mfs': {'en': 'Mobile Wallet', 'bn': 'মোবাইল ওয়ালেট'},
    'credit_card': {'en': 'Credit Card', 'bn': 'ক্রেডিট কার্ড'},
    'online': {'en': 'Online', 'bn': 'অনলাইন'},
    'transfer': {'en': 'Transfer', 'bn': 'ট্রান্সফার'},
    'from_account': {'en': 'From', 'bn': 'যে অ্যাকাউন্ট থেকে'},
    'to_account': {'en': 'To', 'bn': 'যে অ্যাকাউন্টে'},
    'swap_accounts': {'en': 'Swap Accounts', 'bn': 'অ্যাকাউন্ট অদলবদল'},
    'source_dest_different': {
      'en': 'Source and destination accounts must be different',
      'bn': 'উৎস এবং গন্তব্য অ্যাকাউন্ট ভিন্ন হতে হবে'
    },
    'select_dest_account': {
      'en': 'Please select destination account',
      'bn': 'গন্তব্য অ্যাকাউন্ট নির্বাচন করুন'
    },
    'save_and_add_another': {
      'en': 'Save & Add Another',
      'bn': 'সেভ করে আরেকটি যোগ করুন'
    },
    'discard_unsaved_title': {
      'en': 'Discard unsaved changes?',
      'bn': 'পরিবর্তন বাতিল করবেন?'
    },
    'discard_unsaved_content': {
      'en': 'You have unsaved changes. Are you sure you want to discard them?',
      'bn': 'আপনার লেখা তথ্য সেভ করা হয়নি। আপনি কি বাতিল করে বের হতে চান?'
    },
    'discard': {'en': 'Discard', 'bn': 'বাতিল করুন'},
    'lent': {'en': 'Lent', 'bn': 'ধার দেওয়া'},
    'upcoming_bills': {'en': 'Upcoming Bills', 'bn': 'আসন্ন বিল'},
    'no_upcoming_bills': {
      'en': 'No upcoming bills in the next 30 days',
      'bn': 'আগামী ৩০ দিনে কোনো আসন্ন বিল নেই'
    },
    'smart_recommendations': {
      'en': 'Smart Recommendations',
      'bn': 'স্মার্ট আর্থিক পরামর্শ'
    },
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
    'no_income_month': {
      'en': 'No income data for this month',
      'bn': 'এই মাসে কোনো আয়ের তথ্য নেই'
    },
    'monthly_overview': {
      'en': 'Monthly Overview',
      'bn': 'মাসিক পর্যালোচনা'
    },
    'mom_spending_decreased': {
      'en': '{pct}% less spent than last month',
      'bn': 'গত মাসের চেয়ে {pct}% কম ব্যয়'
    },
    'mom_spending_increased': {
      'en': '{pct}% more spent than last month',
      'bn': 'গত মাসের চেয়ে {pct}% বেশি ব্যয়'
    },
    'mom_spending_same': {
      'en': 'Same spending as last month',
      'bn': 'গত মাসের সমান ব্যয়'
    },
    'accounts_breakdown': {
      'en': 'Accounts & Wallets Breakdown',
      'bn': 'অ্যাকাউন্ট ও ওয়ালেট বিশ্লেষণ'
    },
    'no_account_data': {
      'en': 'No account transaction data for this month',
      'bn': 'এই মাসে কোনো অ্যাকাউন্টের লেনদেন নেই'
    },
    'daily_pace_card_title': {
      'en': 'Daily Allowance & Pace',
      'bn': 'দৈনিক বরাদ্দ ও ব্যয়ের গতি'
    },
    'daily_pace_desc': {
      'en': 'Set a daily limit to track daily pace & rollover savings',
      'bn': 'দৈনিক খরচের সীমা নির্ধারণ করে গতি ও সঞ্চয় ট্র্যাক করুন'
    },
    'today_spent': {'en': 'Today Spent', 'bn': 'আজকের ব্যয়'},
    'daily_limit': {'en': 'Daily Limit', 'bn': 'দৈনিক সীমা'},
    'available_left': {'en': 'Available Left', 'bn': 'বাকি বরাদ্দ'},
    'over_target': {'en': 'over target', 'bn': 'সীমা অতিক্রম'},
    'available': {'en': 'available', 'bn': 'উপলব্ধ'},
    'month_avg_day': {'en': 'Month Avg/Day', 'bn': 'মাসের দৈনিক গড়'},
    'days_tracked': {
      'en': '{count} days tracked',
      'bn': '{count} দিন ট্র্যাক করা হয়েছে'
    },
    'allowance_usage': {'en': 'Allowance Usage', 'bn': 'বরাদ্দের ব্যবহার'},
    'above_target': {'en': 'Above Target', 'bn': 'লক্ষ্যের চেয়ে বেশি'},
    'exceeded_pace': {'en': 'Exceeded Pace', 'bn': 'গতিসীমা অতিক্রান্ত'},
    'savings_rollover': {'en': 'Savings Rollover', 'bn': 'সঞ্চিত বরাদ্দ'},
    'setup': {'en': 'Setup', 'bn': 'সেটআপ'},
    'view_type_donut': {'en': 'Donut', 'bn': 'ডোনাট'},
    'view_type_bar': {'en': 'Bar', 'bn': 'বার'},
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
    'emi_calculator': {'en': 'EMI Calculator', 'bn': 'ইএমআই ক্যালকুলেটর'},
    'loan_amount': {'en': 'Loan Amount', 'bn': 'ঋণের ভাড়া'},
    'interest_rate': {'en': 'Interest Rate (%)', 'bn': 'হারে সুদ (%)'},
    'tenure_months': {'en': 'Tenure (months)', 'bn': 'মেয়াদ (মাস)'},
    'monthly_emi': {'en': 'Monthly EMI', 'bn': 'মাসিক ইএমআই'},
    'total_interest': {'en': 'Total Interest', 'bn': 'মোট সুদ'},
    'total_payment': {'en': 'Total Payment', 'bn': 'মোট পরিশোধ'},
    'emi_schedule': {'en': 'EMI Schedule', 'bn': 'ইএমআই সময়সূচী'},
    'calculate_emi': {'en': 'Calculate EMI', 'bn': 'ইএমআই হিসাব করুন'},
    'enter_valid_loan_amount': {
      'en': 'Enter a valid loan amount',
      'bn': 'সঠিক ঋণের পরিমাণ লিখুন'
    },
    'enter_valid_interest_rate': {
      'en': 'Enter a valid interest rate',
      'bn': 'সঠিক সুদের হার লিখুন'
    },
    'enter_valid_tenure': {
      'en': 'Enter a valid tenure',
      'bn': 'সঠিক মেয়াদ লিখুন'
    },
    'split_expenses': {'en': 'Split Expenses', 'bn': 'বিল ভাগ করুন'},
    'split_groups': {'en': 'Split Groups', 'bn': 'বিল গ্রুপ'},
    'group_name': {'en': 'Group Name', 'bn': 'গ্রুপের নাম'},
    'group_members': {'en': 'Group Members', 'bn': 'গ্রুপ সদস্য'},
    'add_group': {'en': 'Add Group', 'bn': 'গ্রুপ যোগ করুন'},
    'create_group': {'en': 'Create Group', 'bn': 'গ্রুপ তৈরি করুন'},
    'members_comma_hint': {
      'en': 'Separate names with commas',
      'bn': 'নাম কমা দিয়ে আলাদা করুন'
    },
    'expense_description': {'en': 'Expense Description', 'bn': 'ব্যয়ের বিবরণ'},
    'paid_by': {'en': 'Paid by', 'bn': 'পরিশোধ করেছেন'},
    'split_among': {'en': 'Split among', 'bn': 'ভাগ করুন'},
    'add_expense': {'en': 'Add Expense', 'bn': 'ব্যয় যোগ করুন'},
    'total_spent': {'en': 'Total Spent', 'bn': 'মোট ব্যয়'},
    'your_share': {'en': 'Your Share', 'bn': 'আপনার ভাগ'},
    'settlement_summary': {
      'en': 'Settlement Summary',
      'bn': 'বিরাম সংক্ষিপ্তসার'
    },
    'owes': {'en': '{from} owes {to}', 'bn': '{from} দেবে {to}'},
    'you_owe': {'en': 'You owe {to}', 'bn': 'আপনি দেন {to}'},
    'owes_you': {'en': '{from} owes you', 'bn': '{from} আপনাকে দেয়'},
    'no_split_groups': {
      'en': 'No split groups yet',
      'bn': 'এখনো কোনো বিল গ্রুপ নেই'
    },
    'split_group_empty': {
      'en': 'Create a group to start splitting expenses',
      'bn': 'ব্যয় ভাগ করার জন্য একটি গ্রুপ তৈরি করুন'
    },
    'detected_subscriptions': {
      'en': 'Detected Subscriptions',
      'bn': 'সনাক্ত সাবস্ক্রিপশন'
    },
    'mark_as_recurring': {
      'en': 'Mark as recurring',
      'bn': 'পুনরাবৃত্তি হিসেবে চিহ্নিত করুন'
    },
    'detected_subscriptions_description': {
      'en': 'Auto-detected recurring payments from your transactions',
      'bn': 'আপনার লেনদেন থেকে স্বয়ংক্রিয়ভাবে সনাক্ত recurring পেমেন্ট'
    },
    'no_detected_subscriptions': {
      'en': 'No recurring subscriptions detected yet',
      'bn': 'এখনো কোনো recurring সাবস্ক্রিপশন সনাক্ত করা হয়নি'
    },
    'subscription_next_expected': {
      'en': 'Next expected',
      'bn': 'পরবর্তী প্রত্যাশিত'
    },
    'suscription_amount': {'en': 'Amount', 'bn': 'পরিমাণ'},
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
    'sms_permission_dialog_title': {
      'en': 'Auto-Import Transactions',
      'bn': 'স্বয়ংক্রিয় লেনদেন ইম্পোর্ট'
    },
    'sms_permission_dialog_body': {
      'en': 'CashTrack can auto-import your MFS transactions (like bKash, Nagad, Rocket, Upay) by reading payment notifications. This helps you track expenses automatically without manual entry!\n\nTo ensure 100% reliable tracking in the background, we will request to exclude CashTrack from battery optimization.\n\nIf you choose not to enable it now, you can always enable it later from Settings -> General -> SMS Auto-Import.',
      'bn': 'ক্যাশট্র্যাক আপনার পেমেন্ট নোটিফিকেশন পড়ে বিকাশ, নগদ, রকেট বা উপায়-এর মতো মোবাইল ব্যাংকিং লেনদেনগুলো স্বয়ংক্রিয়ভাবে অ্যাপে যোগ করতে পারে। এতে আপনার ম্যানুয়ালি কোনো লেনদেন লিখতে হবে না!\n\nব্যাকগ্রাউন্ডে ১০০% নিখুঁত ট্র্যাকিং নিশ্চিত করতে, আমরা অ্যাপটিকে ব্যাটারি অপ্টিমাইজেশন থেকে মুক্ত রাখার অনুমতি চাইব।\n\nআপনি যদি এখন এটি চালু করতে না চান, তবে পরবর্তীতে যেকোনো সময় সেটিংস -> সাধারণ -> এসএমএস অটো-ইমপোর্ট (Settings -> General -> SMS Auto-Import) থেকে এটি চালু করতে পারবেন।'
    },
    'sms_permission_dialog_allow': {
      'en': 'Enable Now',
      'bn': 'এখনই চালু করুন'
    },
    'sms_permission_dialog_deny': {
      'en': 'Maybe Later',
      'bn': 'পরে করব'
    },
    'background_running_tips': {
      'en': 'If auto-import stops working in the background on devices like Xiaomi, Samsung, or Vivo, please set App Info -> Battery -> \'Unrestricted\' and enable \'Autostart\' in system settings.',
      'bn': 'Xiaomi, Samsung বা Vivo-র মতো ফোনে ব্যাকগ্রাউন্ডে লেনদেন অটো-ইম্পোর্ট বন্ধ হয়ে গেলে, ফোন সেটিংস থেকে App Info -> Battery -> \'Unrestricted\' সিলেক্ট করুন এবং \'Autostart\' সচল রাখুন।'
    },
    'sms_web_not_supported_title': {
      'en': 'Mobile Only Feature',
      'bn': 'শুধুমাত্র মোবাইলে প্রযোজ্য'
    },
    'sms_web_not_supported_desc': {
      'en': 'SMS Auto-Import is only supported on mobile devices (Android) and is not available on the web version.',
      'bn': 'এসএমএস অটো-ইমপোর্ট ফিচারটি শুধুমাত্র মোবাইল ডিভাইসের (Android) জন্য প্রযোজ্য এবং এটি ওয়েব সংস্করণে কাজ করবে না।'
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
    'backup_local': {'en': 'Local Backup (JSON)', 'bn': 'লোকাল ব্যাকআপ (JSON)'},
    'backup_local_sub': {
      'en': 'Save full data backup file to device or Google Drive',
      'bn': 'ডিভাইস বা গুগল ড্রাইভে সম্পূর্ণ ব্যাকআপ ফাইল সেভ করুন'
    },
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
    'restore_local': {'en': 'Restore from File (JSON)', 'bn': 'ফাইল থেকে রিস্টোর (JSON)'},
    'restore_local_sub': {
      'en': 'Restore all records from a CashTrack JSON backup file',
      'bn': 'CashTrack JSON ব্যাকআপ ফাইল থেকে সব রেকর্ড রিস্টোর করুন'
    },
    'restore_data': {
      'en': 'Restore your data',
      'bn': 'আপনার ডেটা রিস্টোর করুন'
    },
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
    'help_improve': {'en': 'Help us improve', 'bn': 'উন্নত করতে সাহায্য করুন'},
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
    'of': {'en': 'of', 'bn': 'এর'},
    'financial_plans': {'en': 'Financial Plans', 'bn': 'আর্থিক পরিকল্পনা'},
    'tools_utilities': {'en': 'Tools & Utilities', 'bn': 'টুলস ও ইউটিলিটি'},
    'active_goals_short': {'en': 'active', 'bn': 'সক্রিয়'},
    'total_saved': {'en': 'Total Saved', 'bn': 'মোট সঞ্চয়'},
    'track_recurring': {'en': 'Track recurring', 'bn': 'পুনরাবৃত্ত খরচ ট্র্যাক'},
    'customize_categories': {'en': 'Customize categories', 'bn': 'ক্যাটাগরি কাস্টমাইজ করুন'},
    'download_reports': {'en': 'Download reports', 'bn': 'রিপোর্ট ডাউনলোড করুন'},
    'personal_notes': {'en': 'Personal notes', 'bn': 'ব্যক্তিগত নোট'},
    'net_balance': {'en': 'Net Balance', 'bn': 'নিট ব্যালেন্স'},
    'view': {'en': 'View', 'bn': 'দেখুন'},
    'manage_categories': {'en': 'Manage Categories', 'bn': 'ক্যাটাগরি পরিচালনা'},
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
    'percent_completed': {'en': '{value}% completed', 'bn': '{value}% সম্পন্ন'},
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
    'edit_savings_goal': {
      'en': 'Edit Savings Goal',
      'bn': 'সেভিংস লক্ষ্য সম্পাদনা'
    },
    'goal_created_success': {
      'en': 'Goal created successfully!',
      'bn': 'লক্ষ্য সফলভাবে তৈরি হয়েছে!'
    },
    'goal_updated_success': {
      'en': 'Goal updated successfully!',
      'bn': 'লক্ষ্য সফলভাবে আপডেট হয়েছে!'
    },
    'update': {'en': 'Update', 'bn': 'আপডেট'},
    'add_money_to': {
      'en': 'Add Money to {name}',
      'bn': '{name}-এ টাকা যোগ করুন'
    },
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
    'nickname_optional': {'en': 'Nickname (Optional)', 'bn': 'ডাকনাম (ঐচ্ছিক)'},
    'initial_balance': {'en': 'Initial Balance', 'bn': 'প্রাথমিক ব্যালেন্স'},
    'edit_account': {'en': 'Edit Account', 'bn': 'অ্যাকাউন্ট সম্পাদনা'},
    'delete_account': {'en': 'Delete Account', 'bn': 'অ্যাকাউন্ট মুছুন'},
    'delete_account_confirm': {
      'en': 'Are you sure you want to delete "{name}"?',
      'bn': 'আপনি কি নিশ্চিত "{name}" মুছতে চান?'
    },
    'account_deleted': {
      'en': 'Account deleted',
      'bn': 'অ্যাকাউন্ট মুছে ফেলা হয়েছে'
    },
    'balance': {'en': 'Balance', 'bn': 'ব্যালেন্স'},
    'edit': {'en': 'Edit', 'bn': 'সম্পাদনা'},
    'delete': {'en': 'Delete', 'bn': 'মুছুন'},
    'close': {'en': 'Close', 'bn': 'বন্ধ'},
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
    'account_info': {'en': 'Account Info', 'bn': 'অ্যাকাউন্ট তথ্য'},
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
    'uncategorized': {'en': 'Uncategorized', 'bn': 'শ্রেণীহীন'},
    'no_account': {'en': 'No Account', 'bn': 'কোন অ্যাকাউন্ট নেই'},
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
    'select_category': {
      'en': 'Select Category',
      'bn': 'ক্যাটাগরি নির্বাচন করুন'
    },
    'select_account': {
      'en': 'Select Account',
      'bn': 'অ্যাকাউন্ট নির্বাচন করুন'
    },
    'select_category_prompt': {
      'en': 'Select a category',
      'bn': 'ক্যাটাগরি নির্বাচন করুন'
    },
    'select_account_prompt': {
      'en': 'Select an account',
      'bn': 'অ্যাকাউন্ট নির্বাচন করুন'
    },
    'recurring_payment': {
      'en': 'Recurring payment',
      'bn': 'পুনরাবৃত্তি লেনদেন'
    },
    'default_recurring_payment': {
      'en': 'Default Recurring Payment',
      'bn': 'ডিফল্ট পুনরাবৃত্তি লেনদেন'
    },
    'recurring_frequency': {
      'en': 'Payment frequency',
      'bn': 'পেমেন্ট ফ্রিকোয়েন্সি'
    },
    'default_recurring_frequency': {
      'en': 'Default Recurring Frequency',
      'bn': 'ডিফল্ট পেমেন্ট ফ্রিকোয়েন্সি'
    },
    'on': {'en': 'On', 'bn': 'চালু'},
    'off': {'en': 'Off', 'bn': 'বন্ধ'},
    'daily': {'en': 'Daily', 'bn': 'দৈনিক'},
    'weekly': {'en': 'Weekly', 'bn': 'সাপ্তাহিক'},
    'monthly': {'en': 'Monthly', 'bn': 'মাসিক'},
    'yearly': {'en': 'Yearly', 'bn': 'বার্ষিক'},
    'subscription_calendar': {
      'en': 'Subscription Calendar',
      'bn': 'সাবস্ক্রিপশন ক্যালেন্ডার'
    },
    'upcoming_recurring_payments': {
      'en': 'Upcoming recurring payments',
      'bn': 'নির্ধারিত পুনরাবৃত্তি লেনদেন'
    },
    'recurring_payments_no_data': {
      'en': 'No recurring payments scheduled for this day.',
      'bn': 'এই দিনে কোনো পুনরাবৃত্তি লেনদেন নির্ধারিত নেই।'
    },
    'pin_category': {'en': 'Pin Category', 'bn': 'ক্যাটাগরি পিন করুন'},
    'unpin_category': {'en': 'Unpin Category', 'bn': 'ক্যাটাগরি আনপিন করুন'},
    'pin_account': {'en': 'Pin Account', 'bn': 'অ্যাকাউন্ট পিন করুন'},
    'unpin_account': {'en': 'Unpin Account', 'bn': 'অ্যাকাউন্ট আনপিন করুন'},
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
    'select_date_range': {
      'en': 'Select date range',
      'bn': 'তারিখ পরিসর নির্বাচন করুন'
    },
    'clear_date_filter': {
      'en': 'Clear date filter',
      'bn': 'তারিখ ফিল্টার মুছুন'
    },
    'transaction_deleted': {
      'en': 'Transaction deleted',
      'bn': 'লেনদেন মুছে ফেলা হয়েছে'
    },
    'add_new_category': {
      'en': 'Add New Category',
      'bn': 'নতুন ক্যাটাগরি যোগ করুন'
    },
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
    'category_deleted': {
      'en': 'Category deleted',
      'bn': 'ক্যাটাগরি মুছে ফেলা হয়েছে'
    },
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
      'en': 'AI service is not configured. Please set your API key.',
      'bn': 'এআই সার্ভিস কনফিগার করা নেই। অনুগ্রহ করে এপিআই কী সেট করুন।'
    },
    'ai_service_error_backend': {
      'en': 'AI service error. Please check your backend configuration.',
      'bn':
          'এআই সার্ভিসে সমস্যা হয়েছে। অনুগ্রহ করে ব্যাকএন্ড কনফিগারেশন চেক করুন।'
    },
    'ai_service_error_api_key': {
      'en': 'AI service error. Please check your API key.',
      'bn':
          'এআই সার্ভিসে সমস্যা হয়েছে। অনুগ্রহ করে আপনার এপিআই কী চেক করুন।'
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
    'borrowed': {'en': 'Borrowed', 'bn': 'ধার নেওয়া'},
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
    'login_failed': {
      'en': 'Login failed: {error}',
      'bn': 'লগইন ব্যর্থ: {error}'
    },
    'low_balance': {'en': 'Low Balance', 'bn': 'কম ব্যালেন্স'},
    'low_balance_body': {
      'en': 'Your balance is {amount}. Consider controlling your expenses.',
      'bn': 'আপনার ব্যালেন্স {amount}। খরচ নিয়ন্ত্রণ করুন।'
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
    'paid_of_total': {
      'en': '{paid} / {total} paid',
      'bn': '{paid} / {total} পরিশোধিত'
    },
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
    'voice_transaction_input': {'en': 'Voice Input', 'bn': 'ভয়েস ইনপুট'},
    'receipt_photo_option': {'en': 'Receipt Photo', 'bn': 'রিসিপ্ট ছবি'},
    'gemini_api_key': {'en': 'AI API Key', 'bn': 'এআই এপিআই কী'},
    'gemini_key_desc': {
      'en': 'Configure AI assistant',
      'bn': 'এআই সহকারী কনফিগার করুন'
    },
    'gemini_key_info': {
      'en': 'Enter your API key to enable the AI assistant feature.',
      'bn': 'এআই সহকারী ফিচার চালু করতে আপনার এপিআই কী দিন।'
    },
    'api_key_saved': {'en': 'API key saved', 'bn': 'এপিআই কী সেভ হয়েছে'},
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
      'en':
          'By continuing, you agree to our Terms of Service\nand Privacy Policy',
      'bn':
          'চালিয়ে যাওয়ার মানে আপনি আমাদের সেবার শর্তাবলী\nও গোপনীয়তা নীতি মেনে নিচ্ছেন'
    },
    'continue_with_email': {
      'en': 'Continue with Email',
      'bn': 'ইমেইল দিয়ে চালিয়ে যান'
    },
    'continue_with_phone': {
      'en': 'Continue with Phone',
      'bn': 'ফোন দিয়ে চালিয়ে যান'
    },
    'or': {'en': 'or', 'bn': 'অথবা'},
    'password_strength_weak': {'en': 'Weak', 'bn': 'দুর্বল'},
    'password_strength_fair': {'en': 'Fair', 'bn': 'মোটামুটি'},
    'password_strength_good': {'en': 'Good', 'bn': 'ভালো'},
    'password_strength_strong': {'en': 'Strong', 'bn': 'শক্তিশালী'},
    'create_your_account': {
      'en': 'Create your account to get started',
      'bn': 'শুরু করতে অ্যাকাউন্ট তৈরি করুন'
    },
    'welcome_back': {
      'en': 'Welcome back! Sign in to continue',
      'bn': 'স্বাগতম! চালিয়ে যেতে সাইন ইন করুন'
    },
    'confirm_password': {
      'en': 'Confirm Password',
      'bn': 'পাসওয়ার্ড নিশ্চিত করুন'
    },
    'invalid_email': {
      'en': 'Please enter a valid email address',
      'bn': 'একটি সঠিক ইমেইল দিন'
    },
    'reset_link_sent': {
      'en': 'Password reset link sent! Check your email.',
      'bn': 'পাসওয়ার্ড রিসেট লিঙ্ক পাঠানো হয়েছে! ইমেইল চেক করুন।'
    },
    'forgot_password': {
      'en': 'Forgot Password?',
      'bn': 'পাসওয়ার্ড ভুলে গেছেন?'
    },
    'password_too_short': {
      'en': 'Password must be at least 6 characters',
      'bn': 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষর হতে হবে'
    },
    'passwords_dont_match': {
      'en': 'Passwords do not match',
      'bn': 'পাসওয়ার্ড মিলছে না'
    },
    'phone_not_available_web': {
      'en':
          'Phone sign-in is not available on web. Please use Email or Guest sign-in.',
      'bn':
          'ওয়েবে ফোন সাইন-ইন পাওয়া যায় না। অনুগ্রহ করে ইমেইল বা গেস্ট সাইন-ইন ব্যবহার করুন।'
    },
    'email_sign_in': {'en': 'Sign in with Email', 'bn': 'ইমেইল দিয়ে সাইন ইন'},
    'create_account': {'en': 'Create Account', 'bn': 'অ্যাকাউন্ট তৈরি করুন'},
    'password': {'en': 'Password', 'bn': 'পাসওয়ার্ড'},
    'sign_in': {'en': 'Sign In', 'bn': 'সাইন ইন'},
    'sign_up': {'en': 'Sign Up', 'bn': 'সাইন আপ'},
    'already_have_account': {
      'en': 'Already have an account? Sign in',
      'bn': 'অ্যাকাউন্ট আছে? সাইন ইন করুন'
    },
    'create_new_account': {
      'en': "Don't have an account? Sign up",
      'bn': 'অ্যাকাউন্ট নেই? সাইন আপ করুন'
    },
    'fill_all_fields': {
      'en': 'Please fill all fields',
      'bn': 'সব ফিল্ড পূরণ করুন'
    },
    'phone_sign_in': {'en': 'Sign in with Phone', 'bn': 'ফোন দিয়ে সাইন ইন'},
    'phone_number': {'en': 'Phone Number', 'bn': 'ফোন নম্বর'},
    'send_otp': {'en': 'Send OTP', 'bn': 'OTP পাঠান'},
    'enter_valid_phone': {
      'en': 'Enter a valid phone number',
      'bn': 'সঠিক ফোন নম্বর দিন'
    },
    'otp_sent_to': {
      'en': 'OTP sent to {phone}',
      'bn': '{phone} এ OTP পাঠানো হয়েছে'
    },
    'enter_otp': {'en': 'Enter OTP', 'bn': 'OTP দিন'},
    'verify_otp': {'en': 'Verify OTP', 'bn': 'OTP যাচাই করুন'},
    'enter_valid_otp': {
      'en': 'Enter valid 6-digit OTP',
      'bn': 'সঠিক ৬ সংখ্যার OTP দিন'
    },
    // Google Sign-In
    'continue_with_google': {
      'en': 'Continue with Google',
      'bn': 'Google দিয়ে চালিয়ে যান'
    },
    // Investments
    'investments': {'en': 'Investments', 'bn': 'বিনিয়োগ'},
    'add_investment': {'en': 'Add Investment', 'bn': 'বিনিয়োগ যোগ করুন'},
    'edit_investment': {'en': 'Edit Investment', 'bn': 'বিনিয়োগ সম্পাদনা'},
    'investment_name': {'en': 'Investment Name', 'bn': 'বিনিয়োগের নাম'},
    'total_invested': {'en': 'Invested', 'bn': 'বিনিয়োগ'},
    'total_returns': {'en': 'Returns', 'bn': 'রিটার্ন'},
    'mutual_fund': {'en': 'Mutual Fund', 'bn': 'মিউচুয়াল ফান্ড'},
    'stock': {'en': 'Stock', 'bn': 'শেয়ার'},
    'fixed_deposit': {'en': 'Fixed Deposit', 'bn': 'ফিক্সড ডিপোজিট'},
    'gold_inv': {'en': 'Gold', 'bn': 'সোনা'},
    'dps': {'en': 'DPS', 'bn': 'ডিপিএস'},
    'others_type': {'en': 'Others', 'bn': 'অন্যান্য'},
    'expected_return': {
      'en': 'Expected Return (%)',
      'bn': 'প্রত্যাশিত রিটার্ন (%)'
    },
    'start_date': {'en': 'Start Date', 'bn': 'শুরুর তারিখ'},
    'maturity_date': {'en': 'Maturity Date', 'bn': 'মেয়াদ শেষ'},
    'no_investments_yet': {
      'en': 'No investments yet',
      'bn': 'এখনো কোনো বিনিয়োগ নেই'
    },
    'add_first_investment': {
      'en': 'Track your investments here',
      'bn': 'আপনার বিনিয়োগ এখানে ট্র্যাক করুন'
    },
    'delete_investment': {'en': 'Delete Investment', 'bn': 'বিনিয়োগ মুছুন'},
    'delete_investment_confirm': {
      'en': 'Are you sure you want to delete this investment?',
      'bn': 'আপনি কি নিশ্চিত এই বিনিয়োগ মুছতে চান?'
    },
    // Assets
    'assets_title': {'en': 'Assets', 'bn': 'সম্পদ'},
    'add_asset': {'en': 'Add Asset', 'bn': 'সম্পদ যোগ করুন'},
    'edit_asset': {'en': 'Edit Asset', 'bn': 'সম্পদ সম্পাদনা'},
    'asset_name': {'en': 'Asset Name', 'bn': 'সম্পদের নাম'},
    'asset_category': {'en': 'Category', 'bn': 'ক্যাটাগরি'},
    'asset_tracker': {'en': 'Asset Tracker', 'bn': 'সম্পদ ট্র্যাকার'},
    'purchase_price': {'en': 'Purchase Price', 'bn': 'ক্রয়মূল্য'},
    'purchase_value': {'en': 'Purchase', 'bn': 'ক্রয়মূল্য'},
    'appreciation': {'en': 'Growth', 'bn': 'মূল্যবৃদ্ধি'},
    'purchase_date': {'en': 'Purchase Date', 'bn': 'ক্রয়ের তারিখ'},
    'warranty_expiry': {'en': 'Warranty', 'bn': 'ওয়ারেন্টি'},
    'warranty_active': {'en': 'Warranty Active', 'bn': 'ওয়ারেন্টি আছে'},
    'no_assets_yet': {'en': 'No assets yet', 'bn': 'এখনো কোনো সম্পদ নেই'},
    'add_first_asset': {
      'en': 'Track your valuable assets',
      'bn': 'আপনার মূল্যবান সম্পদ ট্র্যাক করুন'
    },
    'total_asset_value': {'en': 'Total Value', 'bn': 'মোট মূল্য'},
    'delete_asset': {'en': 'Delete Asset', 'bn': 'সম্পদ মুছুন'},
    'delete_asset_confirm': {
      'en': 'Are you sure you want to delete this asset?',
      'bn': 'আপনি কি নিশ্চিত এই সম্পদ মুছতে চান?'
    },
    // ── Smart Debt Agreement System ──────────────────────
    'smart_agreements': {'en': 'Smart Agreements', 'bn': 'স্মার্ট চুক্তি'},
    'debt_agreements': {'en': 'Debt Agreements', 'bn': 'ঋণ চুক্তি'},
    'create_agreement': {'en': 'Create Agreement', 'bn': 'চুক্তি তৈরি করুন'},
    'agreement_details': {'en': 'Agreement Details', 'bn': 'চুক্তির বিবরণ'},
    'agreement_terms': {'en': 'Agreement Terms', 'bn': 'চুক্তির শর্তাবলী'},
    'agreement_terms_hint': {
      'en': 'e.g. Must repay within deadline, 2% daily penalty applies...',
      'bn': 'যেমন: ডেডলাইনের মধ্যে ফেরত দিতে হবে, ২% দৈনিক জরিমানা...'
    },
    'penalty_rate': {
      'en': 'Daily Penalty Rate (%)',
      'bn': 'দৈনিক জরিমানা হার (%)'
    },
    'penalty_amount': {'en': 'Penalty Amount', 'bn': 'জরিমানার পরিমাণ'},
    'no_penalty': {'en': 'No penalty', 'bn': 'কোনো জরিমানা নেই'},
    'phone_number_optional': {
      'en': 'Phone Number (Optional)',
      'bn': 'ফোন নম্বর (ঐচ্ছিক)'
    },
    'payment_method': {'en': 'Payment Method', 'bn': 'পেমেন্ট পদ্ধতি'},
    'select_payment_method': {
      'en': 'Select Payment Method',
      'bn': 'পেমেন্ট পদ্ধতি নির্বাচন করুন'
    },
    'enable_agreement': {
      'en': 'Enable Smart Agreement',
      'bn': 'স্মার্ট চুক্তি সক্রিয় করুন'
    },
    'agreement_enabled': {
      'en': 'Digital contract with terms',
      'bn': 'শর্তসহ ডিজিটাল চুক্তি'
    },
    // Agreement Status
    'status_pending': {'en': 'Pending', 'bn': 'অপেক্ষমাণ'},
    'status_accepted': {'en': 'Accepted', 'bn': 'গৃহীত'},
    'status_rejected': {'en': 'Rejected', 'bn': 'প্রত্যাখ্যাত'},
    'status_expired': {'en': 'Overdue', 'bn': 'মেয়াদোত্তীর্ণ'},
    'status_completed': {'en': 'Completed', 'bn': 'সম্পন্ন'},
    // Trust Score
    'trust_score': {'en': 'Trust Score', 'bn': 'বিশ্বাস স্কোর'},
    'trust_excellent': {'en': 'Excellent', 'bn': 'চমৎকার'},
    'trust_good': {'en': 'Good', 'bn': 'ভালো'},
    'trust_average': {'en': 'Average', 'bn': 'মোটামুটি'},
    'trust_poor': {'en': 'Poor', 'bn': 'খারাপ'},
    'trust_very_poor': {'en': 'Very Poor', 'bn': 'অত্যন্ত খারাপ'},
    // Countdown & Deadline
    'days_remaining': {
      'en': '{count} days remaining',
      'bn': '{count} দিন বাকি'
    },
    'hours_remaining': {
      'en': '{count} hours remaining',
      'bn': '{count} ঘণ্টা বাকি'
    },
    'overdue_days': {
      'en': 'Overdue by {count} days',
      'bn': '{count} দিন অতিক্রান্ত'
    },
    'deadline_today': {'en': 'Deadline is today!', 'bn': 'আজ ডেডলাইন!'},
    'no_deadline': {'en': 'No deadline set', 'bn': 'কোনো ডেডলাইন নেই'},
    // Actions
    'send_reminder': {'en': 'Send Reminder', 'bn': 'রিমাইন্ডার পাঠান'},
    'reminder_sent': {
      'en': 'Reminder sent!',
      'bn': 'রিমাইন্ডার পাঠানো হয়েছে!'
    },
    'reminders_sent_count': {
      'en': '{count} reminders sent',
      'bn': '{count}টি রিমাইন্ডার পাঠানো হয়েছে'
    },
    'view_agreement': {'en': 'View Agreement', 'bn': 'চুক্তি দেখুন'},
    'mark_as_paid': {'en': 'Mark as Paid', 'bn': 'পরিশোধিত হিসেবে চিহ্নিত'},
    'generate_payment_link': {'en': 'Payment Link', 'bn': 'পেমেন্ট লিঙ্ক'},
    'payment_link_copied': {
      'en': 'Payment link copied!',
      'bn': 'পেমেন্ট লিঙ্ক কপি হয়েছে!'
    },
    'calculate_penalty': {'en': 'Calculate Penalty', 'bn': 'জরিমানা গণনা'},
    // Summary
    'active_agreements': {'en': 'Active Agreements', 'bn': 'সক্রিয় চুক্তি'},
    'total_lent': {'en': 'Total Lent', 'bn': 'মোট ধার দেওয়া'},
    'total_borrowed': {'en': 'Total Borrowed', 'bn': 'মোট ধার নেওয়া'},
    'total_penalty': {'en': 'Total Penalty', 'bn': 'মোট জরিমানা'},
    'overdue_count': {
      'en': '{count} overdue',
      'bn': '{count}টি মেয়াদোত্তীর্ণ'
    },
    // Agreement View
    'agreement_contract': {
      'en': 'DEBT AGREEMENT CONTRACT',
      'bn': 'ঋণ চুক্তি চুক্তিপত্র'
    },
    'lender': {'en': 'Lender', 'bn': 'ঋণদাতা'},
    'borrower': {'en': 'Borrower', 'bn': 'ঋণগ্রহীতা'},
    'principal_amount': {'en': 'Principal Amount', 'bn': 'মূল অর্থ'},
    'agreed_deadline': {'en': 'Agreed Deadline', 'bn': 'সম্মত সময়সীমা'},
    'penalty_clause': {'en': 'Penalty Clause', 'bn': 'জরিমানা ধারা'},
    'daily_penalty_after_deadline': {
      'en': '{rate}% daily penalty after deadline',
      'bn': 'ডেডলাইনের পর দৈনিক {rate}% জরিমানা'
    },
    'agreement_created_on': {
      'en': 'Agreement created on {date}',
      'bn': 'চুক্তি তৈরি হয়েছে {date}'
    },
    'me': {'en': 'Me', 'bn': 'আমি'},
    // Tab labels
    'all': {'en': 'All', 'bn': 'সব'},
    'lent_tab': {'en': 'Lent', 'bn': 'ধার দিয়েছি'},
    'borrowed_tab': {'en': 'Borrowed', 'bn': 'ধার নিয়েছি'},
    'overdue_tab': {'en': 'Overdue', 'bn': 'মেয়াদোত্তীর্ণ'},
    // Manual Penalty
    'add_penalty': {'en': 'Add Penalty', 'bn': 'জরিমানা যোগ করুন'},
    'add_penalty_hint': {
      'en':
          'Add a penalty amount for late payment. This will be added to the existing penalty.',
      'bn':
          'দেরিতে পরিশোধের জন্য জরিমানা যোগ করুন। এটি বিদ্যমান জরিমানায় যোগ হবে।'
    },
    'penalty_added': {'en': 'Penalty added', 'bn': 'জরিমানা যোগ হয়েছে'},
    'current_penalty': {'en': 'Current penalty', 'bn': 'বর্তমান জরিমানা'},
    'agreement_sms_sent': {
      'en': 'Agreement SMS sent',
      'bn': 'চুক্তির SMS পাঠানো হয়েছে'
    },
    // EMI Calculator additions
    'principal': {'en': 'Principal', 'bn': 'মূলধন'},
    'interest': {'en': 'Interest', 'bn': 'সুদ'},
    'emi_balance': {'en': 'Balance', 'bn': 'অবশিষ্ট'},
    'month_label': {'en': 'Month', 'bn': 'মাস'},
    'loan_breakdown': {'en': 'Loan Breakdown', 'bn': 'ঋণ বিশ্লেষণ'},
    'emi_empty_title': {'en': 'Calculate Your EMI', 'bn': 'আপনার ইএমআই হিসাব করুন'},
    'emi_empty_subtitle': {
      'en': 'Enter loan details above to see your monthly payment and full amortization schedule',
      'bn': 'মাসিক পরিশোধ ও সম্পূর্ণ পরিশোধ সময়সূচী দেখতে উপরে ঋণের বিবরণ দিন'
    },
    'interest_amount': {'en': 'Interest Amount', 'bn': 'সুদের পরিমাণ'},
    'email_verification_sent': {
      'en': 'Account created! A verification link has been sent to your email. Please verify it before logging in.',
      'bn': 'অ্যাকাউন্ট তৈরি হয়েছে! আপনার ইমেইলে একটি ভেরিফিকেশন লিংক পাঠানো হয়েছে। লগইন করার আগে অনুগ্রহ করে এটি ভেরিফাই করুন।'
    },
    'email_not_verified': {
      'en': 'Your email is not verified yet. A new verification link has been sent to your email.',
      'bn': 'আপনার ইমেইলটি এখনও ভেরিফাই করা হয়নি। আপনার ইমেইলে একটি নতুন ভেরিফিকেশন লিংক পাঠানো হয়েছে।'
    },
    'verify_email_title': {
      'en': 'Verify Your Email',
      'bn': 'আপনার ইমেইল ভেরিফাই করুন'
    },
    'verify_email_sent_msg': {
      'en': 'We have sent a verification link to your email. Please click the link to verify your account.',
      'bn': 'আমরা আপনার ইমেইলে একটি ভেরিফিকেশন লিংক পাঠিয়েছি। আপনার অ্যাকাউন্টটি ভেরিফাই করতে অনুগ্রহ করে লিংকটিতে ক্লিক করুন।'
    },
    'verify_email_instructions': {
      'en': 'Once verified, click the button below to access CashTrack.',
      'bn': 'ভেরিফাই করা হয়ে গেলে, ক্যাশট্র্যাকে প্রবেশ করতে নিচের বাটনে ক্লিক করুন।'
    },
    'i_have_verified': {
      'en': 'I Have Verified',
      'bn': 'আমি ভেরিফাই করেছি'
    },
    'resend_email': {
      'en': 'Resend Email',
      'bn': 'পুনরায় লিংক পাঠান'
    },
    'log_out': {
      'en': 'Log Out',
      'bn': 'লগ আউট'
    },
    'verification_link_resent': {
      'en': 'Verification link has been resent.',
      'bn': 'ভেরিফিকেশন লিংক পুনরায় পাঠানো হয়েছে।'
    },
    'dps_calculator_title': {'en': 'DPS Calculator', 'bn': 'ডিপিএস ক্যালকুলেটর'},
    'dps_calculator_subtitle': {'en': 'Maturity, Interest & Source Tax (AIT)', 'bn': 'মুনাফা, কর (AIT) ও মোট জমার হিসাব'},
    'net_maturity_amount': {'en': 'Net Maturity Amount', 'bn': 'কর কর্তন পরবর্তী মোট টাকা'},
    'total_deposit': {'en': 'Total Deposit', 'bn': 'মোট জমা টাকা'},
    'net_profit': {'en': 'Net Profit', 'bn': 'নিট মুনাফা'},
    'monthly_deposit': {'en': 'Monthly Deposit', 'bn': 'প্রতি মাসের কিস্তি'},
    'annual_interest_rate': {'en': 'Annual Interest Rate', 'bn': 'বার্ষিক মুনাফার হার'},
    'tenure_years': {'en': 'Tenure (Years)', 'bn': 'মেয়াদ (বছর)'},
    'has_tin_proof': {'en': 'TIN / Return Proof Submitted', 'bn': 'TIN ও রিটার্ন দাখিলের প্রমাণপত্র আছে'},
    'no_tin_proof': {'en': 'No Return Proof (Higher Tax)', 'bn': 'রিটার্ন প্রুফ নেই (উচ্চ হারে কর)'},
    'tax_rate_5': {'en': '5% AIT will be deducted on profit', 'bn': 'মুনাফার ওপর ৫% উৎসে কর (AIT) প্রযোজ্য'},
    'tax_rate_10': {'en': '10% AIT will be deducted on profit', 'bn': 'মুনাফার ওপর ১০% উৎসে কর (AIT) প্রযোজ্য'},
    'gross_interest_and_ait': {'en': 'Gross Interest & Tax Deduction', 'bn': 'মোট মুনাফা ও উৎসে কর কর্তন'},
    'gross_profit': {'en': 'Gross Profit', 'bn': 'গ্রস মুনাফা'},
    'source_tax': {'en': 'Source Tax (AIT)', 'bn': 'উৎসে কর (AIT)'},
    'yearly_growth_schedule': {'en': 'Yearly Growth Schedule', 'bn': 'বছরভিত্তিক প্রবৃদ্ধি বিবরণী'},
    'compound_growth': {'en': 'Monthly Compounding', 'bn': 'মাসিক চক্রবৃদ্ধি'},
    'deposit': {'en': 'Deposit', 'bn': 'জমা'},
    'dps_interest': {'en': 'Profit', 'bn': 'মুনাফা'},
    'save_as_investment': {'en': 'Save as Investment', 'bn': 'বিনিয়োগ হিসেবে সেভ করুন'},
    'save_dps_desc': {'en': 'This will record this DPS plan into your active Investments list.', 'bn': 'এই ডিপিএস প্ল্যানটি আপনার সক্রিয় বিনিয়োগ তালিকায় যুক্ত হবে।'},
    'save_sanchaya_desc': {'en': 'This will record this Sanchayapatra certificate into your Investments.', 'bn': 'এই সঞ্চয়পত্র সার্টিফিকেটটি আপনার সক্রিয় বিনিয়োগে যুক্ত হবে।'},
    'investment_saved_success': {'en': 'Investment saved successfully!', 'bn': 'বিনিয়োগ সফলভাবে যুক্ত হয়েছে!'},
    'sanchayapatra_calculator_title': {'en': 'Sanchayapatra Calculator', 'bn': 'সঞ্চয়পত্র ক্যালকুলেটর'},
    'sanchayapatra_calculator_subtitle': {'en': 'National Savings Certificate Schemes & Tax', 'bn': 'জাতীয় সঞ্চয়পত্র স্কিম ও মুনাফার হিসাব'},
    'scheme_paribar': {'en': 'Paribar (5-Yr)', 'bn': 'পরিবার সঞ্চয়পত্র (৫ বছর)'},
    'scheme_three_month': {'en': '3-Month Profit (3-Yr)', 'bn': '৩ মাস অন্তর (৩ বছর)'},
    'scheme_pensioner': {'en': 'Pensioner (5-Yr)', 'bn': 'পেনশনার সঞ্চয়পত্র (৫ বছর)'},
    'scheme_general_5yr': {'en': 'Bangladesh 5-Yr', 'bn': 'বাংলাদেশ সঞ্চয়পত্র (৫ বছর)'},
    'net_monthly_profit': {'en': 'Net Monthly Profit', 'bn': 'মাসিক নিট মুনাফা'},
    'net_quarterly_profit': {'en': 'Net Quarterly Profit', 'bn': 'ত্রৈমাসিক নিট মুনাফা'},
    'net_maturity_profit': {'en': 'Net Maturity Profit', 'bn': 'মেয়াদান্তে মোট নিট মুনাফা'},
    'effective_rate': {'en': 'Effective Rate', 'bn': 'কার্যকর মুনাফার হার'},
    'total_profit_3yr': {'en': 'Total 3-Yr Profit', 'bn': '৩ বছরে মোট মুনাফা'},
    'total_profit_5yr': {'en': 'Total 5-Yr Profit', 'bn': '৫ বছরে মোট মুনাফা'},
    'investment_amount': {'en': 'Investment Amount', 'bn': 'বিনিয়োগের পরিমাণ'},
    'scheme_details_and_tax': {'en': 'Scheme Details & Tax Slab', 'bn': 'স্কিমের বিবরণ ও উৎসে কর (AIT)'},
    'gross_payout': {'en': 'Gross Profit Payout', 'bn': 'গ্রস মুনাফা প্রদান'},
    'source_tax_ait': {'en': 'AIT Tax Deduction', 'bn': 'উৎসে কর (AIT) কর্তন'},
    'net_payout': {'en': 'Net Take-Home Payout', 'bn': 'হাতে পাওয়ার মতো নিট মুনাফা'},
    'zakat_calculator_title': {'en': 'Zakat Calculator', 'bn': 'যাকাত ক্যালকুলেটর'},
    'zakat_calculator_subtitle': {'en': '1-Tap Auto-Sync & 2.5% Calculation', 'bn': '১-ট্যাপ অটো-সিঙ্ক ও ২.৫% যাকাতের হিসাব'},
    'auto_sync': {'en': 'Auto Sync', 'bn': 'অটো সিঙ্ক'},
    'total_zakat_due_2_5': {'en': 'Total Zakat Due (2.5%)', 'bn': 'মোট প্রদেয় যাকাত (২.৫%)'},
    'nisab_reached': {'en': 'Nisab Reached (Eligible)', 'bn': 'নিসাব পূর্ণ (যাকাত ফরজ)'},
    'below_nisab': {'en': 'Below Nisab (Not Obligatory)', 'bn': 'নিসাবের নিচে (অপরিহার্য নয়)'},
    'net_zakatable_wealth': {'en': 'Net Zakatable Wealth', 'bn': 'যাকাতযোগ্য নিট সম্পদ'},
    'nisab_threshold': {'en': 'Nisab Threshold', 'bn': 'নিসাব সীমা'},
    'record_zakat_payment': {'en': 'Record as Expense Transaction', 'bn': 'খরচ ট্রানজেকশনে যুক্ত করুন'},
    'nisab_benchmark': {'en': 'Nisab Benchmark', 'bn': 'নিসাব স্ট্যান্ডার্ড'},
    'silver_standard': {'en': 'Silver (52.5 Bhori)', 'bn': 'রুপা (৫২.৫ ভরি)'},
    'gold_standard': {'en': 'Gold (7.5 Bhori)', 'bn': 'স্বর্ণ (৭.৫ ভরি)'},
    'silver_price_bhori': {'en': 'Silver Price / Bhori', 'bn': 'প্রতি ভরি রুপার বাজারমূল্য'},
    'gold_price_bhori': {'en': 'Gold Price / Bhori', 'bn': 'প্রতি ভরি স্বর্ণের বাজারমূল্য'},
    'nisab_quantity': {'en': 'Nisab Quantity', 'bn': 'নিসাব পরিমাপ'},
    'zakatable_assets': {'en': 'Zakatable Assets', 'bn': 'যাকাতযোগ্য সম্পদসমূহ'},
    'cash_and_bank_balances': {'en': 'Cash in Hand & Bank Balances', 'bn': 'নগদ ক্যাশ ও ব্যাংক ব্যালেন্স'},
    'gold_silver_holdings': {'en': 'Gold & Silver Valuations', 'bn': 'স্বর্ণ ও রুপার মূল্য'},
    'investments_stocks_mutual_funds': {'en': 'Investments, Shares & Mutual Funds', 'bn': 'শেয়ার, মিউচুয়াল ফান্ড ও বিনিয়োগ'},
    'business_inventory_goods': {'en': 'Business Stock / Merchandise', 'bn': 'ব্যবসার পণ্য ও মালামাল'},
    'money_lent_receivable': {'en': 'Receivable Loans (Money Lent)', 'bn': 'অন্যের কাছে পাওনা টাকা'},
    'deductible_liabilities': {'en': 'Deductible Liabilities', 'bn': 'বাদযোগ্য দেনা বা ঋণ'},
    'debts_and_loans_due': {'en': 'Immediate Debts & Loans Due', 'bn': 'জরুরি প্রদেয় দেনা ও ঋণ'},
    'due_utility_living_expenses': {'en': 'Due Utility Bills & Obligations', 'bn': 'বকেয়া ইউটিলিটি বিল ও খরচ'},
    'scan_receipt': {'en': 'Scan Receipt / Memo', 'bn': 'রসিদ / মেমো স্ক্যান'},
    'scan_receipt_hint': {'en': 'Auto-extract amount, merchant, date & category', 'bn': 'অ্যামাউন্ট, মার্চেন্ট, তারিখ ও ক্যাটাগরি স্বয়ংক্রিয় পূরণ'},
    'scanning_receipt': {'en': 'Analyzing receipt with AI...', 'bn': 'এআই দিয়ে রসিদ বিশ্লেষণ হচ্ছে...'},
    'receipt_scan_success': {'en': 'Receipt details extracted!', 'bn': 'রসিদের তথ্য সফলভাবে পাওয়া গেছে!'},
    'shopping_planner': {'en': 'Shopping & Grocery Planner', 'bn': 'বাজার ও শপিং প্ল্যানার'},
    'shopping_planner_sub': {'en': 'Create bazaar lists & convert to expense', 'bn': 'বাজারের ফর্দ ও ১-ক্লিকে খরচে রূপান্তর'},
    'utility_bills': {'en': 'Utility Bills & Reminders', 'bn': 'ইউটিলিটি বিল ও রিমাইন্ডার'},
    'utility_bills_sub': {'en': 'Electricity, Gas, WiFi & Rent bills', 'bn': 'বিদ্যুৎ, গ্যাস, ইন্টারনেট ও ভাড়ার হিসাব'},
    'bangladesh_financial_hub': {'en': 'Bangladesh Financial Hub', 'bn': 'বাংলাদেশ ফিনান্সিয়াল হাব'},
    'bd_tools_desc': {'en': 'DPS, Sanchayapatra & Zakat calculators', 'bn': 'ডিপিএস, সঞ্চয়পত্র ও যাকাত ক্যালকুলেটর'},
    'add_new_bill': {'en': 'Add new bill', 'bn': 'নতুন বিল যোগ করুন'},
    'no_utility_bills_added': {'en': 'No utility bills added', 'bn': 'কোনো ইউটিলিটি বিল যোগ করা নেই'},
    'add_first_bill': {'en': 'Add your first bill', 'bn': 'প্রথম বিল যোগ করুন'},
    'current_month_utility_bill': {'en': 'Current Month Utility Bill', 'bn': 'চলতি মাসের ইউটিলিটি বিল'},
    'due_bills_count': {'en': '{count} bills due', 'bn': '{count}টি বিল বাকি'},
    'all_bills_paid': {'en': 'All bills paid', 'bn': 'সব বিল পরিশোধিত'},
    'paid_amount': {'en': 'Paid: ৳{amount}', 'bn': 'পরিশোধিত: ৳{amount}'},
    'due_amount': {'en': 'Due: ৳{amount}', 'bn': 'বাকি: ৳{amount}'},
    'every_month_date': {'en': 'Every month on {date}', 'bn': 'প্রতি মাসের {date} তারিখ'},
    'pay': {'en': 'Pay', 'bn': 'পরিশোধ করুন'},
    'mark_as_unpaid': {'en': 'Mark as unpaid', 'bn': 'বকেয়া হিসেবে চিহ্নিত করুন'},
    'budget_expense_summary': {'en': 'Budget & Expense Summary', 'bn': 'বাজেট ও খরচের সারসংক্ষেপ'},
    'items_completed_count': {'en': '{completed}/{total} completed', 'bn': '{completed}/{total} সম্পন্ন'},
    'estimated_budget': {'en': 'Estimated Budget', 'bn': 'আনুমানিক বাজেট'},
    'shopping_done': {'en': 'Shopping Done', 'bn': 'কেনাকাটা হয়েছে'},
    'add_total_expense_1click': {'en': 'Add total expense in 1-click', 'bn': '১-ক্লিকে মোট খরচ এন্ট্রিতে যোগ করুন'},
    'add_item': {'en': 'Add Item', 'bn': 'আইটেম যোগ করুন'},
    'no_items_in_list': {'en': 'No items in list yet', 'bn': 'লিস্টে এখনো কোনো আইটেম নেই'},
    'add_first_item': {'en': 'Add first item', 'bn': 'প্রথম আইটেম যোগ করুন'},
    'new_list': {'en': 'New List', 'bn': 'নতুন লিস্ট'},
    'recurring_transactions': {'en': 'Recurring Transactions', 'bn': 'নিয়মিত লেনদেন'},
    'recurring_processed_title': {'en': 'Recurring Transactions Auto-Posted', 'bn': 'নিয়মিত লেনদেন স্বয়ংক্রিয়ভাবে যুক্ত হয়েছে'},
    'recurring_processed_body': {'en': '{count} recurring transactions have been posted to your accounts.', 'bn': '{count}টি নিয়মিত লেনদেন স্বয়ংক্রিয়ভাবে আপনার অ্যাকাউন্টে যুক্ত হয়েছে।'},
    'statement_import_preview': {'en': 'Statement Import Preview', 'bn': 'স্টেটমেন্ট ইমপোর্ট প্রিভিউ'},
    'detected_format': {'en': 'Detected Format', 'bn': 'শনাক্তকৃত ফরম্যাট'},
    'select_target_account': {'en': 'Select Target Account', 'bn': 'টার্গেট অ্যাকাউন্ট নির্বাচন করুন'},
    'selected_items': {'en': '{selected} of {total} selected', 'bn': '{total}টির মধ্যে {selected}টি নির্বাচিত'},
    'already_imported': {'en': 'Possible Duplicate', 'bn': 'সম্ভাব্য ডুপ্লিকেট'},
    'import_selected_btn': {'en': 'Import {count} Transactions', 'bn': '{count}টি লেনদেন ইমপোর্ট করুন'},
    'net_worth': {'en': 'Net Worth', 'bn': 'নিট সম্পদ'},
    'daily_safe_spend': {'en': 'Daily Safe to Spend', 'bn': 'দৈনিক নিরাপদ খরচ'},
    'days_left_in_month': {'en': '{days} days left', 'bn': 'বাকি {days} দিন'},
    'wealth_overview': {'en': 'Wealth Overview', 'bn': 'সম্পদের সার্বিক চিত্র'},
    'total_receivables': {'en': 'Receivables (Lent)', 'bn': 'অন্যের কাছে পাওনা'},
    'total_liabilities': {'en': 'Liabilities (Debts)', 'bn': 'মোট দেনা ও দায়'},
    'total_assets_wealth': {'en': 'Total Assets & Inv.', 'bn': 'মোট সম্পদ ও বিনিয়োগ'},
    'critical': {'en': 'Critical', 'bn': 'ঝুঁকিপূর্ণ'},
    'no_debts': {'en': 'No active debts', 'bn': 'কোনো দেনা নেই'},
    'rename_list': {'en': 'Rename List', 'bn': 'লিস্টের নাম পরিবর্তন'},
    'delete_list': {'en': 'Delete List', 'bn': 'লিস্ট মুছুন'},
    'edit_item': {'en': 'Edit Item', 'bn': 'আইটেম পরিবর্তন করুন'},
    'actual_price': {'en': 'Actual Price (৳)', 'bn': 'প্রকৃত খরচ (৳)'},
    'confirm_delete_list': {'en': 'Are you sure you want to delete this list?', 'bn': 'আপনি কি এই লিস্টটি মুছে ফেলতে চান?'},
    // ── Settings screen audit (2026-11) ──
    'settings_last_cloud_backup': {'en': 'Last backup: {time}', 'bn': 'শেষ ব্যাকআপ: {time}'},
    'settings_backup_failed': {'en': 'Backup failed. Please try again.', 'bn': 'ব্যাকআপ ব্যর্থ হয়েছে। আবার চেষ্টা করুন।'},
    'settings_restore_complete': {'en': 'Restore complete', 'bn': 'রিস্টোর সম্পন্ন হয়েছে'},
    'settings_restore_failed': {'en': 'Restore failed. Check your connection and try again.', 'bn': 'রিস্টোর ব্যর্থ হয়েছে। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।'},
    'settings_sign_in_required_cloud': {'en': 'Sign in with an account to use cloud backup', 'bn': 'ক্লাউড ব্যাকআপ ব্যবহার করতে অ্যাকাউন্টে সাইন ইন করুন'},
    'settings_operation_in_progress': {'en': 'Please wait for the current operation to finish', 'bn': 'চলমান কাজটি শেষ হওয়া পর্যন্ত অপেক্ষা করুন'},
    'settings_restoring': {'en': 'Restoring…', 'bn': 'রিস্টোর হচ্ছে…'},
    'settings_backing_up': {'en': 'Backing up…', 'bn': 'ব্যাকআপ হচ্ছে…'},
    'settings_current_pin': {'en': 'Current PIN', 'bn': 'বর্তমান পিন'},
    'settings_new_pin': {'en': 'New PIN', 'bn': 'নতুন পিন'},
    'settings_pin_current_wrong': {'en': 'Current PIN is incorrect', 'bn': 'বর্তমান পিন সঠিক নয়'},
    'settings_pin_save_failed': {'en': 'Could not update PIN. Please try again.', 'bn': 'পিন আপডেট করা যায়নি। আবার চেষ্টা করুন।'},
    'settings_change_password': {'en': 'Change Password', 'bn': 'পাসওয়ার্ড পরিবর্তন'},
    'settings_change_password_sub': {'en': 'Get a secure reset link by email', 'bn': 'ইমেইলে নিরাপদ রিসেট লিংক পান'},
    'settings_change_password_confirm': {'en': 'We will send a password reset link to {email}. Continue?', 'bn': '{email} ঠিকানায় পাসওয়ার্ড রিসেট লিংক পাঠানো হবে। চালিয়ে যাবেন?'},
    'settings_send_link': {'en': 'Send Link', 'bn': 'লিংক পাঠান'},
    'settings_reset_link_sent': {'en': 'Reset link sent to {email}', 'bn': '{email} ঠিকানায় রিসেট লিংক পাঠানো হয়েছে'},
    'settings_reset_link_failed': {'en': 'Could not send reset link. Check your connection and try again.', 'bn': 'রিসেট লিংক পাঠানো যায়নি। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।'},
    'settings_sign_out_failed': {'en': 'Sign out failed. Please try again.', 'bn': 'সাইন আউট ব্যর্থ হয়েছে। আবার চেষ্টা করুন।'},
    'settings_sms_disabled_no_permission': {'en': 'SMS Auto-Import has been disabled as permission was not granted.', 'bn': 'এসএমএস অটো-ইমপোর্ট অনুমতি না পাওয়ায় এটি বন্ধ করা হয়েছে।'},
    'settings_background_tips_title': {'en': 'Background Run Tips', 'bn': 'ব্যাকগ্রাউন্ড রানিং টিপস'},
    'settings_weekly_report_on': {'en': 'A weekly income vs expense summary arrives about once a week, around 9 AM', 'bn': 'প্রায় সপ্তাহে একবার, সকাল ৯টার দিকে আয়-ব্যয়ের সামারি নোটিফিকেশন আসবে'},
    'settings_weekly_report_enabled': {'en': 'Weekly summary enabled — it will arrive about once a week', 'bn': 'সাপ্তাহিক সামারি চালু হয়েছে — প্রায় সপ্তাহে একবার আসবে'},
    'ok': {'en': 'OK', 'bn': 'ঠিক আছে'},
    'pin_attempts_left': {'en': 'Incorrect PIN. {count} attempt(s) left before a temporary lock', 'bn': 'ভুল পিন। সাময়িক লকের আগে আর {count} বার চেষ্টা করা যাবে'},
    'pin_locked_out': {'en': 'Too many wrong attempts. Try again in {time}', 'bn': 'অনেকবার ভুল পিন দেওয়া হয়েছে। {time} পর আবার চেষ্টা করুন'},
    'settings_delete_account': {'en': 'Delete Account', 'bn': 'অ্যাকাউন্ট মুছে ফেলুন'},
    'settings_delete_account_sub': {'en': 'Permanently delete your account and all data', 'bn': 'অ্যাকাউন্ট ও সব ডেটা স্থায়ীভাবে মুছে ফেলুন'},
    'settings_delete_account_q': {'en': 'Delete your account?', 'bn': 'অ্যাকাউন্ট মুছে ফেলবেন?'},
    'settings_delete_account_body': {'en': 'This permanently deletes your CashTrack account, all cloud backups, and all data on this device: transactions, accounts, budgets, goals, debts, notes and receipts. This cannot be undone. Export a backup first if you want to keep a copy.', 'bn': 'এটি আপনার CashTrack অ্যাকাউন্ট, সব ক্লাউড ব্যাকআপ এবং এই ডিভাইসের সব ডেটা স্থায়ীভাবে মুছে ফেলবে: লেনদেন, অ্যাকাউন্ট, বাজেট, লক্ষ্য, দেনা, নোট ও রিসিপ্ট। এটি আর ফেরানো যাবে না। কপি রাখতে চাইলে আগে ব্যাকআপ এক্সপোর্ট করুন।'},
    'settings_delete_permanently': {'en': 'Delete Permanently', 'bn': 'স্থায়ীভাবে মুছুন'},
    'settings_account_deleted': {'en': 'Your account has been deleted', 'bn': 'আপনার অ্যাকাউন্ট মুছে ফেলা হয়েছে'},
    'settings_delete_account_failed': {'en': 'Could not delete your account. Check your connection and try again. Nothing was deleted.', 'bn': 'অ্যাকাউন্ট মুছে ফেলা যায়নি। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন। কিছুই মোছা হয়নি।'},
    'settings_reauth_expired': {'en': 'For your security, please confirm your identity again and retry.', 'bn': 'নিরাপত্তার জন্য আবার পরিচয় নিশ্চিত করে চেষ্টা করুন।'},
    'settings_reauth_wrong': {'en': 'Incorrect password', 'bn': 'পাসওয়ার্ড সঠিক নয়'},
    'settings_reauth_mismatch': {'en': 'Please choose the same Google account you are signed in with', 'bn': 'যে Google অ্যাকাউন্টে সাইন ইন করা আছে সেটিই বেছে নিন'},
    'settings_reauth_too_many': {'en': 'Too many attempts. Please try again later.', 'bn': 'অনেকবার চেষ্টা করা হয়েছে। পরে আবার চেষ্টা করুন।'},
    'settings_reauth_failed': {'en': 'Could not confirm your identity. Please try again.', 'bn': 'পরিচয় নিশ্চিত করা যায়নি। আবার চেষ্টা করুন।'},
    'settings_confirm_identity': {'en': 'Confirm your identity', 'bn': 'পরিচয় নিশ্চিত করুন'},
    'settings_enter_password_to_continue': {'en': 'Enter your password to continue.', 'bn': 'চালিয়ে যেতে আপনার পাসওয়ার্ড দিন।'},
    'settings_password': {'en': 'Password', 'bn': 'পাসওয়ার্ড'},
    'settings_continue': {'en': 'Continue', 'bn': 'চালিয়ে যান'},
    'once': {'en': 'Once', 'bn': 'একবার'},
    'settings_sign_out_registered_body': {'en': 'Your data will be backed up to your account, then removed from this device. Sign in again to get it back.', 'bn': 'আপনার ডেটা অ্যাকাউন্টে ব্যাকআপ হবে, তারপর এই ডিভাইস থেকে মুছে যাবে। আবার সাইন ইন করলে ফিরে পাবেন।'},
    'settings_sign_out_guest_body': {'en': 'You are using a guest account. Signing out permanently deletes all data on this device, and it cannot be recovered. Export a backup first if you want to keep it.', 'bn': 'আপনি গেস্ট অ্যাকাউন্ট ব্যবহার করছেন। সাইন আউট করলে এই ডিভাইসের সব ডেটা স্থায়ীভাবে মুছে যাবে এবং আর ফিরে পাওয়া যাবে না। রাখতে চাইলে আগে ব্যাকআপ এক্সপোর্ট করুন।'},
    'settings_backup_failed_title': {'en': 'Backup failed', 'bn': 'ব্যাকআপ ব্যর্থ হয়েছে'},
    'settings_sign_out_backup_failed_body': {'en': 'Your latest changes could not be backed up (check your internet connection). If you sign out now, changes not yet backed up will be permanently deleted from this device.', 'bn': 'আপনার সাম্প্রতিক পরিবর্তনগুলো ব্যাকআপ করা যায়নি (ইন্টারনেট সংযোগ দেখুন)। এখন সাইন আউট করলে ব্যাকআপ না হওয়া পরিবর্তনগুলো এই ডিভাইস থেকে স্থায়ীভাবে মুছে যাবে।'},
    'settings_erase_and_sign_out': {'en': 'Erase & Sign Out', 'bn': 'মুছে সাইন আউট'},
    'settings_export_backup_first': {'en': 'Export Backup', 'bn': 'ব্যাকআপ এক্সপোর্ট'},
    'settings_push_permission_required': {'en': 'Push notifications permission is required', 'bn': 'পুশ নোটিফিকেশন পারমিশন প্রয়োজন'},
    'settings_turn_on_push_first': {'en': 'Turn on Push Notifications first', 'bn': 'Push Notifications চালু করুন'},
    'settings_sms_notif_permission_required': {'en': 'Notification permission is required to ask for transaction confirmation', 'bn': 'লেনদেন নিশ্চিতকরণের জন্য নোটিফিকেশন পারমিশন প্রয়োজন'},
    'settings_battery_optimization_warning': {'en': 'Battery optimization is active. Auto-import might not be 100% reliable in the background.', 'bn': 'ব্যাটারি অপ্টিমাইজেশন সচল থাকায় ব্যাকগ্রাউন্ডে লেনদেন ট্র্যাকিং বিঘ্নিত হতে পারে।'},
    'settings_app_tagline': {'en': 'Personal Finance Manager', 'bn': 'ব্যক্তিগত অর্থ ব্যবস্থাপনা অ্যাপ'},
    'settings_privacy_body': {'en': 'CashTrack stores your financial data locally on your device. Cloud backups only happen when you explicitly enable them.', 'bn': 'CashTrack আপনার আর্থিক ডেটা স্থানীয়ভাবে ডিভাইসে সংরক্ষণ করে। ক্লাউড ব্যাকআপ শুধুমাত্র আপনার অনুমতিতে হয়।'},
    'settings_terms_body': {'en': 'This app is for personal finance tracking. You are responsible for reviewing imported data and keeping your own backups.', 'bn': 'এই অ্যাপটি ব্যক্তিগত অর্থ ট্র্যাকিংয়ের জন্য। আমদানি করা ডেটা যাচাই করা এবং ব্যাকআপ রাখা আপনার দায়িত্ব।'},
    'settings_restore_local_body': {'en': 'Restore all accounts, budgets, and transactions from a CashTrack JSON backup file.', 'bn': 'আপনার সিলেক্ট করা CashTrack JSON ফাইল থেকে সমস্ত অ্যাকাউন্ট ও লেনদেন রিস্টোর হবে।'},
    'settings_voice_input_sub': {'en': 'Shows a mic button in the transaction form to capture amount and note', 'bn': 'ট্রানজ্যাকশন ফর্মে মাইক বাটন দেখাবে এবং ভয়েস থেকে amount/note নিতে পারবে'},
    'settings_receipt_option_sub': {'en': 'Lets users attach a receipt image from camera or gallery', 'bn': 'ট্রানজ্যাকশনের সাথে ক্যামেরা/গ্যালারি থেকে রিসিপ্ট যোগ করা যাবে'},
    'settings_screenshot_protection_sub': {'en': 'Blocks screenshots and recent-app previews on Android', 'bn': 'Android এ sensitive screen-এর screenshot ও recent preview ব্লক করবে'},
    'settings_export_sub': {'en': 'Export your data as CSV, JSON or PDF', 'bn': 'CSV, JSON বা PDF আকারে ডেটা এক্সপোর্ট করুন'},
    'settings_terms_sub': {'en': 'A short summary of usage expectations', 'bn': 'ব্যবহার ও দায়িত্ব সম্পর্কিত সংক্ষিপ্ত তথ্য'},
    'settings_accent_color_sub': {'en': 'Choose the accent color you want across the app', 'bn': 'একটি অ্যাকসেন্ট রঙ বেছে নিন'},
    'settings_export_csv_sub': {'en': 'Opens in Excel or Google Sheets', 'bn': 'Excel / Google Sheets এ ওপেন করা যাবে'},
    'settings_export_pdf_sub': {'en': 'Ready to print or share', 'bn': 'প্রিন্ট বা শেয়ার করার জন্য উপযুক্ত'},
    'settings_export_json_sub': {'en': 'Full data backup format', 'bn': 'সম্পূর্ণ ডেটা ব্যাকআপ ফরম্যাট'},
    'settings_screenshot_maybe_unsupported': {'en': 'This device may not fully support screenshot protection', 'bn': 'এই ডিভাইসে screenshot protection পুরোপুরি support নাও করতে পারে'},
    'settings_hide_amounts_sub_on': {'en': 'Balances and reports stay masked until you reveal them', 'bn': 'ড্যাশবোর্ড, প্রোফাইল ও রিপোর্টে টাকার অঙ্ক লুকানো থাকবে'},
    'settings_hide_amounts_sub_off': {'en': 'Balances and reports stay visible across the app', 'bn': 'ব্যালেন্স ও রিপোর্টের অঙ্ক স্বাভাবিকভাবে দেখা যাবে'},
    'settings_push_sub_on': {'en': 'Daily reminders, alerts and weekly summaries can appear', 'bn': 'রিমাইন্ডার, বাজেট অ্যালার্ট ও সাপ্তাহিক সামারি নোটিফিকেশন আসবে'},
    'settings_push_sub_off': {'en': 'When off, the app will not show local notifications', 'bn': 'বন্ধ থাকলে অ্যাপের কোনো লোকাল নোটিফিকেশন দেখাবে না'},
    'settings_voice_toggled_on': {'en': 'Voice input is enabled in the transaction form', 'bn': 'ট্রানজ্যাকশন ফর্মে ভয়েস ইনপুট চালু হয়েছে'},
    'settings_voice_toggled_off': {'en': 'Voice input has been turned off', 'bn': 'ভয়েস ইনপুট বন্ধ করা হয়েছে'},
    'settings_receipt_toggled_on': {'en': 'Receipt image support is enabled', 'bn': 'রিসিপ্ট ছবি অপশন চালু হয়েছে'},
    'settings_receipt_toggled_off': {'en': 'Receipt image support has been turned off', 'bn': 'রিসিপ্ট ছবি অপশন বন্ধ করা হয়েছে'},
    'settings_weekly_report_off': {'en': 'No weekly summary notification will be sent', 'bn': 'বন্ধ থাকলে সাপ্তাহিক সামারি নোটিফিকেশন যাবে না'},
    'settings_daily_reminder_label': {'en': 'Daily reminder time: {time}', 'bn': 'দৈনিক রিমাইন্ডার সময়: {time}'},
    'settings_restore_local_success': {'en': 'Successfully restored {count} records from backup!', 'bn': 'সফলভাবে {count} টি রেকর্ড রিস্টোর করা হয়েছে!'},
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
