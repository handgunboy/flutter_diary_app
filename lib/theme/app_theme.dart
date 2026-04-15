import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData buildLightTheme() {
    final colors = AppColors.light;
    return ThemeData(
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.actionPrimaryBackground,
        brightness: Brightness.light,
      ).copyWith(
        surface: colors.surface,
        onSurface: colors.textPrimary,
        surfaceTint: Colors.transparent,
      ),
      useMaterial3: true,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 4,
        shadowColor: colors.shadowSoft,
        surfaceTintColor: Colors.transparent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: colors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSubtle,
        hintStyle: TextStyle(
          color: colors.textMuted,
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: colors.textMuted,
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          color: colors.textMuted,
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.actionPrimaryBackground, width: 1),
        ),
      ),
    );
  }

  static ThemeData buildDarkTheme() {
    final colors = AppColors.dark;
    return ThemeData(
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.dark(
        surface: colors.surface,
        primary: colors.actionPrimaryBackground,
        secondary: colors.outlineStrong,
        onSurface: colors.textPrimary,
      ),
      useMaterial3: true,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 4,
        shadowColor: colors.shadowSoft,
        surfaceTintColor: Colors.transparent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: colors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSubtle,
        hintStyle: TextStyle(
          color: colors.textMuted,
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: colors.textMuted,
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          color: colors.textMuted,
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outlineStrong, width: 1),
        ),
      ),
    );
  }
}
