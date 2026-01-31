import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_state_provider.dart';
import '../../../providers/service_providers.dart';
import '../../../services/lexicon_core_service.dart';

/// Chat view mode state.
enum ChatViewMode {
  idle,
  recording,
  paused,
  error,
}

/// Chat message model.
class ChatMessage {
  final String id;
  final int speakerId;
  final String text;
  final int startMs;
  final int endMs;

  const ChatMessage({
    required this.id,
    required this.speakerId,
    required this.text,
    required this.startMs,
    required this.endMs,
  });

  factory ChatMessage.fromSegment(Segment segment) {
    return ChatMessage(
      id: segment.id,
      speakerId: segment.speakerId ?? 0,
      text: segment.text,
      startMs: segment.startMs,
      endMs: segment.endMs,
    );
  }
}

/// Chat view state.
class ChatState {
  final ChatViewMode mode;
  final List<ChatMessage> messages;
  final SessionId? sessionId;
  final String title;
  final String? errorMessage;
  final TranscriptionHandle? transcriptionHandle;
  final double audioLevel;

  const ChatState({
    this.mode = ChatViewMode.idle,
    this.messages = const [],
    this.sessionId,
    this.title = 'Untitled Chat',
    this.errorMessage,
    this.transcriptionHandle,
    this.audioLevel = 0.0,
  });

  ChatState copyWith({
    ChatViewMode? mode,
    List<ChatMessage>? messages,
    SessionId? sessionId,
    bool clearSessionId = false,
    String? title,
    String? errorMessage,
    bool clearError = false,
    TranscriptionHandle? transcriptionHandle,
    bool clearHandle = false,
    double? audioLevel,
  }) {
    return ChatState(
      mode: mode ?? this.mode,
      messages: messages ?? this.messages,
      sessionId: clearSessionId ? null : (sessionId ?? this.sessionId),
      title: title ?? this.title,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      transcriptionHandle:
          clearHandle ? null : (transcriptionHandle ?? this.transcriptionHandle),
      audioLevel: audioLevel ?? this.audioLevel,
    );
  }
}

/// Chat view state notifier.
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  StreamSubscription<List<double>>? _audioSubscription;
  StreamSubscription<double>? _audioLevelSubscription;

  ChatNotifier(this._ref) : super(const ChatState());

  LexiconCoreService get _lexiconCore => _ref.read(lexiconCoreProvider);

  /// Start a new chat recording session.
  Future<void> startRecording() async {
    try {
      // Request permission
      final audioService = _ref.read(audioCaptureProvider);
      final hasPermission = await audioService.requestPermission();
      if (!hasPermission) {
        state = state.copyWith(
          mode: ChatViewMode.error,
          errorMessage: 'Microphone permission denied',
        );
        return;
      }

      // Create session
      final sessionId = await _lexiconCore.createSession(
        const SessionConfig(viewType: ViewType.chat),
      );

      // Start transcription with diarization
      final handle = await _lexiconCore.startTranscription(
        sessionId,
        const TranscriptionConfig(diarization: true),
      );

      // Set state to recording BEFORE starting audio capture
      state = state.copyWith(
        mode: ChatViewMode.recording,
        sessionId: sessionId,
        transcriptionHandle: handle,
        clearError: true,
      );

      // Listen to audio stream - must be set up before starting capture
      _audioSubscription = audioService.audioStream.listen((samples) async {
        if (state.mode == ChatViewMode.recording) {
          final segments = await _lexiconCore.processAudio(handle, samples);
          if (segments.isNotEmpty) {
            final newMessages =
                segments.map((s) => ChatMessage.fromSegment(s)).toList();
            state = state.copyWith(
              messages: [...state.messages, ...newMessages],
            );
          }
        }
      });

      // Listen to audio level stream
      _audioLevelSubscription = audioService.audioLevelStream.listen((level) {
        state = state.copyWith(audioLevel: level);
      });

      // Start audio capture after subscriptions are ready
      await audioService.start();

      _ref.read(appStateProvider.notifier).setRecording(true);
    } catch (e) {
      state = state.copyWith(
        mode: ChatViewMode.error,
        errorMessage: 'Failed to start recording: $e',
      );
    }
  }

  /// Pause the current recording.
  Future<void> pauseRecording() async {
    if (state.mode != ChatViewMode.recording) return;

    final audioService = _ref.read(audioCaptureProvider);
    await audioService.pause();
    state = state.copyWith(mode: ChatViewMode.paused);
  }

  /// Resume a paused recording.
  Future<void> resumeRecording() async {
    if (state.mode != ChatViewMode.paused) return;

    final audioService = _ref.read(audioCaptureProvider);
    await audioService.resume();
    state = state.copyWith(mode: ChatViewMode.recording);
  }

  /// Stop recording and save.
  Future<void> stopRecording() async {
    if (state.mode != ChatViewMode.recording &&
        state.mode != ChatViewMode.paused) {
      return;
    }

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

      state = state.copyWith(
        mode: ChatViewMode.idle,
        audioLevel: 0.0,
        clearHandle: true,
      );

      _ref.read(appStateProvider.notifier).setRecording(false);
    } catch (e) {
      state = state.copyWith(
        mode: ChatViewMode.error,
        errorMessage: 'Failed to stop recording: $e',
      );
    }
  }

  /// Update the chat title.
  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  /// Load existing session.
  Future<void> loadSession(SessionId id) async {
    try {
      final session = await _lexiconCore.getSession(id);
      if (session == null) {
        state = state.copyWith(
          mode: ChatViewMode.error,
          errorMessage: 'Session not found',
        );
        return;
      }

      final messages =
          session.segments.map((s) => ChatMessage.fromSegment(s)).toList();
      state = ChatState(
        mode: ChatViewMode.idle,
        sessionId: id,
        title: session.title,
        messages: messages,
      );
    } catch (e) {
      state = state.copyWith(
        mode: ChatViewMode.error,
        errorMessage: 'Failed to load session: $e',
      );
    }
  }

  /// Clear current session.
  void clearSession() {
    _audioSubscription?.cancel();
    _audioLevelSubscription?.cancel();
    state = const ChatState();
    _ref.read(appStateProvider.notifier).setRecording(false);
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _audioLevelSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for audio level in chat (0.0 to 1.0).
final chatAudioLevelProvider = Provider<double>((ref) {
  return ref.watch(chatProvider).audioLevel;
});

/// Provider for Chat view state.
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref),
);

/// Provider for current chat mode.
final chatModeProvider = Provider<ChatViewMode>((ref) {
  return ref.watch(chatProvider).mode;
});

/// Provider for chat messages.
final chatMessagesProvider = Provider<List<ChatMessage>>((ref) {
  return ref.watch(chatProvider).messages;
});
