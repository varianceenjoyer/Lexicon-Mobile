---
id: WP-STATE
type: work-plan
status: ready
phase: mvp
created: 2026-01-29
updated: 2026-01-29
author: design-lead
consumers: [developer]
depends-on: [WP-SETUP]
blocks: [WP-NOTE, WP-CHAT, WP-FILES]
priority: high
tags: [state, riverpod, notifier, provider]
---

# WP-STATE: State Management with Riverpod

## Overview

Implement the state management layer using Riverpod. This provides reactive state for all views, manages service lifecycles, and handles async operations with proper error states.

## Scope

### Included
- Riverpod provider definitions for all services
- StateNotifier/AsyncNotifier classes for each view
- Global app state (current session, recording state)
- Error state handling patterns
- Service dependency injection via providers

### Excluded
- Service implementations (see WP-FFI, WP-AUDIO)
- UI widgets (see WP-NOTE, WP-CHAT, WP-FILES)
- Navigation (see WP-NAV)

## Interface Contract

### Service Providers

```dart
// lib/providers/service_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lexicon Core service provider
final lexiconCoreProvider = Provider<LexiconCoreService>((ref) {
  // Return mock during development, real service when integrated
  return LexiconCoreServiceMock();
});

/// Audio capture service provider
final audioCaptureProvider = Provider<AudioCaptureService>((ref) {
  final service = AudioCaptureService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// TTS playback service provider
final ttsPlaybackProvider = Provider<TTSPlaybackService>((ref) {
  final service = TTSPlaybackService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Background recording service provider
final backgroundRecordingProvider = Provider<BackgroundRecordingService>((ref) {
  return BackgroundRecordingService();
});
```

### Note View State

```dart
// lib/features/note/providers/note_provider.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'note_provider.freezed.dart';
part 'note_provider.g.dart';

@freezed
class NoteState with _$NoteState {
  const factory NoteState({
    @Default(NoteViewMode.idle) NoteViewMode mode,
    @Default('') String transcriptionText,
    @Default([]) List<Segment> segments,
    SessionId? sessionId,
    @Default(false) bool isEdited,
    String? errorMessage,
  }) = _NoteState;
}

enum NoteViewMode {
  idle,
  recording,
  paused,
  processing,
  playbackReady,
  playing,
  error,
}

@riverpod
class NoteNotifier extends _$NoteNotifier {
  @override
  NoteState build() => const NoteState();

  /// Start a new recording session
  Future<void> startRecording();

  /// Pause the current recording
  Future<void> pauseRecording();

  /// Resume a paused recording
  Future<void> resumeRecording();

  /// Stop recording and generate TTS
  Future<void> stopRecording();

  /// Update transcription text (manual edit)
  void updateText(String text);

  /// Start TTS playback
  Future<void> startPlayback();

  /// Pause TTS playback
  Future<void> pausePlayback();

  /// Seek TTS playback
  Future<void> seekPlayback(Duration position);

  /// Save current session
  Future<void> saveSession();

  /// Load existing session
  Future<void> loadSession(SessionId id);

  /// Clear current session
  void clearSession();
}
```

### TTS Playback State

```dart
// lib/features/note/providers/tts_playback_provider.dart

@freezed
class TTSPlaybackState with _$TTSPlaybackState {
  const factory TTSPlaybackState({
    @Default(PlaybackStatus.idle) PlaybackStatus status,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
    @Default(Duration.zero) Duration buffered,
  }) = _TTSPlaybackState;
}

enum PlaybackStatus { idle, loading, playing, paused, completed, error }

@riverpod
class TTSPlaybackNotifier extends _$TTSPlaybackNotifier {
  @override
  TTSPlaybackState build() => const TTSPlaybackState();

  Future<void> loadAudio(String text);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
}
```

### Chat View State

```dart
// lib/features/chat/providers/chat_provider.dart

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    @Default(ChatViewMode.idle) ChatViewMode mode,
    @Default([]) List<ChatMessage> messages,
    SessionId? sessionId,
    String? errorMessage,
  }) = _ChatState;
}

enum ChatViewMode {
  idle,
  recording,
  paused,
  error,
}

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required int speakerId,
    required String text,
    required int startMs,
    required int endMs,
  }) = _ChatMessage;
}

@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  ChatState build() => const ChatState();

  /// Start a new chat recording session
  Future<void> startRecording();

  /// Pause the current recording
  Future<void> pauseRecording();

  /// Resume a paused recording
  Future<void> resumeRecording();

  /// Stop recording and save
  Future<void> stopRecording();

  /// Load existing session
  Future<void> loadSession(SessionId id);

  /// Clear current session
  void clearSession();
}
```

### File Manager State

```dart
// lib/features/files/providers/files_provider.dart

@freezed
class FilesState with _$FilesState {
  const factory FilesState({
    @Default([]) List<SessionSummary> sessions,
    SessionSummary? selectedSession,
    @Default(SortOrder.dateDesc) SortOrder sortOrder,
    @Default('') String searchQuery,
    @Default([]) List<SearchResult> searchResults,
    @Default(false) bool isLoading,
    @Default(false) bool isSearching,
    String? errorMessage,
  }) = _FilesState;
}

enum SortOrder { dateDesc, dateAsc, nameAsc, nameDesc, durationDesc }

@riverpod
class FilesNotifier extends _$FilesNotifier {
  @override
  Future<FilesState> build() async {
    // Load initial session list
    final sessions = await ref.read(lexiconCoreProvider).listSessions();
    return FilesState(sessions: sessions);
  }

  /// Refresh session list
  Future<void> refresh();

  /// Select a session for preview
  Future<void> selectSession(SessionId id);

  /// Set sort order
  void setSortOrder(SortOrder order);

  /// Search transcriptions
  Future<void> search(String query);

  /// Clear search
  void clearSearch();

  /// Delete session
  Future<void> deleteSession(SessionId id);

  /// Rename session
  Future<void> renameSession(SessionId id, String newTitle);
}
```

### Import State

```dart
// lib/features/files/providers/import_provider.dart

@freezed
class ImportState with _$ImportState {
  const factory ImportState.idle() = ImportIdle;
  const factory ImportState.selecting() = ImportSelecting;
  const factory ImportState.processing({
    required double progress,
    required String fileName,
  }) = ImportProcessing;
  const factory ImportState.complete({
    required SessionId sessionId,
    required String fileName,
  }) = ImportComplete;
  const factory ImportState.error({
    required String message,
  }) = ImportError;
}

@riverpod
class ImportNotifier extends _$ImportNotifier {
  @override
  ImportState build() => const ImportState.idle();

  /// Start file selection
  Future<void> selectFile();

  /// Start import after file selected
  Future<void> startImport(String filePath);

  /// Cancel ongoing import
  Future<void> cancelImport();

  /// Reset to idle state
  void reset();
}
```

### Global App State

```dart
// lib/providers/app_state_provider.dart

@freezed
class AppState with _$AppState {
  const factory AppState({
    @Default(false) bool isRecording,
    SessionId? activeSessionId,
    @Default(ViewType.note) ViewType activeView,
    @Default(ThermalState.nominal) ThermalState thermalState,
  }) = _AppState;
}

enum ThermalState { nominal, fair, serious, critical }

@riverpod
class AppStateNotifier extends _$AppStateNotifier {
  @override
  AppState build() => const AppState();

  void setRecording(bool isRecording);
  void setActiveSession(SessionId? id);
  void setActiveView(ViewType view);
  void setThermalState(ThermalState state);
}
```

## Acceptance Criteria

- [ ] All service providers compile and resolve correctly
- [ ] NoteNotifier manages full recording lifecycle
- [ ] ChatNotifier manages diarized recording lifecycle
- [ ] FilesNotifier handles session list with sorting and search
- [ ] ImportNotifier tracks import progress correctly
- [ ] AppStateNotifier provides global recording status
- [ ] State changes trigger appropriate UI rebuilds
- [ ] Error states display correctly across views
- [ ] Code generation (freezed, riverpod_generator) works
- [ ] Unit tests pass for all notifiers
- [ ] Memory leaks avoided via proper disposal

## Dependencies

### Requires
- WP-SETUP complete (Flutter project structure)
- Service interface definitions from WP-FFI, WP-AUDIO

### Blocks
- WP-NOTE (needs NoteNotifier)
- WP-CHAT (needs ChatNotifier)
- WP-FILES (needs FilesNotifier, ImportNotifier)

## Files to Create

| File | Purpose |
|------|---------|
| `lib/providers/service_providers.dart` | Service DI providers |
| `lib/providers/app_state_provider.dart` | Global app state |
| `lib/features/note/providers/note_provider.dart` | Note view state |
| `lib/features/note/providers/tts_playback_provider.dart` | TTS playback state |
| `lib/features/chat/providers/chat_provider.dart` | Chat view state |
| `lib/features/files/providers/files_provider.dart` | File manager state |
| `lib/features/files/providers/import_provider.dart` | Import workflow state |
| `test/providers/note_provider_test.dart` | Note notifier tests |
| `test/providers/chat_provider_test.dart` | Chat notifier tests |
| `test/providers/files_provider_test.dart` | Files notifier tests |

## Code Generation

```bash
# Generate freezed and riverpod code
dart run build_runner build --delete-conflicting-outputs

# Watch for changes during development
dart run build_runner watch --delete-conflicting-outputs
```

## State Flow Diagrams

### Note View State Flow

```
[idle] ──(startRecording)──▶ [recording]
   ▲                              │
   │                         (pause/stop)
   │                              │
   │                              ▼
   │                        ┌─────────┐
   │                        │ paused  │──(resume)──▶ [recording]
   │                        └────┬────┘
   │                             │
   │                          (stop)
   │                             │
   │                             ▼
   │                       [processing]
   │                             │
   │                        (TTS ready)
   │                             │
   │                             ▼
   │                      [playbackReady]
   │                             │
   │                         (play)
   │                             │
   │                             ▼
   └────────────────────────[playing]
```

## Research References

- [Architecture: Layer Architecture](../design/architecture.md#layer-architecture)
- [Architecture: View Architecture](../design/architecture.md#view-architecture)

## Notes

- Use `@riverpod` annotation for code generation
- Prefer AsyncNotifier for async state (autoDispose by default)
- Use `ref.invalidateSelf()` for refresh patterns
- Watch vs read: watch for UI bindings, read for actions
- Consider `keepAlive` for services that shouldn't be disposed

---

*Work package created: 2026-01-29*
