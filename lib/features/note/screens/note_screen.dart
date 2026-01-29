import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/service_providers.dart';
import '../../../services/tts_playback_service.dart';
import '../providers/note_provider.dart';
import '../widgets/note_app_bar.dart';
import '../widgets/recording_controls.dart';
import '../widgets/transcription_text_area.dart';
import '../widgets/tts_player_controls.dart';

/// Note View screen for single-speaker transcription with TTS playback.
///
/// This is the primary view for note-taking, memos, and voice journaling.
class NoteScreen extends ConsumerStatefulWidget {
  const NoteScreen({super.key});

  @override
  ConsumerState<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends ConsumerState<NoteScreen> {
  late TextEditingController _textController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noteState = ref.watch(noteProvider);
    final ttsService = ref.watch(ttsPlaybackProvider);

    // Sync text controller with state
    if (_textController.text != noteState.transcriptionText) {
      final selection = _textController.selection;
      _textController.text = noteState.transcriptionText;
      // Preserve cursor position if still valid
      if (selection.start <= _textController.text.length &&
          selection.end <= _textController.text.length) {
        _textController.selection = selection;
      }
    }

    // Auto-scroll during recording
    if (noteState.mode == NoteViewMode.recording) {
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

    final showPlaybackControls = noteState.mode == NoteViewMode.playbackReady ||
        noteState.mode == NoteViewMode.playing;

    return Scaffold(
      appBar: NoteAppBar(
        title: noteState.title,
        onTitleEdit: (title) => ref.read(noteProvider.notifier).updateTitle(title),
        onDelete: () {
          ref.read(noteProvider.notifier).clearSession();
        },
      ),
      body: Column(
        children: [
          // Transcription text area
          Expanded(
            child: TranscriptionTextArea(
              controller: _textController,
              scrollController: _scrollController,
              isEditable: noteState.mode != NoteViewMode.recording &&
                  noteState.mode != NoteViewMode.processing,
              onTextChanged: (text) {
                ref.read(noteProvider.notifier).updateText(text);
              },
            ),
          ),

          // TTS playback controls
          if (showPlaybackControls)
            TTSPlayerControls(
              position: ttsService.position,
              duration: ttsService.duration,
              playbackState: ttsService.playbackState,
              onPlay: () => ref.read(noteProvider.notifier).startPlayback(),
              onPause: () => ref.read(noteProvider.notifier).pausePlayback(),
              onSeek: (pos) => ref.read(noteProvider.notifier).seekPlayback(pos),
            ),

          // Recording controls
          RecordingControls(
            mode: noteState.mode,
            onRecordTap: _handleRecordTap,
            onStopTap: () => ref.read(noteProvider.notifier).stopRecording(),
          ),
        ],
      ),
    );
  }

  void _handleRecordTap() {
    final notifier = ref.read(noteProvider.notifier);
    final mode = ref.read(noteProvider).mode;

    switch (mode) {
      case NoteViewMode.idle:
      case NoteViewMode.playbackReady:
        notifier.startRecording();
        break;
      case NoteViewMode.recording:
        notifier.pauseRecording();
        break;
      case NoteViewMode.paused:
        notifier.resumeRecording();
        break;
      case NoteViewMode.playing:
        notifier.pausePlayback();
        break;
      default:
        break;
    }
  }
}
