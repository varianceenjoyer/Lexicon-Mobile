import 'package:flutter/material.dart';

/// Available theme color presets.
enum ThemePreset {
  /// Deep blue with teal accents (default)
  ocean(
    name: 'Ocean',
    primary: Color(0xFF1565C0),
    secondary: Color(0xFF26A69A),
  ),

  /// Purple with pink accents
  sunset(
    name: 'Sunset',
    primary: Color(0xFF7B1FA2),
    secondary: Color(0xFFE91E63),
  ),

  /// Green with amber accents
  forest(
    name: 'Forest',
    primary: Color(0xFF388E3C),
    secondary: Color(0xFFFFA000),
  ),

  /// Indigo with cyan accents
  twilight(
    name: 'Twilight',
    primary: Color(0xFF303F9F),
    secondary: Color(0xFF00BCD4),
  ),

  /// Deep orange with brown accents
  autumn(
    name: 'Autumn',
    primary: Color(0xFFE64A19),
    secondary: Color(0xFF795548),
  ),

  /// Teal with lime accents
  spring(
    name: 'Spring',
    primary: Color(0xFF00796B),
    secondary: Color(0xFFCDDC39),
  );

  const ThemePreset({
    required this.name,
    required this.primary,
    required this.secondary,
  });

  /// Display name for the preset.
  final String name;

  /// Primary seed color.
  final Color primary;

  /// Secondary accent color.
  final Color secondary;
}
