import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_state_provider.dart';
import '../../../providers/service_providers.dart';
import '../../../services/lexicon_core_service.dart';

/// Note view mode state.
enum NoteViewMode {
  idle,
  recording,
  paused,
  processing,
  playbackReady,
  playing,
  error,
}

/// Note view state.
class NoteState {
  final NoteViewMode mode;
  final String transcriptionText;
  final List<Segment> segments;
  final SessionId? sessionId;
  final String title;
  final bool isEdited;
  final String? errorMessage;
  final TranscriptionHandle? transcriptionHandle;
  final double audioLevel;

  const NoteState({
    this.mode = NoteViewMode.idle,
    this.transcriptionText = '',
    this.segments = const [],
    this.sessionId,
    this.title = 'Untitled Note',
    this.isEdited = false,
    this.errorMessage,
    this.transcriptionHandle,
    this.audioLevel = 0.0,
  });

  NoteState copyWith({
    NoteViewMode? mode,
    String? transcriptionText,
    List<Segment>? segments,
    SessionId? sessionId,
    bool clearSessionId = false,
    String? title,
    bool? isEdited,
    String? errorMessage,
    bool clearError = false,
    TranscriptionHandle? transcriptionHandle,
    bool clearHandle = false,
    double? audioLevel,
  }) {
    return NoteState(
      mode: mode ?? this.mode,
      transcriptionText: transcriptionText ?? this.transcriptionText,
      segments: segments ?? this.segments,
      sessionId: clearSessionId ? null : (sessionId ?? this.sessionId),
      title: title ?? this.title,
      isEdited: isEdited ?? this.isEdited,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      transcriptionHandle:
          clearHandle ? null : (transcriptionHandle ?? this.transcriptionHandle),
      audioLevel: audioLevel ?? this.audioLevel,
    );
  }
}

/// Note view state notifier.
class NoteNotifier extends StateNotifier<NoteState> {
  final Ref _ref;
  StreamSubscription<List<double>>? _audioSubscription;
  StreamSubscription<double>? _audioLevelSubscription;

  NoteNotifier(this._ref) : super(const NoteState());

  LexiconCoreService get _lexiconCore => _ref.read(lexiconCoreProvider);

  /// Start a new recording session.
  Future<void> startRecording() async {
    try {
      // Request permission
      final audioService = _ref.read(audioCaptureProvider);
      final hasPermission = await audioService.requestPermission();
      if (!hasPermission) {
        state = state.copyWith(
          mode: NoteViewMode.error,
          errorMessage: 'Microphone permission denied',
        );
        return;
      }

      // Create session
      final sessionId = await _lexiconCore.createSession(
        const SessionConfig(viewType: ViewType.note),
      );

      // Start transcription
      final handle = await _lexiconCore.startTranscription(
        sessionId,
        const TranscriptionConfig(diarization: false),
      );

      // Start audio capture
      await audioService.start();

      // Listen to audio stream
      _audioSubscription = audioService.audioStream.listen((samples) async {
        if (state.mode == NoteViewMode.recording) {
          final segments = await _lexiconCore.processAudio(handle, samples);
          if (segments.isNotEmpty) {
            final newText = state.transcriptionText +
                (state.transcriptionText.isEmpty ? '' : ' ') +
                segments.map((s) => s.text).join(' ');
            state = state.copyWith(
              transcriptionText: newText,
              segments: [...state.segments, ...segments],
            );
          }
        }
      });

      // Listen to audio level stream
      _audioLevelSubscription = audioService.audioLevelStream.listen((level) {
        state = state.copyWith(audioLevel: level);
      });

      state = state.copyWith(
        mode: NoteViewMode.recording,
        sessionId: sessionId,
        transcriptionHandle: handle,
        clearError: true,
      );

      _ref.read(appStateProvider.notifier).setRecording(true);
    } catch (e) {
      state = state.copyWith(
        mode: NoteViewMode.error,
        errorMessage: 'Failed to start recording: $e',
      );
    }
  }

  /// Pause the current recording.
  Future<void> pauseRecording() async {
    if (state.mode != NoteViewMode.recording) return;

    final audioService = _ref.read(audioCaptureProvider);
    await audioService.pause();
    state = state.copyWith(mode: NoteViewMode.paused);
  }

  /// Resume a paused recording.
  Future<void> resumeRecording() async {
    if (state.mode != NoteViewMode.paused) return;

    final audioService = _ref.read(audioCaptureProvider);
    await audioService.resume();
    state = state.copyWith(mode: NoteViewMode.recording);
  }

  /// Stop recording and prepare for playback.
  Future<void> stopRecording() async {
    if (state.mode != NoteViewMode.recording &&
        state.mode != NoteViewMode.paused) {
      return;
    }

    state = state.copyWith(mode: NoteViewMode.processing);

    try {
      // Stop audio capture
      final audioService = _ref.read(audioCaptureProvider);
      await audioService.stop();
      await _audioSubscription?.cancel();
      _audioSubscription = null;
      await _audioLevelSubscription?.cancel();
      _audioLevelSubscription = null;

      // Stop transcription
      if (state.transcriptionHandle != null) {
        await _lexiconCore.stopTranscription(state.transcriptionHandle!);
      }

      // Generate TTS (prepare for playback)
      // For now, just mark as ready
      state = state.copyWith(
        mode: NoteViewMode.playbackReady,
        audioLevel: 0.0,
        clearHandle: true,
      );

      _ref.read(appStateProvider.notifier).setRecording(false);
    } catch (e) {
      state = state.copyWith(
        mode: NoteViewMode.error,
        errorMessage: 'Failed to stop recording: $e',
      );
    }
  }

  /// Update transcription text (manual edit).
  void updateText(String text) {
    state = state.copyWith(
      transcriptionText: text,
      isEdited: true,
    );
  }

  /// Update the note title.
  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  /// Start TTS playback.
  Future<void> startPlayback() async {
    if (state.transcriptionText.isEmpty) return;

    try {
      final ttsService = _ref.read(ttsPlaybackProvider);
      // TODO: Generate TTS from Lexicon Core and play
      await ttsService.loadFromBytes([]);
      await ttsService.play();
      state = state.copyWith(mode: NoteViewMode.playing);
    } catch (e) {
      state = state.copyWith(
        mode: NoteViewMode.error,
        errorMessage: 'Failed to play audio: $e',
      );
    }
  }

  /// Pause TTS playback.
  Future<void> pausePlayback() async {
    final ttsService = _ref.read(ttsPlaybackProvider);
    await ttsService.pause();
    state = state.copyWith(mode: NoteViewMode.playbackReady);
  }

  /// Seek TTS playback.
  Future<void> seekPlayback(Duration position) async {
    final ttsService = _ref.read(ttsPlaybackProvider);
    await ttsService.seek(position);
  }

  /// Save current session.
  Future<void> saveSession() async {
    if (state.sessionId == null) return;

    try {
      await _lexiconCore.renameSession(state.sessionId!, state.title);
      state = state.copyWith(isEdited: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save: $e',
      );
    }
  }

  /// Load existing session.
  Future<void> loadSession(SessionId id) async {
    try {
      final session = await _lexiconCore.getSession(id);
      if (session == null) {
        state = state.copyWith(
          mode: NoteViewMode.error,
          errorMessage: 'Session not found',
        );
        return;
      }

      final text = session.segments.map((s) => s.text).join(' ');
      state = NoteState(
        mode: NoteViewMode.playbackReady,
        sessionId: id,
        title: session.title,
        transcriptionText: text,
        segments: session.segments,
      );
    } catch (e) {
      state = state.copyWith(
        mode: NoteViewMode.error,
        errorMessage: 'Failed to load session: $e',
      );
    }
  }

  /// Clear current session.
  void clearSession() {
    _audioSubscription?.cancel();
    _audioLevelSubscription?.cancel();
    state = const NoteState();
    _ref.read(appStateProvider.notifier).setRecording(false);
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _audioLevelSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for Note view state.
final noteProvider = StateNotifierProvider<NoteNotifier, NoteState>(
  (ref) => NoteNotifier(ref),
);

/// Provider for current note mode.
final noteModeProvider = Provider<NoteViewMode>((ref) {
  return ref.watch(noteProvider).mode;
});

/// Provider for note transcription text.
final noteTextProvider = Provider<String>((ref) {
  return ref.watch(noteProvider).transcriptionText;
});

/// Provider for audio level (0.0 to 1.0).
final audioLevelProvider = Provider<double>((ref) {
  return ref.watch(noteProvider).audioLevel;
});
