---
id: HO-2026-01-29-wp-audio
type: handoff
status: ready
created: 2026-01-29
updated: 2026-01-29
from: design-lead
to: developer
work-package: WP-AUDIO
priority: critical
blocked-by: WP-SETUP
tags: [audio, capture, playback, record, just_audio]
---

# Handoff: Audio Capture and Playback Services

## Summary

Implement audio capture using the `record` plugin and audio playback using `just_audio`. These services provide the platform abstraction layer for microphone input and TTS audio output.

**Blocked by**: WP-SETUP must be completed first.

## Context

Audio is critical for the app's core functionality:
- **Capture**: Real-time mic input at 16kHz mono (Whisper-compatible)
- **Playback**: TTS audio output at 22050Hz (Lexicon Core format)
- **Background**: Recording must continue when app is backgrounded

## Task

Complete [WP-AUDIO](../work/WP-AUDIO.md):

1. **Add dependencies**
   ```yaml
   dependencies:
     record: ^5.0.0
     just_audio: ^0.9.36
     permission_handler: ^11.0.0
     flutter_foreground_task: ^6.0.0
   ```

2. **Create AudioCaptureService**
   - `lib/services/audio_capture_service.dart`
   - Permission handling
   - Stream<Uint8List> output at 16kHz mono
   - Pause/resume support

3. **Create TTSPlaybackService**
   - `lib/services/tts_playback_service.dart`
   - Stream input for TTS audio
   - Play/pause/seek controls
   - Position and duration streams

4. **Create BackgroundRecordingService**
   - `lib/services/background_recording_service.dart`
   - Foreground service on Android
   - Audio background mode on iOS

## Key Interfaces

```dart
class AudioCaptureService {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<Stream<Uint8List>> startCapture();
  Future<void> pauseCapture();
  Future<void> stopCapture();
}

class TTSPlaybackService {
  Stream<Duration> get positionStream;
  Duration? get duration;
  Future<void> loadFromStream(Stream<Uint8List> audioStream);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
}
```

## Acceptance Criteria

From WP-AUDIO:
- [ ] AudioCaptureService streams audio at 16kHz mono
- [ ] Permission request shows system dialog
- [ ] TTSPlaybackService plays audio without gaps
- [ ] Play/pause/seek controls work correctly
- [ ] Background recording works on both platforms
- [ ] Audio latency meets targets (<100ms capture)

## Latency Budget

| Operation | Target |
|-----------|--------|
| Capture start | <100ms |
| Buffer delivery | ~100ms chunks |
| Playback first audio | <30ms |

## Notes

- Test on physical devices for accurate latency measurements
- Prototype validation required per architecture document
- See [R-AUDIO-01](../design/research/R-AUDIO-01-realtime-audio-pipeline.md) for audio patterns

---

*Handoff created: 2026-01-29 by design-lead*
