import re, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'lib/core/l10n/app_l10n.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# These are multi-line entries where the key and 'bn' are on separate lines
remaining_fixes = {
    'daily_reminder_time_value': 'দৈনিক রিমাইন্ডার {time} এ',
    'bill_reminder_body': '{name} এর পরিশোধের আর ৩ দিন বাকি। পরিমাণ: {amount}',
    'budget_alert_body': 'আপনি {category} বাজেটের {percent}% খরচ করেছেন ({spent} / {budget})',
    'low_balance_alert_body': 'আপনার {account} ব্যালেন্স কম: {amount}',
    'debt_due_tomorrow': '{body} আগামীকাল',
    'debt_due_today': '{body} আজ',
    'sms_daily_summary_single': 'আজ ১টি লেনদেন স্বয়ংক্রিয়ভাবে ইমপোর্ট হয়েছে ({amount})',
    'sms_daily_summary_multi': 'আজ {count}টি লেনদেন স্বয়ংক্রিয়ভাবে ইমপোর্ট হয়েছে ({amount})',
    'sms_tx_detected_body': '{action} {amount} - নিশ্চিত বা সম্পাদনা করতে ট্যাপ করুন',
    'debt_reminder_body': '{name} এর সাথে {amount} {action}',
    'used_percent': '{value}% ব্যবহার',
    'active_goal_count': '{count}টি সক্রিয় লক্ষ্য{suffix}',
    'more_goals': '+{count}টি আরও লক্ষ্য',
    'due_count': '{count}টি বাকি',
    'more_transactions': '+{count}টি আরও লেনদেন',
    'days_left': '{count} দিন বাকি',
    'percent_completed': '{value}% সম্পন্ন',
    'to_go_amount': '{amount} বাকি',
    'add_money_to': '{name}-এ টাকা যোগ করুন',
    'added_amount_to_goal': '{name}-এ {amount} যোগ হয়েছে',
    'delete_account_confirm': "আপনি কি নিশ্চিত \\\"{name}\\\" মুছতে চান?",
    'suggested_amount': 'প্রস্তাবিত: {amount}',
    'error_with_detail': 'ত্রুটি: {error}',
    'edit_field': '{label} সম্পাদনা',
    'field_updated': '{label} আপডেট হয়েছে',
    'add_category_type': '{type} ক্যাটাগরি যোগ করুন',
    'delete_category_confirm': "আপনি কি নিশ্চিত \\\"{name}\\\" মুছতে চান?",
}

fixed = 0
for key, bn_val in remaining_fixes.items():
    # Use DOTALL to handle multi-line entries
    # Find the FIRST occurrence of this key in the _values map
    # Then find its 'bn': 'value' part
    key_pattern = re.compile(
        r"'" + re.escape(key) + r"'\s*:\s*\{",
        re.DOTALL
    )
    key_match = key_pattern.search(content)
    if not key_match:
        print(f"  WARNING: Could not find key '{key}'")
        continue
    
    # From the key position, find the closing brace
    start_pos = key_match.start()
    # Find 'bn': 'value' within the next few hundred chars
    substr = content[start_pos:start_pos+500]
    bn_pattern = re.compile(r"('bn'\s*:\s*)'((?:[^'\\]|\\.)*)'")
    bn_match = bn_pattern.search(substr)
    if not bn_match:
        # Try multi-line bn value
        bn_pattern2 = re.compile(r"('bn'\s*:\s*\n\s*)'((?:[^'\\]|\\.)*)'")
        bn_match = bn_pattern2.search(substr)
    
    if bn_match:
        abs_start = start_pos + bn_match.start()
        abs_end = start_pos + bn_match.end()
        old_bn = bn_match.group(2)
        new_segment = bn_match.group(1) + "'" + bn_val + "'"
        content = content[:abs_start] + new_segment + content[abs_end:]
        fixed += 1
        print(f"  Fixed '{key}'")
    else:
        print(f"  WARNING: Found key '{key}' but no bn value")

print(f"\nFixed {fixed} entries")

with open(r'lib/core/l10n/app_l10n.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
