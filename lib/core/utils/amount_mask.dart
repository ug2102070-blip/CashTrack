// lib/core/utils/amount_mask.dart
String formatAmount(
  String currency,
  double amount, {
  int decimals = 0,
  bool hide = false,
}) {
  if (hide) {
    // Keep currency visible so users know denomination; mask digits only (production-style).
    return '$currency\u00A0••••••';
  }
  return '$currency${amount.toStringAsFixed(decimals)}';
}

String formatSignedAmount(
  String currency,
  double amount, {
  int decimals = 0,
  bool hide = false,
}) {
  if (hide) {
    final sign = amount < 0 ? '-' : '+';
    return '$sign $currency\u00A0••••••';
  }
  final sign = amount < 0 ? '-' : '+';
  return '$sign $currency${amount.abs().toStringAsFixed(decimals)}';
}
