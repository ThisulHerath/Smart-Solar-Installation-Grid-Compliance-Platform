import 'dart:convert';

class Validators {
  static String? required(String? value) =>
      value == null || value.trim().isEmpty
          ? 'Please complete this field.'
          : null;

  static String? projectName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Please enter a project name.';
    if (name.length < 3) return 'Use at least 3 characters.';
    if (name.length > 120) return 'Use no more than 120 characters.';
    return null;
  }

  static String? email(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
          ? null
          : 'Enter a valid email, such as you@example.com.';
  static String? password(String? value) {
    final password = value ?? '';
    if (password.length < 12 ||
        password.length > 64 ||
        utf8.encode(password).length > 72 ||
        !RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Use 12–64 characters with uppercase, lowercase, number and symbol.';
    }
    return null;
  }

  static String? code(String? value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
      ? null
      : 'Enter the six-digit verification code.';
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return RegExp(r'^\+?[0-9().\s-]+$').hasMatch(value) &&
            digits.length >= 7 &&
            digits.length <= 15
        ? null
        : 'Enter a valid phone number or leave this blank.';
  }

  static String? confirm(String? value, String password) =>
      value == password && value?.isNotEmpty == true
          ? null
          : 'Your passwords do not match.';
  static String? number(String? value,
      {double min = 0, double max = 100000, bool optional = false}) {
    if (optional && (value == null || value.trim().isEmpty)) return null;
    final number = double.tryParse(value ?? '');
    return number == null || !number.isFinite || number < min || number > max
        ? 'Enter a number from $min to $max.'
        : null;
  }
}
