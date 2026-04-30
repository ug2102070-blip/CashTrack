import re, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'lib/core/l10n/app_l10n.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find all bn values that still contain '?' characters (corrupted) or mojibake
lines = content.split('\n')
issues = []
for i, line in enumerate(lines, 1):
    if "'bn':" in line:
        bn_match = re.search(r"'bn'\s*:\s*'(.*?)'", line)
        if bn_match:
            val = bn_match.group(1)
            if '?' in val and len(val) > 1:
                issues.append((i, val))
            elif '\u00c3' in val or '\u00c2' in val or '\u00e2\u0080' in val:
                issues.append((i, val))

print(f"Found {len(issues)} remaining corrupted entries:")
for line_no, val in issues:
    try:
        print(f"  Line {line_no}: [{repr(val)}]")
    except:
        print(f"  Line {line_no}: <encoding issue>")

# Check entries where bn == en (untranslated) - excluding known OK ones
ok_values = {'CashTrack', 'CSV', 'JSON', 'MFS', '+', '-'}
untranslated = []
for m in re.finditer(r"'([^']+)'\s*:\s*\{[^}]*'en'\s*:\s*'([^']+)'\s*,\s*'bn'\s*:\s*'([^']+)'", content):
    key = m.group(1)
    en_val = m.group(2)
    bn_val = m.group(3)
    if en_val == bn_val and en_val not in ok_values:
        pos = m.start()
        line_no = content[:pos].count('\n') + 1
        untranslated.append((line_no, key, en_val))

print(f"\nFound {len(untranslated)} untranslated (en==bn) entries:")
for line_no, key, val in untranslated:
    print(f"  Line {line_no}: key='{key}' value='{val}'")
