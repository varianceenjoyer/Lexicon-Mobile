---
id: WP-FFI
type: work-plan
status: ready
phase: mvp
created: 2026-01-29
updated: 2026-01-29
author: design-lead
consumers: [developer]
depends-on: [WP-SETUP]
blocks: [WP-NOTE, WP-CHAT, WP-FILES]
priority: critical
tags: [ffi, rust, flutter_rust_bridge, lexicon-core]
---

# WP-FFI: flutter_rust_bridge Integration with Lexicon Core

## Overview

Integrate Lexicon Core (embedded Rust library) into the Flutter project using flutter_rust_bridge. This provides the FFI bridge for all STT, TTS, storage, and session management functionality.

## Scope

### Included
- flutter_rust_bridge v2 setup and configuration
- Dart binding generation from Rust API
- LexiconCoreService wrapper class
- StreamSink callbacks for real-time transcription
- Error translation layer (Rust → Dart)
- Mock implementation for development without Rust library

### Excluded
- Audio capture (see WP-AUDIO)
- UI integration (see WP-NOTE, WP-CHAT, WP-FILES)
- State management integration (see WP-STATE)

## Interface Contract

### LexiconCoreService API

```dart
// lib/services/lexicon_core_service.dart

import 'package:lexicon_core/lexicon_core.dart';

/// Service wrapper for Lexicon Core FFI operations
class LexiconCoreService {
  final LexiconCore _core;

  LexiconCoreService(this._core);

  // Session Management
  Future<SessionId> createSession(SessionConfig config);
  Future<Session> getSession(SessionId id);
  Future<List<SessionSummary>> listSessions();
  Future<void> deleteSession(SessionId id);
  Future<void> renameSession(SessionId id, String title);

  // STT Operations
  Future<TranscriptionHandle> startTranscription(
    SessionId sessionId,
    TranscriptionConfig config,
  );
  Stream<Segment> processAudioStream(
    TranscriptionHandle handle,
    Stream<Float32List> audioSamples,
  );
  Future<void> stopTranscription(TranscriptionHandle handle);
  Future<void> cancelTranscription(TranscriptionHandle handle);

  // TTS Operations
  Stream<Uint8List> synthesizeSpeech(String text, {String? voiceId});
  Future<void> cancelSynthesis();

  // File Import
  Stream<ImportProgress> importAudioFile(
    String path,
    TranscriptionConfig config,
  );
  Future<void> cancelImport(SessionId sessionId);

  // Search
  Future<List<SearchResult>> searchTranscriptions(String query);
}
```

### Data Models

```dart
// lib/services/models/session.dart

class SessionId {
  final String value;
  const SessionId(this.value);
}

class Session {
  final SessionId id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Duration? duration;
  final String sourceType; // 'mic' | 'import'
  final ViewType viewType;
  final List<Segment> segments;
}

class SessionSummary {
  final SessionId id;
  final String title;
  final DateTime createdAt;
  final Duration? duration;
  final ViewType viewType;
  final int segmentCount;
}

class SessionConfig {
  final String? title;
  final ViewType viewType;

  const SessionConfig({this.title, required this.viewType});
}

enum ViewType { note, chat }
```

```dart
// lib/services/models/transcription.dart

class TranscriptionHandle {
  final String value;
  const TranscriptionHandle(this.value);
}

class TranscriptionConfig {
  final bool diarization;
  final String? language;
  final bool translateToEnglish;

  const TranscriptionConfig({
    required this.diarization,
    this.language,
    this.translateToEnglish = false,
  });
}

class Segment {
  final String id;
  final int? speakerId;
  final String text;
  final int startMs;
  final int endMs;
  final double? confidence;

  const Segment({
    required this.id,
    this.speakerId,
    required this.text,
    required this.startMs,
    required this.endMs,
    this.confidence,
  });
}
```

```dart
// lib/services/models/import.dart

class ImportProgress {
  final double percentage;
  final String status; // 'loading' | 'transcribing' | 'complete' | 'error'
  final String? errorMessage;
  final SessionId? sessionId; // Set when complete

  const ImportProgress({
    required this.percentage,
    required this.status,
    this.errorMessage,
    this.sessionId,
  });
}
```

```dart
// lib/services/models/search.dart

class SearchResult {
  final SessionId sessionId;
  final String sessionTitle;
  final String matchText;
  final int segmentStartMs;

  const SearchResult({
    required this.sessionId,
    required this.sessionTitle,
    required this.matchText,
    required this.segmentStartMs,
  });
}
```

### Error Types

```dart
// lib/services/models/errors.dart

sealed class LexiconError implements Exception {
  String get message;
}

class ModelNotFoundError extends LexiconError {
  @override
  String get message => 'Speech model not found';
}

class InferenceFailedError extends LexiconError {
  final String details;
  InferenceFailedError(this.details);

  @override
  String get message => 'Transcription failed: $details';
}

class StorageFullError extends LexiconError {
  @override
  String get message => 'Not enough storage space';
}

class CancelledError extends LexiconError {
  @override
  String get message => 'Operation cancelled';
}

class InvalidAudioError extends LexiconError {
  @override
  String get message => 'Audio format not supported';
}
```

### Mock Implementation

```dart
// lib/services/lexicon_core_service_mock.dart

class LexiconCoreServiceMock implements LexiconCoreService {
  // Mock implementation for development without Rust library
  // Returns synthetic data for UI development
}
```

## Acceptance Criteria

- [ ] flutter_rust_bridge generates Dart bindings successfully
- [ ] LexiconCoreService compiles without errors
- [ ] Mock implementation provides synthetic data for all methods
- [ ] StreamSink callbacks deliver segments in real-time
- [ ] Error types translate correctly from Rust to Dart
- [ ] Session CRUD operations work with mock data
- [ ] Import progress stream emits correct updates
- [ ] Search returns mock results
- [ ] Unit tests pass for service wrapper

## Dependencies

### Requires
- WP-SETUP complete (Flutter project structure)
- Lexicon Core library from Lexicon Local Server project
- flutter_rust_bridge CLI tools

### Blocks
- WP-NOTE (needs STT and TTS APIs)
- WP-CHAT (needs STT API with diarization)
- WP-FILES (needs session and search APIs)

## Files to Create

| File | Purpose |
|------|---------|
| `lib/services/lexicon_core_service.dart` | Main service wrapper |
| `lib/services/lexicon_core_service_mock.dart` | Mock for UI development |
| `lib/services/models/session.dart` | Session data models |
| `lib/services/models/transcription.dart` | Transcription data models |
| `lib/services/models/import.dart` | Import progress models |
| `lib/services/models/search.dart` | Search result models |
| `lib/services/models/errors.dart` | Error type definitions |
| `rust/` | Rust bridge code (generated) |
| `test/services/lexicon_core_service_test.dart` | Service unit tests |

## Configuration

### pubspec.yaml additions

```yaml
dependencies:
  flutter_rust_bridge: ^2.0.0
  # Generated package
  lexicon_core:
    path: ./rust/lexicon_core

dev_dependencies:
  flutter_rust_bridge_codegen: ^2.0.0
```

### Build Script

```bash
# Generate Dart bindings from Rust
flutter_rust_bridge_codegen generate

# Verify bindings
flutter pub get
flutter analyze
```

## Research References

- [R-FFI-01](../design/research/R-FFI-01-uniffi-integration.md) — FFI integration patterns
- [Architecture: FFI Interface Contract](../design/architecture.md#ffi-interface-contract)

## Notes

- flutter_rust_bridge v2 is the target version
- StreamSink provides callback-based streaming (equivalent to UniFFI callbacks)
- Zero-copy array transfer for audio data (Float32List)
- Mock implementation enables UI development before Rust integration complete

---

*Work package created: 2026-01-29*
