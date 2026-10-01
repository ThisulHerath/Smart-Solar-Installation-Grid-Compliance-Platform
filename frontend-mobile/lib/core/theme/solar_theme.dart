import 'package:flutter/material.dart';

class SolarColors {
  // Shared with the React website's public and workspace palettes.
  static const background = Color(0xFFF8FAF7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFEFF6E8);
  static const primary = Color(0xFF0A5569);
  static const onPrimary = Color(0xFFFFFFFF);
  static const lime = Color(0xFF69B63B);
  static const limeDark = Color(0xFF589F30);
  static const text = Color(0xFF303D3E);
  static const muted = Color(0xFF657779);
  static const border = Color(0xFFDFE8D8);
  static const success = Color(0xFF4D8E28);
  static const warning = Color(0xFF956719);
  static const error = Color(0xFFBF4C52);
  static const info = Color(0xFF246A79);
  static const heroEnd = Color(0xFF377D61);
  static const heroAccent = Color(0xFFB5DC8B);
  static const heroText = Color(0xFFE0EDE7);
  static const successSoft = Color(0xFFEDF7E5);
  static const warningSoft = Color(0xFFFFF7E6);
  static const errorSoft = Color(0xFFFFEEEE);
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
    progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SolarColors.lime, linearTrackColor: SolarColors.surfaceSoft),
    navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SolarColors.surface,
        indicatorColor: SolarColors.surfaceSoft,
        labelTextStyle: WidgetStateProperty.all(const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SolarColors.primary))),
    tabBarTheme: const TabBarThemeData(
        labelColor: SolarColors.primary,
        unselectedLabelColor: SolarColors.muted,
        indicatorColor: SolarColors.lime,
        dividerColor: SolarColors.border),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SolarColors.lime,
        foregroundColor: Colors.white,
        elevation: 2),
    bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SolarColors.surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
    dialogTheme: DialogThemeData(
        backgroundColor: SolarColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
    listTileTheme: const ListTileThemeData(
        iconColor: SolarColors.primary,
        textColor: SolarColors.text,
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 6)),
    dividerColor: SolarColors.border,
    snackBarTheme: const SnackBarThemeData(
        backgroundColor: SolarColors.primary,
        contentTextStyle: TextStyle(color: SolarColors.onPrimary)),
  );
}
