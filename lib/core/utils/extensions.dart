// lib/core/utils/extensions.dart
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

// Date Extensions
extension DateTimeExtension on DateTime {
  String format([String pattern = AppConstants.dateFormat]) {
    return DateFormat(pattern).format(this);
  }

  String toTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} বছর আগে';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} মাস আগে';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} দিন আগে';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ঘন্টা আগে';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} মিনিট আগে';
    } else {
      return 'এখনই';
    }
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool isToday() {
    final now = DateTime.now();
    return isSameDay(now);
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(yesterday);
  }

  bool isThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return isAfter(startOfWeek) && isBefore(now.add(const Duration(days: 1)));
  }

  bool isThisMonth() {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
  DateTime get startOfMonth => DateTime(year, month, 1);
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);
}

// Double Extensions
extension DoubleExtension on double {
  String toCurrency({String symbol = AppConstants.currencySymbol}) {
    final formatter = NumberFormat('#,##,###.00', 'en_IN');
    return '$symbol${formatter.format(this)}';
  }

  String toCompact() {
    if (this >= 10000000) {
      return '${(this / 10000000).toStringAsFixed(1)} কোটি';
    } else if (this >= 100000) {
      return '${(this / 100000).toStringAsFixed(1)} লাখ';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)} হাজার';
    }
    return toStringAsFixed(0);
  }

  String toPercentage() {
    return '${toStringAsFixed(1)}%';
  }
}

// String Extensions
extension StringExtension on String {
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  bool get isValidPhone {
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(this);
  }

  bool get isValidBangladeshiPhone {
    return RegExp(r'^(?:\+?88)?01[3-9]\d{8}$').hasMatch(this);
  }

  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  bool containsAny(List<String> keywords) {
    final lower = toLowerCase();
    return keywords.any((keyword) => lower.contains(keyword.toLowerCase()));
  }
}

// BuildContext Extensions
extension BuildContextExtension on BuildContext {
  // Navigation shortcuts
  void pop([dynamic result]) => Navigator.of(this).pop(result);

  Future<T?> push<T>(Widget page) =>
      Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));

  // ফিক্সড: টাইপ আর্গুমেন্ট এবং রিটার্ন টাইপ ঠিক করা হয়েছে
  Future<T?> pushReplacement<T, TO>(Widget page) => Navigator.of(this)
      .pushReplacement<T, TO>(MaterialPageRoute(builder: (_) => page));

  // MediaQuery shortcuts
  Size get screenSize => MediaQuery.of(this).size;
  double get width => screenSize.width;
  double get height => screenSize.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  // Show SnackBar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show Loading Dialog
  void showLoadingDialog() {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  // Hide keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}

// List Extensions
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;

  List<T> distinctBy<R>(R Function(T) selector) {
    final seen = <R>{};
    return where((item) => seen.add(selector(item))).toList();
  }
}

// Color Extensions
extension ColorExtension on Color {
  String toHex() {
    // ফিক্সড: deprecated 'value' এর পরিবর্তে toARGB32() ব্যবহার করা হয়েছে
    return '#${toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
