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
/// Watches settings and updates the service when they change.
final lexiconCoreProvider = Provider<LexiconCoreService>((ref) {
  final settings = ref.watch(settingsProvider);

  if (LexiconFlutterService.isInitialized) {
    debugPrint('Using real Lexicon service');
    final service = LexiconFlutterService();
    service.updateSettings(
      silenceThreshold: settings.silenceThreshold,
      chunkSizeMs: settings.chunkSizeMs,
    );
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
