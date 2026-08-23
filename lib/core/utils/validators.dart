// lib/core/utils/validators.dart
import 'package:flutter/material.dart';
import '../l10n/app_l10n.dart';

class Validators {
  static String? required(BuildContext context, String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null 
          ? context.t('error_required_field_named', params: {'field': fieldName})
          : context.t('error_required_field');
    }
    return null;
  }

  static String? email(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.t('error_required_field');
    }
    final isValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
    if (!isValid) {
      return context.t('error_invalid_email');
    }
    return null;
  }

  static String? phone(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is often optional, use required() first if mandatory
    }
    final isValid = RegExp(r'^(?:\+?88)?01[3-9]\d{8}$').hasMatch(value);
    if (!isValid) {
      return context.t('error_invalid_phone');
    }
    return null;
  }

  static String? amount(BuildContext context, String? value, {int? maxAmount}) {
    if (value == null || value.trim().isEmpty) {
      return context.t('error_required_field');
    }
    final number = double.tryParse(value);
    if (number == null || number <= 0) {
      return context.t('error_invalid_amount');
    }
    if (maxAmount != null && (number * 100).toInt() > maxAmount) {
      return context.t('error_amount_exceeds_max');
    }
    return null;
  }
}
