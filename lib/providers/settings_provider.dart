import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  const SettingsState({
    this.silenceThreshold = 0.0, // Disabled by default - sherpa handles silence well
    this.chunkSizeMs = 3000, // 3 seconds - gives offline model enough context
  });

  SettingsState copyWith({
    double? silenceThreshold,
    int? chunkSizeMs,
  }) {
    return SettingsState(
      silenceThreshold: silenceThreshold ?? this.silenceThreshold,
      chunkSizeMs: chunkSizeMs ?? this.chunkSizeMs,
    );
  }
}

/// Settings state notifier with persistence.
class SettingsNotifier extends StateNotifier<SettingsState> {
  static const _keySilenceThreshold = 'silence_threshold';
  static const _keyChunkSizeMs = 'chunk_size_ms';

  SharedPreferences? _prefs;

  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    final silenceThreshold = _prefs?.getDouble(_keySilenceThreshold) ?? 0.0;
    final chunkSizeMs = _prefs?.getInt(_keyChunkSizeMs) ?? 3000;

    state = SettingsState(
      silenceThreshold: silenceThreshold,
      chunkSizeMs: chunkSizeMs,
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

  /// Reset all settings to defaults.
  Future<void> resetToDefaults() async {
    await _prefs?.remove(_keySilenceThreshold);
    await _prefs?.remove(_keyChunkSizeMs);
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
