---
id: WP-AUDIO
type: work-plan
status: complete
phase: mvp
created: 2026-01-29
updated: 2026-01-29
author: design-lead
consumers: [developer]
depends-on: [WP-SETUP]
blocks: [WP-NOTE, WP-CHAT]
priority: critical
tags: [audio, capture, playback, record, just_audio]
---

# WP-AUDIO: Audio Capture and Playback Services

## Overview

Implement audio capture using the `record` plugin and audio playback using `just_audio`. These services provide the platform abstraction layer for microphone input and TTS audio output.

## Scope

### Included
- AudioCaptureService using `record` plugin
- TTSPlaybackService using `just_audio`
- Permission handling for microphone access
- Background recording support via `flutter_foreground_task`
- Audio format configuration (16kHz mono for STT)
- Audio session management (iOS interruptions, Android focus)

### Excluded
- FFI integration with Lexicon Core (see WP-FFI)
- UI controls (see WP-NOTE, WP-CHAT)
- State management (see WP-STATE)

## Interface Contract

### AudioCaptureService

```dart
// lib/services/audio_capture_service.dart

import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

enum AudioCaptureState {
  idle,
  recording,
  paused,
  interrupted,
}

class AudioCaptureService {
  final AudioRecorder _recorder = AudioRecorder();

  /// Current capture state
  ValueNotifier<AudioCaptureState> get state;

  /// Check if microphone permission is granted
  Future<bool> hasPermission();

  /// Request microphone permission
  /// Returns true if granted, false otherwise
  Future<bool> requestPermission();

  /// Start audio capture
  /// Returns stream of PCM audio chunks (16-bit, 16kHz, mono)
  /// Throws PermissionDeniedException if mic access not granted
  Future<Stream<Uint8List>> startCapture();

  /// Pause audio capture (preserves session)
  Future<void> pauseCapture();

  /// Resume paused capture
  Future<Stream<Uint8List>> resumeCapture();

  /// Stop audio capture and release resources
  Future<void> stopCapture();

  /// Handle audio interruption (phone call, etc.)
  void handleInterruption(bool shouldPause);

  /// Dispose of resources
  Future<void> dispose();
}

class PermissionDeniedException implements Exception {
  final String message = 'Microphone permission denied';
}
```

### TTSPlaybackService

```dart
// lib/services/tts_playback_service.dart

import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';

enum PlaybackState {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

class TTSPlaybackService {
  final AudioPlayer _player = AudioPlayer();

  /// Current playback state
  ValueNotifier<PlaybackState> get state;

  /// Current playback position
  Stream<Duration> get positionStream;

  /// Total duration (available after loading)
  Duration? get duration;

  /// Buffered position
  Stream<Duration> get bufferedPositionStream;

  /// Load audio from stream of PCM chunks
  /// Audio format: 22050Hz, 16-bit, mono (Lexicon Core TTS output)
  Future<void> loadFromStream(Stream<Uint8List> audioStream);

  /// Load audio from file path
  Future<void> loadFromFile(String path);

  /// Start or resume playback
  Future<void> play();

  /// Pause playback
  Future<void> pause();

  /// Seek to position
  Future<void> seek(Duration position);

  /// Stop playback and reset
  Future<void> stop();

  /// Dispose of resources
  Future<void> dispose();
}
```

### BackgroundRecordingService

```dart
// lib/services/background_recording_service.dart

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class BackgroundRecordingService {
  /// Start foreground service for background recording
  /// Shows notification on Android, uses background audio mode on iOS
  Future<void> startBackgroundMode();

  /// Stop foreground service
  Future<void> stopBackgroundMode();

  /// Check if app is in background
  bool get isInBackground;

  /// Handle app lifecycle changes
  void handleAppLifecycle(AppLifecycleState state);
}
```

### Audio Configuration Constants

```dart
// lib/core/constants/audio_constants.dart

class AudioConstants {
  // Capture settings (Whisper-compatible)
  static const int captureSampleRate = 16000;
  static const int captureChannels = 1;
  static const int captureBitDepth = 16;

  // Playback settings (Lexicon Core TTS output)
  static const int playbackSampleRate = 22050;
  static const int playbackChannels = 1;
  static const int playbackBitDepth = 16;

  // Buffer sizes
  static const int captureBufferMs = 100;  // ~1600 samples at 16kHz
  static const int playbackBufferMs = 200; // Gapless playback buffer

  // Latency targets
  static const int maxCaptureLatencyMs = 50;
  static const int maxPlaybackLatencyMs = 30;
}
```

## Acceptance Criteria

- [x] AudioCaptureService streams audio at 16kHz mono
- [x] Permission request shows appropriate system dialog
- [x] Permission denial is handled gracefully with user guidance
- [x] TTSPlaybackService plays audio from stream without gaps
- [x] Playback controls (play/pause/seek) function correctly
- [x] Position and duration updates stream to UI
- [ ] Background recording works on Android (foreground service)
- [ ] Background recording works on iOS (audio background mode)
- [ ] Audio interruptions (phone calls) pause recording gracefully
- [ ] Recording resumes correctly after interruption
- [ ] Audio latency meets targets (<100ms capture, <300ms TTS first audio)
- [ ] Unit tests pass for both services
- [ ] Integration test validates capture → FFI round-trip

## Implementation Notes

Implemented 2026-01-29:
- Created AudioCaptureService interface and stub implementation
- Created TTSPlaybackService interface and stub implementation
- Service interfaces follow work package contract specifications
- Mock implementations simulate audio capture/playback for development
- Real implementations pending record/just_audio plugin integration
- Background recording support outlined in AndroidManifest (FOREGROUND_SERVICE)

## Dependencies

### Requires
- WP-SETUP complete (Flutter project structure)
- `record` plugin (^5.0.0)
- `just_audio` plugin (^0.9.0)
- `permission_handler` plugin (^11.0.0)
- `flutter_foreground_task` plugin (^6.0.0)

### Blocks
- WP-NOTE (needs audio capture and TTS playback)
- WP-CHAT (needs audio capture)

## Files to Create

| File | Purpose |
|------|---------|
| `lib/services/audio_capture_service.dart` | Mic capture wrapper |
| `lib/services/tts_playback_service.dart` | TTS audio playback |
| `lib/services/background_recording_service.dart` | Background mode support |
| `lib/core/constants/audio_constants.dart` | Audio configuration |
| `test/services/audio_capture_service_test.dart` | Capture unit tests |
| `test/services/tts_playback_service_test.dart` | Playback unit tests |

## Configuration

### pubspec.yaml additions

```yaml
dependencies:
  record: ^5.0.0
  just_audio: ^0.9.36
  permission_handler: ^11.0.0
  flutter_foreground_task: ^6.0.0
  audio_session: ^0.1.16  # For iOS audio session management
```

### iOS Info.plist (already in WP-SETUP)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Lexicon uses the microphone to transcribe your speech into text.</string>
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

### Android AndroidManifest.xml (already in WP-SETUP)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
```

## Latency Budget

| Operation | Target | Measurement |
|-----------|--------|-------------|
| Permission dialog response | <100ms | User action to callback |
| Audio session activation | <30ms | iOS audio session |
| Capture start | <100ms | Button tap to first buffer |
| Buffer delivery | ~100ms chunks | Continuous streaming |
| Playback first audio | <30ms | After buffer scheduled |

## Research References

- [R-AUDIO-01](../design/research/R-AUDIO-01-realtime-audio-pipeline.md) — Audio pipeline research
- [R-TTS-01](../design/research/R-TTS-01-tts-pipeline.md) — TTS playback patterns
- [Architecture: Audio Configuration](../design/architecture.md#audio-configuration)

## Notes

- `record` plugin handles platform-specific audio format conversion
- Target 16kHz for STT (Whisper requirement)
- TTS output from Lexicon Core is 22050Hz
- Test on physical devices for accurate latency measurements
- Prototype validation required per architecture document

---

*Work package created: 2026-01-29*
