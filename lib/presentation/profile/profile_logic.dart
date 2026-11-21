// lib/presentation/profile/profile_logic.dart
//
// Pure helpers for the profile screen, kept out of the widget so they can be
// unit-tested.
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction_model.dart';
import '../../services/profile_store.dart';

/// Max lengths for free-text profile fields (prevents unbounded Hive values,
/// header overflow and Firestore rule rejections).
const Map<String, int> kProfileFieldMaxLength = ProfileStore.maxFieldLengths;

/// Longest edge of a stored profile photo. Raw camera images are several MB;
/// they are base64-stored in Hive and loaded at startup, so keep them small.
const double kProfilePhotoMaxDimension = 512;
const int kProfilePhotoQuality = 80;

/// Hard upper bound on the picked file (after picker resizing). 512 KiB of
/// JPEG is ~699 KB as base64, just under [ProfileStore.maxPhotoBase64Length]
/// so the photo can always sync.
const int kProfilePhotoMaxBytes = 512 * 1024;

/// DOB is persisted in a fixed, locale-independent format. Before this was
/// pinned, the value was written with `Intl.defaultLocale`, so Bangla users
/// stored Bangla month names that could not be parsed back in English.
final DateFormat _dobStorageFormat = DateFormat('dd MMM yyyy', 'en_US');

String formatDobForStorage(DateTime date) => _dobStorageFormat.format(date);

/// Parses a stored DOB, accepting the canonical English format, ISO-8601 and
/// legacy values written in the Bangla locale. Returns null if unparseable.
DateTime? parseStoredDob(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final attempts = <DateTime? Function()>[
    () => _dobStorageFormat.parseStrict(value),
    () => DateTime.tryParse(value),
    () => DateFormat('dd MMM yyyy', 'bn_BD').parseLoose(value),
    () => DateFormat('dd MMM yyyy', 'bn').parseLoose(value),
  ];
  for (final attempt in attempts) {
    try {
      final parsed = attempt();
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    } catch (_) {
      // Try the next format.
    }
  }
  return null;
}

/// Formats a stored DOB for display in the user's locale. Falls back to the
/// raw value so nothing the user entered is hidden.
String displayDob(String raw, String localeTag) {
  final parsed = parseStoredDob(raw);
  if (parsed == null) return raw.trim();
  try {
    return DateFormat.yMMMd(localeTag).format(parsed);
  } catch (_) {
    return formatDobForStorage(parsed);
  }
}

/// Removes spaces, dashes and parentheses users commonly type in numbers.
String normalizePhone(String raw) => raw.replaceAll(RegExp(r'[\s\-()]'), '');

/// Up to two initials. Uses grapheme clusters so Bangla names (with combining
/// vowel signs) are not split mid-character.
String profileInitials(String name, String fallback) {
  final parts =
      name.split(RegExp(r'\s+')).where((e) => e.trim().isNotEmpty).toList();
  if (parts.isEmpty) return fallback;
  final first = parts.first.characters.first.toUpperCase();
  if (parts.length == 1) return first;
  return first + parts.last.characters.first.toUpperCase();
}

/// True when any calendar month with income has a savings rate of at least
/// [minRatePercent]%. Integer (paisa) math only; transfers are ignored.
bool hasSavingsMonth(
  Iterable<TransactionModel> transactions, {
  int minRatePercent = 20,
}) {
  final income = <int, int>{};
  final expense = <int, int>{};
  for (final tx in transactions) {
    if (tx.isDeleted) continue;
    final monthKey = tx.date.year * 12 + tx.date.month;
    if (tx.type == TransactionType.income) {
      income[monthKey] = (income[monthKey] ?? 0) + tx.amount;
    } else if (tx.type == TransactionType.expense) {
      expense[monthKey] = (expense[monthKey] ?? 0) + tx.amount;
    }
  }
  for (final entry in income.entries) {
    final inc = entry.value;
    if (inc <= 0) continue;
    final saved = inc - (expense[entry.key] ?? 0);
    if (saved * 100 >= inc * minRatePercent) return true;
  }
  return false;
}
