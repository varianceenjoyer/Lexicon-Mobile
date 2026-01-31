import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_capture_service.dart';
import '../services/lexicon_core_service.dart';
import '../services/lexicon_flutter_service.dart';
import '../services/mocks/lexicon_core_service_mock.dart';
import '../services/tts_playback_service.dart';
import 'settings_provider.dart';

/// Lexicon Core service provider.
///
/// Returns real FFI implementation if initialized, otherwise mock.
/// Uses ref.listen instead of ref.watch to prevent provider rebuild on settings change.
/// This is critical for latency - rebuilding the provider would interrupt transcription.
final lexiconCoreProvider = Provider<LexiconCoreService>((ref) {
  if (LexiconFlutterService.isInitialized) {
    debugPrint('Using real Lexicon service');
    final service = LexiconFlutterService();

    // Get initial settings
    final initialSettings = ref.read(settingsProvider);
    service.updateSettings(
      silenceThreshold: initialSettings.silenceThreshold,
      chunkSizeMs: initialSettings.chunkSizeMs,
    );

    // Listen for settings changes without triggering provider rebuild
    ref.listen<SettingsState>(settingsProvider, (previous, next) {
      debugPrint('[lexiconCoreProvider] Settings changed, updating service');
      service.updateSettings(
        silenceThreshold: next.silenceThreshold,
        chunkSizeMs: next.chunkSizeMs,
      );
    });

    return service;
  }
  debugPrint('Using mock Lexicon service');
  return LexiconCoreServiceMock();
});

/// Audio capture service provider.
final audioCaptureProvider = Provider<AudioCaptureService>((ref) {
  final service = AudioCaptureServiceImpl();
  ref.onDispose(() => service.dispose());
  return service;
});

/// TTS playback service provider.
final ttsPlaybackProvider = Provider<TTSPlaybackService>((ref) {
  final service = TTSPlaybackServiceImpl();
  ref.onDispose(() => service.dispose());
  return service;
});
