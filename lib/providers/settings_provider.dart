import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/theme_preset.dart';

/// Application settings state.
class SettingsState {
  /// Silence threshold for VAD (0.0 - 0.1).
  /// Audio below this RMS level is considered silence and skipped.
  /// Default 0 = disabled (process all audio). Sherpa model handles silence well.
  final double silenceThreshold;

  /// Minimum audio chunk size in milliseconds.
  /// Higher values give the offline STT model more context for better accuracy.
  /// Lower values provide faster (but less accurate) incremental results.
  final int chunkSizeMs;

  /// Selected theme color preset.
  final ThemePreset themePreset;

  /// Theme mode (system, light, or dark).
  final ThemeMode themeMode;

  const SettingsState({
    this.silenceThreshold = 0.0, // Disabled by default - sherpa handles silence well
    this.chunkSizeMs = 3000, // 3 seconds - gives offline model enough context
    this.themePreset = ThemePreset.ocean,
    this.themeMode = ThemeMode.system,
  });

  SettingsState copyWith({
    double? silenceThreshold,
    int? chunkSizeMs,
    ThemePreset? themePreset,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      silenceThreshold: silenceThreshold ?? this.silenceThreshold,
      chunkSizeMs: chunkSizeMs ?? this.chunkSizeMs,
      themePreset: themePreset ?? this.themePreset,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Settings state notifier with persistence.
class SettingsNotifier extends StateNotifier<SettingsState> {
  static const _keySilenceThreshold = 'silence_threshold';
  static const _keyChunkSizeMs = 'chunk_size_ms';
  static const _keyThemePreset = 'theme_preset';
  static const _keyThemeMode = 'theme_mode';

  SharedPreferences? _prefs;

  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    final silenceThreshold = _prefs?.getDouble(_keySilenceThreshold) ?? 0.0;
    final chunkSizeMs = _prefs?.getInt(_keyChunkSizeMs) ?? 3000;
    final themePresetIndex = _prefs?.getInt(_keyThemePreset) ?? 0;
    final themeModeIndex = _prefs?.getInt(_keyThemeMode) ?? 0;

    state = SettingsState(
      silenceThreshold: silenceThreshold,
      chunkSizeMs: chunkSizeMs,
      themePreset: ThemePreset.values[themePresetIndex.clamp(0, ThemePreset.values.length - 1)],
      themeMode: ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)],
    );
  }

  Future<void> setSilenceThreshold(double value) async {
    // Clamp to valid range
    final clamped = value.clamp(0.0, 0.1);
    state = state.copyWith(silenceThreshold: clamped);
    await _prefs?.setDouble(_keySilenceThreshold, clamped);
  }

  Future<void> setChunkSizeMs(int value) async {
    // Clamp to valid range (1000ms - 5000ms)
    // Offline STT model needs at least 1s of audio for context
    final clamped = value.clamp(1000, 5000);
    state = state.copyWith(chunkSizeMs: clamped);
    await _prefs?.setInt(_keyChunkSizeMs, clamped);
  }

  Future<void> setThemePreset(ThemePreset preset) async {
    state = state.copyWith(themePreset: preset);
    await _prefs?.setInt(_keyThemePreset, preset.index);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs?.setInt(_keyThemeMode, mode.index);
  }

  /// Reset all settings to defaults.
  Future<void> resetToDefaults() async {
    await _prefs?.remove(_keySilenceThreshold);
    await _prefs?.remove(_keyChunkSizeMs);
    await _prefs?.remove(_keyThemePreset);
    await _prefs?.remove(_keyThemeMode);
    state = const SettingsState(); // Uses default values
  }
}

/// Provider for application settings.
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

/// Provider for silence threshold.
final silenceThresholdProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).silenceThreshold;
});

/// Provider for chunk size in milliseconds.
final chunkSizeMsProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).chunkSizeMs;
});

/// Provider for current theme preset.
final themePresetProvider = Provider<ThemePreset>((ref) {
  return ref.watch(settingsProvider).themePreset;
});

/// Provider for current theme mode.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});
