import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../note/providers/note_provider.dart';
import '../../note/widgets/audio_level_meter.dart';
import '../../note/widgets/recording_controls.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_bubble_list.dart';

/// Chat View screen for multi-speaker diarized transcription.
///
/// Displays conversation as a chat-like interface with speaker bubbles.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late ScrollController _scrollController;
  Map<int, String> _speakerLabels = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Auto-scroll when new messages arrive during recording
    if (chatState.mode == ChatViewMode.recording) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }

    return Scaffold(
      appBar: ChatAppBar(
        title: chatState.title,
        onTitleEdit: (title) => ref.read(chatProvider.notifier).updateTitle(title),
        speakerLabels: _speakerLabels,
        onSpeakerLabelsEdit: (labels) {
          setState(() {
            _speakerLabels = labels;
          });
        },
        onDelete: () {
          ref.read(chatProvider.notifier).clearSession();
        },
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: ChatBubbleList(
              messages: chatState.messages,
              scrollController: _scrollController,
              speakerLabels: _speakerLabels,
            ),
          ),

          // Audio level meter
          AudioLevelMeter(
            level: chatState.audioLevel,
            isActive: chatState.mode == ChatViewMode.recording,
          ),

          // Recording controls
          RecordingControls(
            mode: _mapToNoteMode(chatState.mode),
            onRecordTap: _handleRecordTap,
            onStopTap: () => ref.read(chatProvider.notifier).stopRecording(),
          ),
        ],
      ),
    );
  }

  void _handleRecordTap() {
    final notifier = ref.read(chatProvider.notifier);
    final mode = ref.read(chatProvider).mode;

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

  /// Maps ChatViewMode to NoteViewMode for reusing RecordingControls.
  NoteViewMode _mapToNoteMode(ChatViewMode mode) {
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
