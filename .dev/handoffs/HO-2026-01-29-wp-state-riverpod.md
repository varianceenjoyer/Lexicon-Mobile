---
id: HO-2026-01-29-wp-state
type: handoff
status: ready
created: 2026-01-29
updated: 2026-01-29
from: design-lead
to: developer
work-package: WP-STATE
priority: high
blocked-by: WP-SETUP
tags: [state, riverpod, providers, notifiers]
---

# Handoff: Riverpod State Management

## Summary

Implement the state management layer using Riverpod. This provides reactive state for all views, manages service lifecycles, and handles async operations with proper error states.

**Blocked by**: WP-SETUP must be completed first.

## Context

Riverpod provides:
- Compile-time safe dependency injection
- Reactive state updates with automatic UI rebuilds
- AsyncNotifier for async state management
- Code generation with riverpod_annotation

## Task

Complete [WP-STATE](../work/WP-STATE.md):

1. **Create service providers**
   - `lib/providers/service_providers.dart`
   - Provider for LexiconCoreService
   - Provider for AudioCaptureService
   - Provider for TTSPlaybackService

2. **Create view notifiers**
   - `lib/features/note/providers/note_provider.dart`
   - `lib/features/chat/providers/chat_provider.dart`
   - `lib/features/files/providers/files_provider.dart`

3. **Create global app state**
   - `lib/providers/app_state_provider.dart`
   - Recording status, active session, thermal state

4. **Run code generation**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

## Key State Models

```dart
@freezed
class NoteState with _$NoteState {
  const factory NoteState({
    @Default(NoteViewMode.idle) NoteViewMode mode,
    @Default('') String transcriptionText,
    @Default([]) List<Segment> segments,
    SessionId? sessionId,
  }) = _NoteState;
}

enum NoteViewMode { idle, recording, paused, processing, playbackReady, playing, error }

@riverpod
class NoteNotifier extends _$NoteNotifier {
  Future<void> startRecording();
  Future<void> pauseRecording();
  Future<void> stopRecording();
  Future<void> startPlayback();
}
```

## Acceptance Criteria

From WP-STATE:
- [ ] All service providers compile and resolve
- [ ] NoteNotifier manages full recording lifecycle
- [ ] ChatNotifier manages diarized recording lifecycle
- [ ] FilesNotifier handles session list with sorting/search
- [ ] State changes trigger UI rebuilds
- [ ] Code generation works
- [ ] Unit tests pass for all notifiers

## Notes

- Use `@riverpod` annotation for code generation
- Prefer AsyncNotifier for async state
- Use `ref.invalidateSelf()` for refresh patterns
- Watch vs read: watch for UI bindings, read for actions

---

*Handoff created: 2026-01-29 by design-lead*
