---
id: WP-NOTE
type: work-plan
status: ready
phase: mvp
created: 2026-01-29
updated: 2026-01-29
author: design-lead
consumers: [developer]
depends-on: [WP-SETUP, WP-FFI, WP-AUDIO, WP-STATE, WP-NAV]
blocks: []
priority: high
tags: [note, view, transcription, tts, recording]
---

# WP-NOTE: Note View Implementation

## Overview

Implement the Note View screen for single-speaker transcription with TTS playback. This is the primary transcription interface optimized for note-taking, memos, and voice journaling.

## Scope

### Included
- NoteScreen widget with full recording workflow
- Transcription text area (scrollable, selectable)
- TTS playback controls (play/pause, seek, progress)
- Mic button with recording indicator
- Session title display and editing
- Real-time text updates during recording
- Manual text editing support

### Excluded
- Audio capture implementation (provided by WP-AUDIO)
- FFI calls to Lexicon Core (provided by WP-FFI)
- State management logic (provided by WP-STATE)
- Navigation shell (provided by WP-NAV)

## Interface Contract

### NoteScreen Widget

```dart
// lib/features/note/screens/note_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NoteScreen extends ConsumerStatefulWidget {
  final SessionId? initialSessionId;

  const NoteScreen({this.initialSessionId, super.key});

  @override
  ConsumerState<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends ConsumerState<NoteScreen> {
  late TextEditingController _textController;
  late ScrollController _scrollController;

  @override
  Widget build(BuildContext context) {
    final noteState = ref.watch(noteNotifierProvider);

    return Scaffold(
      appBar: NoteAppBar(
        title: noteState.sessionTitle,
        onTitleEdit: (title) => ref.read(noteNotifierProvider.notifier).updateTitle(title),
      ),
      body: Column(
        children: [
          Expanded(
            child: TranscriptionTextArea(
              controller: _textController,
              scrollController: _scrollController,
              isEditable: noteState.mode != NoteViewMode.recording,
              onTextChanged: (text) => ref.read(noteNotifierProvider.notifier).updateText(text),
            ),
          ),
          if (noteState.mode == NoteViewMode.playbackReady ||
              noteState.mode == NoteViewMode.playing)
            TTSPlayerControls(
              state: ref.watch(ttsPlaybackNotifierProvider),
              onPlay: () => ref.read(ttsPlaybackNotifierProvider.notifier).play(),
              onPause: () => ref.read(ttsPlaybackNotifierProvider.notifier).pause(),
              onSeek: (position) => ref.read(ttsPlaybackNotifierProvider.notifier).seek(position),
            ),
          RecordingControls(
            mode: noteState.mode,
            onRecordTap: _handleRecordTap,
          ),
        ],
      ),
    );
  }

  void _handleRecordTap() {
    final notifier = ref.read(noteNotifierProvider.notifier);
    final mode = ref.read(noteNotifierProvider).mode;

    switch (mode) {
      case NoteViewMode.idle:
        notifier.startRecording();
        break;
      case NoteViewMode.recording:
        notifier.pauseRecording();
        break;
      case NoteViewMode.paused:
        notifier.resumeRecording();
        break;
      default:
        break;
    }
  }
}
```

### TranscriptionTextArea Widget

```dart
// lib/features/note/widgets/transcription_text_area.dart

class TranscriptionTextArea extends StatelessWidget {
  final TextEditingController controller;
  final ScrollController scrollController;
  final bool isEditable;
  final ValueChanged<String> onTextChanged;

  const TranscriptionTextArea({
    required this.controller,
    required this.scrollController,
    required this.isEditable,
    required this.onTextChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        scrollController: scrollController,
        maxLines: null,
        expands: true,
        readOnly: !isEditable,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Tap the microphone to start recording...',
        ),
        style: Theme.of(context).textTheme.bodyLarge,
        onChanged: onTextChanged,
      ),
    );
  }
}
```

### TTSPlayerControls Widget

```dart
// lib/features/note/widgets/tts_player_controls.dart

class TTSPlayerControls extends StatelessWidget {
  final TTSPlaybackState state;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final ValueChanged<Duration> onSeek;

  const TTSPlayerControls({
    required this.state,
    required this.onPlay,
    required this.onPause,
    required this.onSeek,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: state.status == PlaybackStatus.playing ? onPause : onPlay,
            icon: Icon(
              state.status == PlaybackStatus.playing
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              size: 48,
            ),
          ),
          Expanded(
            child: Slider(
              value: state.position.inMilliseconds.toDouble(),
              min: 0,
              max: state.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
              onChanged: (value) => onSeek(Duration(milliseconds: value.round())),
            ),
          ),
          Text(
            '${_formatDuration(state.position)} / ${_formatDuration(state.duration)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
```

### RecordingControls Widget

```dart
// lib/features/note/widgets/recording_controls.dart

class RecordingControls extends StatelessWidget {
  final NoteViewMode mode;
  final VoidCallback onRecordTap;

  const RecordingControls({
    required this.mode,
    required this.onRecordTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Stop button (visible when recording or paused)
          if (mode == NoteViewMode.recording || mode == NoteViewMode.paused)
            IconButton(
              onPressed: () {
                // Stop recording via provider
              },
              icon: const Icon(Icons.stop_circle, size: 48),
            ),

          const SizedBox(width: 24),

          // Main mic/pause button
          _MicButton(
            mode: mode,
            onTap: onRecordTap,
          ),

          const SizedBox(width: 24),

          // Placeholder for symmetry
          if (mode == NoteViewMode.recording || mode == NoteViewMode.paused)
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final NoteViewMode mode;
  final VoidCallback onTap;

  const _MicButton({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRecording = mode == NoteViewMode.recording;
    final isPaused = mode == NoteViewMode.paused;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
        child: Icon(
          isRecording
              ? Icons.pause
              : isPaused
                  ? Icons.play_arrow
                  : Icons.mic,
          size: 32,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
```

### NoteAppBar Widget

```dart
// lib/features/note/widgets/note_app_bar.dart

class NoteAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final ValueChanged<String> onTitleEdit;

  const NoteAppBar({
    this.title,
    required this.onTitleEdit,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: GestureDetector(
        onTap: () => _showTitleEditor(context),
        child: Text(
          title ?? 'New Note',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
            const PopupMenuItem(value: 'export', child: Text('Export')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ],
    );
  }

  void _showTitleEditor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TitleEditDialog(
        currentTitle: title ?? '',
        onSave: onTitleEdit,
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    // Handle menu actions
  }
}
```

## Layout Specification

```
┌────────────────────────────────────────────┐
│  [App Bar]                                 │
│  Title (editable)                      ... │
├────────────────────────────────────────────┤
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │                                      │ │
│  │     Transcription Text Area          │ │
│  │     (scrollable, selectable)         │ │
│  │                                      │ │
│  │     Live text updates during         │ │
│  │     recording. Editable when         │ │
│  │     not recording.                   │ │
│  │                                      │ │
│  └──────────────────────────────────────┘ │
│                                            │
├────────────────────────────────────────────┤
│  [TTS Player Controls]                     │
│  ▶  ─────────●────────────  00:04 / 00:17 │
├────────────────────────────────────────────┤
│                                            │
│           [Stop]  [Mic/Pause]              │
│                                            │
├────────────────────────────────────────────┤
│           [Bottom Navigation]              │
└────────────────────────────────────────────┘
```

## Acceptance Criteria

- [ ] NoteScreen displays correctly with all components
- [ ] Mic button starts recording on tap
- [ ] Recording indicator shows animated state
- [ ] Text updates in real-time during transcription
- [ ] Pause button pauses recording (preserves session)
- [ ] Stop button ends recording, triggers TTS generation
- [ ] TTS player appears after recording stops
- [ ] Play/pause controls TTS playback
- [ ] Seek slider allows position control
- [ ] Time display shows position and duration
- [ ] Title is editable via tap or menu
- [ ] Text is selectable when not recording
- [ ] Text is editable when not recording (regenerates TTS)
- [ ] Auto-scroll follows new transcription text
- [ ] Error states display as snackbar/toast
- [ ] Widget tests pass for all components

## Dependencies

### Requires
- WP-SETUP complete (Flutter project)
- WP-FFI complete (LexiconCoreService)
- WP-AUDIO complete (AudioCaptureService, TTSPlaybackService)
- WP-STATE complete (NoteNotifier, TTSPlaybackNotifier)
- WP-NAV complete (Navigation shell)

### Blocks
- None (end-point work package)

## Files to Create

| File | Purpose |
|------|---------|
| `lib/features/note/screens/note_screen.dart` | Main screen widget |
| `lib/features/note/widgets/transcription_text_area.dart` | Text display/edit area |
| `lib/features/note/widgets/tts_player_controls.dart` | TTS playback UI |
| `lib/features/note/widgets/recording_controls.dart` | Mic and stop buttons |
| `lib/features/note/widgets/note_app_bar.dart` | App bar with title |
| `lib/features/note/widgets/title_edit_dialog.dart` | Title editing dialog |
| `test/features/note/note_screen_test.dart` | Screen widget tests |
| `test/features/note/widgets/` | Widget unit tests |

## State Machine

```
┌────────────────────────────────────────────────────────────────────────┐
│                           NOTE VIEW STATES                              │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   [IDLE]                                                               │
│     │                                                                   │
│     │ (tap mic)                                                         │
│     ▼                                                                   │
│   [RECORDING] ──(tap pause)──▶ [PAUSED] ──(tap resume)──▶ [RECORDING] │
│     │                            │                                      │
│     │ (tap stop)                 │ (tap stop)                          │
│     ▼                            ▼                                      │
│   [PROCESSING] ◀─────────────────┘                                     │
│     │                                                                   │
│     │ (TTS generation complete)                                         │
│     ▼                                                                   │
│   [PLAYBACK_READY]                                                     │
│     │                                                                   │
│     │ (tap play)                                                        │
│     ▼                                                                   │
│   [PLAYING] ──(tap pause)──▶ [PAUSED_PLAYBACK] ──(tap play)──▶ [PLAYING]│
│     │                            │                                      │
│     │ (playback complete)        │ (new recording)                     │
│     ▼                            ▼                                      │
│   [IDLE] ◀───────────────────────┘                                     │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

## Research References

- [project.md: Note View Specification](../project.md#1-note-view)
- [Architecture: Note View State Machine](../design/architecture.md#note-view-state-machine)
- [R-TTS-01](../design/research/R-TTS-01-tts-pipeline.md) — TTS playback patterns

## Notes

- Haptic feedback on recording start/stop
- Auto-save on stop or app background
- Consider debouncing text edits before TTS regeneration
- Material 3 theming throughout

---

*Work package created: 2026-01-29*
