import 'package:flutter/material.dart';

class SolarColors {
  // Shared with the React website's public and workspace palettes.
  static const background = Color(0xFFF6F8F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFEEF4ED);
  static const primary = Color(0xFF07536A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const lime = Color(0xFF72B83E);
  static const limeDark = Color(0xFF5F9F31);
  static const text = Color(0xFF304143);
  static const muted = Color(0xFF687A7C);
  static const border = Color(0xFFDCE7D8);
  static const success = Color(0xFF287247);
  static const warning = Color(0xFF8B580B);
  static const error = Color(0xFFB33838);
  static const info = Color(0xFF246A79);
  static const purple = Color(0xFF705193);
}

ThemeData buildSolarTheme() {
  final scheme = ColorScheme.fromSeed(
          seedColor: SolarColors.primary, brightness: Brightness.light)
      .copyWith(
    primary: SolarColors.primary,
    onPrimary: SolarColors.onPrimary,
    secondary: SolarColors.lime,
    onSecondary: SolarColors.text,
    surface: SolarColors.surface,
    onSurface: SolarColors.text,
    onSurfaceVariant: SolarColors.muted,
    outline: SolarColors.border,
    error: SolarColors.error,
  );
  return ThemeData(
    useMaterial3: true,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48))),
    colorScheme: scheme,
    scaffoldBackgroundColor: SolarColors.background,
    appBarTheme: const AppBarTheme(
        backgroundColor: SolarColors.surface,
        foregroundColor: SolarColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1),
    cardTheme: CardThemeData(
        color: SolarColors.surface,
        elevation: 1,
        shadowColor: const Color(0x14173E44),
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: SolarColors.border))),
    inputDecorationTheme: InputDecorationTheme(
        errorMaxLines: 3,
        filled: true,
        fillColor: SolarColors.surface,
        labelStyle: const TextStyle(color: SolarColors.muted),
        hintStyle: const TextStyle(color: SolarColors.muted),
        prefixIconColor: SolarColors.muted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SolarColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: SolarColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: SolarColors.primary, width: 1.5))),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: SolarColors.lime,
            foregroundColor: SolarColors.onPrimary,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16))),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: SolarColors.lime,
            foregroundColor: SolarColors.onPrimary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: SolarColors.primary,
            side: const BorderSide(color: SolarColors.border),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14))),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: SolarColors.primary)),
    chipTheme: const ChipThemeData(
        backgroundColor: SolarColors.surfaceSoft,
        labelStyle: TextStyle(color: SolarColors.primary),
        side: BorderSide(color: SolarColors.border)),
    dividerColor: SolarColors.border,
    snackBarTheme: const SnackBarThemeData(
        backgroundColor: SolarColors.primary,
        contentTextStyle: TextStyle(color: SolarColors.onPrimary)),
  );
}
