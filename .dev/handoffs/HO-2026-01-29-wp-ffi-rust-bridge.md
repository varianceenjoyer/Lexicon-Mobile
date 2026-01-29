---
id: HO-2026-01-29-wp-ffi
type: handoff
status: ready
created: 2026-01-29
updated: 2026-01-29
from: design-lead
to: developer
work-package: WP-FFI
priority: critical
blocked-by: WP-SETUP
tags: [ffi, rust, flutter_rust_bridge]
---

# Handoff: flutter_rust_bridge Integration

## Summary

Integrate Lexicon Core (embedded Rust library) into the Flutter project using flutter_rust_bridge v2. This provides the FFI bridge for all STT, TTS, storage, and session management functionality.

**Blocked by**: WP-SETUP must be completed first.

## Context

Lexicon Mobile uses a "thin client" architecture where the Flutter app handles UI and platform audio, while Lexicon Core (Rust) handles all ML inference, storage, and audio processing.

Key integration points:
- **flutter_rust_bridge v2** — Dart bindings for Rust FFI with StreamSink support
- **Zero-copy array transfer** — Float32List for audio data
- **Streaming callbacks** — Real-time segment delivery during transcription

## Task

Complete [WP-FFI](../work/WP-FFI.md):

1. **Add flutter_rust_bridge dependency**
   ```yaml
   dependencies:
     flutter_rust_bridge: ^2.0.0
   ```

2. **Create service wrapper**
   - `lib/services/lexicon_core_service.dart`
   - Session management APIs
   - STT/TTS operations with streaming
   - File import with progress

3. **Create data models**
   - `lib/services/models/session.dart`
   - `lib/services/models/transcription.dart`
   - `lib/services/models/errors.dart`

4. **Create mock implementation**
   - `lib/services/lexicon_core_service_mock.dart`
   - Enables UI development before Rust integration

## Key Interface

```dart
class LexiconCoreService {
  // Session Management
  Future<SessionId> createSession(SessionConfig config);
  Future<List<SessionSummary>> listSessions();

  // STT Operations
  Future<TranscriptionHandle> startTranscription(SessionId id, TranscriptionConfig config);
  Stream<Segment> processAudioStream(TranscriptionHandle handle, Stream<Float32List> audio);

  // TTS Operations
  Stream<Uint8List> synthesizeSpeech(String text, {String? voiceId});

  // Search
  Future<List<SearchResult>> searchTranscriptions(String query);
}
```

## Acceptance Criteria

From WP-FFI:
- [ ] flutter_rust_bridge generates Dart bindings successfully
- [ ] LexiconCoreService compiles without errors
- [ ] Mock implementation provides synthetic data
- [ ] StreamSink callbacks deliver segments in real-time
- [ ] Error types translate correctly from Rust to Dart
- [ ] Unit tests pass for service wrapper

## Notes

- Start with mock implementation for parallel UI development
- Real Rust integration can be added later when Lexicon Core is available
- See [R-FFI-01](../design/research/R-FFI-01-uniffi-integration.md) for FFI patterns

---

*Handoff created: 2026-01-29 by design-lead*
