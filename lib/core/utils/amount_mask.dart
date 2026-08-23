// lib/core/utils/amount_mask.dart
String formatAmount(
  String currency,
  num amountInPaisa, {
  int decimals = 0,
  bool hide = false,
}) {
  if (hide) {
    // Keep currency visible so users know denomination; mask digits only (production-style).
    return '$currency\u00A0••••••';
  }
  return '$currency${(amountInPaisa / 100).toStringAsFixed(decimals)}';
}

String formatSignedAmount(
  String currency,
  num amountInPaisa, {
  int decimals = 0,
  bool hide = false,
}) {
  if (hide) {
    final sign = amountInPaisa < 0 ? '-' : '+';
    return '$sign $currency\u00A0••••••';
  }
  final sign = amountInPaisa < 0 ? '-' : '+';
  return '$sign $currency${(amountInPaisa.abs() / 100).toStringAsFixed(decimals)}';
}
