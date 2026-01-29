---
id: WP-CHAT
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
tags: [chat, view, diarization, conversation, speakers]
---

# WP-CHAT: Chat View Implementation

## Overview

Implement the Chat View screen for multi-speaker diarized transcription. This view displays transcribed speech as a conversation with chat bubbles, similar to a messaging app, with speakers visually differentiated.

## Scope

### Included
- ChatScreen widget with diarized recording workflow
- Chat bubble list (left/right aligned by speaker)
- Speaker color differentiation
- Recording controls (identical to Note View)
- Session title display and editing
- Real-time bubble updates during recording
- Speaker label assignment (future: editable names)

### Excluded
- Audio capture implementation (provided by WP-AUDIO)
- FFI calls to Lexicon Core (provided by WP-FFI)
- State management logic (provided by WP-STATE)
- Navigation shell (provided by WP-NAV)
- TTS playback (not supported in Chat View per spec)

## Interface Contract

### ChatScreen Widget

```dart
// lib/features/chat/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final SessionId? initialSessionId;

  const ChatScreen({this.initialSessionId, super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late ScrollController _scrollController;

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);

    return Scaffold(
      appBar: ChatAppBar(
        title: chatState.sessionTitle,
        onTitleEdit: (title) => ref.read(chatNotifierProvider.notifier).updateTitle(title),
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatBubbleList(
              messages: chatState.messages,
              scrollController: _scrollController,
            ),
          ),
          RecordingControls(
            mode: _mapToNoteMode(chatState.mode),
            onRecordTap: _handleRecordTap,
          ),
        ],
      ),
    );
  }

  void _handleRecordTap() {
    final notifier = ref.read(chatNotifierProvider.notifier);
    final mode = ref.read(chatNotifierProvider).mode;

    switch (mode) {
      case ChatViewMode.idle:
        notifier.startRecording();
        break;
      case ChatViewMode.recording:
        notifier.pauseRecording();
        break;
      case ChatViewMode.paused:
        notifier.resumeRecording();
        break;
      default:
        break;
    }
  }

  NoteViewMode _mapToNoteMode(ChatViewMode mode) {
    // Reuse RecordingControls widget by mapping modes
    switch (mode) {
      case ChatViewMode.idle:
        return NoteViewMode.idle;
      case ChatViewMode.recording:
        return NoteViewMode.recording;
      case ChatViewMode.paused:
        return NoteViewMode.paused;
      case ChatViewMode.error:
        return NoteViewMode.error;
    }
  }
}
```

### ChatBubbleList Widget

```dart
// lib/features/chat/widgets/chat_bubble_list.dart

class ChatBubbleList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;

  const ChatBubbleList({
    required this.messages,
    required this.scrollController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isLeftAligned = message.speakerId % 2 == 0;

        return ChatBubble(
          message: message,
          isLeftAligned: isLeftAligned,
          speakerColor: _getSpeakerColor(context, message.speakerId),
        );
      },
    );
  }

  Color _getSpeakerColor(BuildContext context, int speakerId) {
    // Alternate between two primary colors based on speaker_id % 2
    final colorScheme = Theme.of(context).colorScheme;
    return speakerId % 2 == 0
        ? colorScheme.primary
        : colorScheme.tertiary;
  }
}
```

### ChatBubble Widget

```dart
// lib/features/chat/widgets/chat_bubble.dart

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLeftAligned;
  final Color speakerColor;

  const ChatBubble({
    required this.message,
    required this.isLeftAligned,
    required this.speakerColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isLeftAligned ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isLeftAligned) const Spacer(flex: 1),
          Flexible(
            flex: 3,
            child: GestureDetector(
              onLongPress: () => _showTimestamp(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: speakerColor.withOpacity(0.15),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isLeftAligned ? 4 : 16),
                    bottomRight: Radius.circular(isLeftAligned ? 16 : 4),
                  ),
                  border: Border.all(
                    color: speakerColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _speakerLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: speakerColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      message.text,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLeftAligned) const Spacer(flex: 1),
        ],
      ),
    );
  }

  String get _speakerLabel => 'Speaker ${message.speakerId + 1}';

  void _showTimestamp(BuildContext context) {
    final startTime = Duration(milliseconds: message.startMs);
    final formatted = _formatDuration(startTime);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Timestamp: $formatted'),
        duration: const Duration(seconds: 2),
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

### ChatAppBar Widget

```dart
// lib/features/chat/widgets/chat_app_bar.dart

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final ValueChanged<String> onTitleEdit;

  const ChatAppBar({
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
          title ?? 'New Conversation',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
            const PopupMenuItem(value: 'speakers', child: Text('Speaker Labels')),
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

### SpeakerLabelsDialog Widget

```dart
// lib/features/chat/widgets/speaker_labels_dialog.dart

class SpeakerLabelsDialog extends StatefulWidget {
  final Map<int, String> currentLabels;
  final ValueChanged<Map<int, String>> onSave;

  const SpeakerLabelsDialog({
    required this.currentLabels,
    required this.onSave,
    super.key,
  });

  @override
  State<SpeakerLabelsDialog> createState() => _SpeakerLabelsDialogState();
}

class _SpeakerLabelsDialogState extends State<SpeakerLabelsDialog> {
  late Map<int, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var entry in widget.currentLabels.entries)
        entry.key: TextEditingController(text: entry.value),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Speaker Labels'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var entry in _controllers.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: 'Speaker ${entry.key + 1}',
                  hintText: 'e.g., Alice, Bob',
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final labels = {
              for (var entry in _controllers.entries)
                entry.key: entry.value.text,
            };
            widget.onSave(labels);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
```

## Layout Specification

```
┌────────────────────────────────────────────┐
│  [App Bar]                                 │
│  Conversation Title                    ... │
├────────────────────────────────────────────┤
│                                            │
│  ┌──────────────────┐                     │
│  │ Speaker 1        │                     │
│  │ Hello, how are   │                     │
│  │ you doing today? │                     │
│  └──────────────────┘                     │
│                                            │
│                     ┌──────────────────┐  │
│                     │ Speaker 2        │  │
│                     │ I'm doing great, │  │
│                     │ thanks!          │  │
│                     └──────────────────┘  │
│                                            │
│  ┌──────────────────┐                     │
│  │ Speaker 1        │                     │
│  │ Wonderful! Let's │                     │
│  │ get started...   │                     │
│  └──────────────────┘                     │
│                                            │
├────────────────────────────────────────────┤
│                                            │
│           [Stop]  [Mic/Pause]              │
│                                            │
├────────────────────────────────────────────┤
│           [Bottom Navigation]              │
└────────────────────────────────────────────┘
```

## Speaker Alignment Logic

```
┌─────────────────────────────────────────────────────────────────────┐
│                     SPEAKER ALIGNMENT RULES                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  speaker_id │ Alignment │ Color           │ Label                   │
│  ───────────┼───────────┼─────────────────┼──────────────────────── │
│      0      │   Left    │ Primary (Blue)  │ Speaker 1 (or custom)   │
│      1      │   Right   │ Tertiary (Teal) │ Speaker 2 (or custom)   │
│      2      │   Left    │ Primary (Blue)  │ Speaker 3 (or custom)   │
│      3      │   Right   │ Tertiary (Teal) │ Speaker 4 (or custom)   │
│     ...     │   ...     │ Pattern repeats │ ...                     │
│                                                                      │
│  Rule: isLeftAligned = (speaker_id % 2 == 0)                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Acceptance Criteria

- [ ] ChatScreen displays correctly with all components
- [ ] Mic button starts diarized recording on tap
- [ ] Recording indicator shows animated state
- [ ] Chat bubbles appear in real-time during transcription
- [ ] Bubbles align left for even speaker_id, right for odd
- [ ] Speaker colors differentiate speakers visually
- [ ] Speaker labels show "Speaker N" by default
- [ ] Long-press on bubble shows timestamp
- [ ] Pause button pauses recording
- [ ] Stop button ends recording and saves
- [ ] Title is editable via tap or menu
- [ ] Speaker labels dialog allows custom names
- [ ] Chat list auto-scrolls to new messages
- [ ] Recorded bubbles are selectable (text copy)
- [ ] Error states display as snackbar/toast
- [ ] Widget tests pass for all components

## Dependencies

### Requires
- WP-SETUP complete (Flutter project)
- WP-FFI complete (LexiconCoreService with diarization)
- WP-AUDIO complete (AudioCaptureService)
- WP-STATE complete (ChatNotifier)
- WP-NAV complete (Navigation shell)

### Blocks
- None (end-point work package)

## Files to Create

| File | Purpose |
|------|---------|
| `lib/features/chat/screens/chat_screen.dart` | Main screen widget |
| `lib/features/chat/widgets/chat_bubble_list.dart` | Scrollable bubble list |
| `lib/features/chat/widgets/chat_bubble.dart` | Individual bubble widget |
| `lib/features/chat/widgets/chat_app_bar.dart` | App bar with title |
| `lib/features/chat/widgets/speaker_labels_dialog.dart` | Speaker name editor |
| `test/features/chat/chat_screen_test.dart` | Screen widget tests |
| `test/features/chat/widgets/` | Widget unit tests |

## Research References

- [project.md: Chat View Specification](../project.md#2-chat-view)
- [Architecture: Chat View Architecture](../design/architecture.md#chat-view-architecture)
- [R-DIAR-01](../design/research/R-DIAR-01-diarization-system.md) — Diarization patterns

## Notes

- RecordingControls widget shared with Note View
- No TTS playback in Chat View (per spec)
- Speaker labels saved to session metadata
- Consider grouping consecutive same-speaker messages
- Material 3 theming throughout

---

*Work package created: 2026-01-29*
