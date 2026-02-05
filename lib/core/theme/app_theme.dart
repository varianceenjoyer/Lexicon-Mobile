import 'package:flutter/material.dart';

import 'theme_preset.dart';

/// Application theme configuration using Material 3.
class AppTheme {
  AppTheme._();

  /// Light theme configuration.
  static ThemeData light([ThemePreset preset = ThemePreset.ocean]) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: preset.primary,
      brightness: Brightness.light,
      secondary: preset.secondary,
    );

    return _buildTheme(colorScheme);
  }

  /// Dark theme configuration.
  static ThemeData dark([ThemePreset preset = ThemePreset.ocean]) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: preset.primary,
      brightness: Brightness.dark,
      secondary: preset.secondary,
    );

    return _buildTheme(colorScheme);
  }

  /// Build ThemeData from ColorScheme.
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
