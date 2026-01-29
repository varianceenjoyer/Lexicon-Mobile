import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_capture_service.dart';
import '../services/lexicon_core_service.dart';
import '../services/mocks/lexicon_core_service_mock.dart';
import '../services/tts_playback_service.dart';

/// Lexicon Core service provider.
///
/// Returns mock implementation during development.
/// Will return real FFI implementation when integrated.
final lexiconCoreProvider = Provider<LexiconCoreService>((ref) {
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
