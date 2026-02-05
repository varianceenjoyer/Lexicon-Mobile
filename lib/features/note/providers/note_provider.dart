import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/wav_reader.dart';
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

  /// Debounce timer for batching segment updates.
  /// Reduces UI rebuilds during rapid transcription updates.
  Timer? _segmentDebounce;

  /// Pending segments to be added on next debounce flush.
  final List<Segment> _pendingSegments = [];

  /// Debounce duration for segment updates (50ms provides good balance).
  static const _debounceMs = 50;

  NoteNotifier(this._ref) : super(const NoteState());

  LexiconCoreService get _lexiconCore => _ref.read(lexiconCoreProvider);

  /// Flush pending segments to state immediately.
  void _flushPendingSegments() {
    if (_pendingSegments.isEmpty) return;

    final newText = state.transcriptionText +
        (state.transcriptionText.isEmpty ? '' : ' ') +
        _pendingSegments.map((s) => s.text).join(' ');

    state = state.copyWith(
      transcriptionText: newText,
      segments: [...state.segments, ..._pendingSegments],
    );

    _pendingSegments.clear();
  }

  /// Add segments with debouncing to reduce UI rebuilds.
  void _addSegmentsDebounced(List<Segment> segments) {
    _pendingSegments.addAll(segments);

    // Cancel existing timer
    _segmentDebounce?.cancel();

    // Set new timer to flush pending segments
    _segmentDebounce = Timer(
      const Duration(milliseconds: _debounceMs),
      _flushPendingSegments,
    );
  }

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

      // Reuse existing session or create a new one
      var sessionId = state.sessionId;
      if (sessionId == null) {
        sessionId = await _lexiconCore.createSession(
          const SessionConfig(viewType: ViewType.note),
        );
      }

      // Start transcription
      final handle = await _lexiconCore.startTranscription(
        sessionId,
        const TranscriptionConfig(diarization: false),
      );

      // Set state to recording BEFORE starting audio capture
      state = state.copyWith(
        mode: NoteViewMode.recording,
        sessionId: sessionId,
        transcriptionHandle: handle,
        clearError: true,
      );

      // Listen to audio stream - must be set up before starting capture
      _audioSubscription = audioService.audioStream.listen((samples) async {
        if (state.mode == NoteViewMode.recording && samples.isNotEmpty) {
          final segments = await _lexiconCore.processAudio(handle, samples);
          if (segments.isNotEmpty) {
            // Use debounced update to reduce UI rebuilds
            _addSegmentsDebounced(segments);
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

      // Flush any pending segments before stopping transcription
      _segmentDebounce?.cancel();
      _flushPendingSegments();

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

  /// Save current session (segments + title).
  Future<void> saveSession() async {
    try {
      // Create session if none exists
      var sessionId = state.sessionId;
      if (sessionId == null) {
        sessionId = await _lexiconCore.createSession(
          SessionConfig(title: state.title, viewType: ViewType.note),
        );
        state = state.copyWith(sessionId: sessionId);
      }

      // If text was manually edited and segments are empty/stale,
      // create a single segment from the current text
      var segments = state.segments;
      if (state.transcriptionText.isNotEmpty && segments.isEmpty) {
        segments = [
          Segment(
            id: const Uuid().v4(),
            text: state.transcriptionText,
            startMs: 0,
            endMs: 0,
          ),
        ];
      }

      await _lexiconCore.renameSession(sessionId, state.title);
      await _lexiconCore.updateSessionSegments(sessionId, segments);
      state = state.copyWith(isEdited: false, segments: segments);
      debugPrint('[Note] Saved session ${sessionId.value}: '
          '${segments.length} segments, title="${state.title}"');
    } catch (e) {
      debugPrint('[Note] Save failed: $e');
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
        mode: NoteViewMode.idle,
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

  /// Clear transcription text only, keeping session intact.
  void clearText() {
    _segmentDebounce?.cancel();
    _pendingSegments.clear();
    state = state.copyWith(
      transcriptionText: '',
      segments: [],
      isEdited: true,
    );
  }

  /// Run auto-test with bundled audio file.
  ///
  /// Loads the test audio from assets, processes it through the transcription
  /// pipeline, and logs the result for accuracy comparison.
  ///
  /// To use tarantulas.mp3, first convert it to WAV:
  ///   cd assets/audio && bash convert_audio.sh
  Future<void> runAutoTest() async {
    try {
      state = state.copyWith(
        mode: NoteViewMode.processing,
        transcriptionText: 'Loading test audio...',
        clearError: true,
      );

      // Load test audio from assets
      // Try tarantulas.wav first (converted from mp3), fall back to woodchuck_16k.wav
      const primaryPath = 'assets/audio/tarantulas.wav';
      const fallbackPath = 'assets/audio/woodchuck_16k.wav';

      ByteData bytes;
      String usedPath;
      String? expectedTranscription;
      try {
        bytes = await rootBundle.load(primaryPath);
        usedPath = primaryPath;
        // Expected transcription for tarantulas (excerpt from accuracy_check.md)
        expectedTranscription = '''Lo, this is the tarantula's den! Wouldst thou see the tarantula itself? Here hangeth its web: touch this, so that it may tremble.

There cometh the tarantula willingly: Welcome, tarantula! Black on thy back is thy triangle and symbol; and I know also what is in thy soul.

Revenge is in thy soul: wherever thou bitest, there ariseth black scab; with revenge, thy poison maketh the soul giddy!''';
      } catch (_) {
        debugPrint('[AutoTest] $primaryPath not found - run: cd assets/audio && bash convert_audio.sh');
        debugPrint('[AutoTest] Using fallback: $fallbackPath');
        bytes = await rootBundle.load(fallbackPath);
        usedPath = fallbackPath;
      }
      debugPrint('[AutoTest] ========================================');
      debugPrint('[AutoTest] Loading audio from $usedPath');

      final audioData = bytes.buffer.asUint8List();

      // Parse WAV file
      final parsed = WavReader.parse(audioData);
      debugPrint(
          '[AutoTest] Parsed: ${parsed.samples.length} samples at ${parsed.sampleRate}Hz');

      // Resample to 16kHz if needed
      var samples = parsed.samples;
      if (parsed.sampleRate != 16000) {
        samples = WavReader.resample(samples, parsed.sampleRate, 16000);
        debugPrint('[AutoTest] Resampled to ${samples.length} samples at 16kHz');
      }

      state = state.copyWith(
        transcriptionText: 'Processing ${(samples.length / 16000).toStringAsFixed(1)}s of audio...',
      );

      // Create a temporary session for transcription
      final sessionId = await _lexiconCore.createSession(
        const SessionConfig(viewType: ViewType.note),
      );

      final handle = await _lexiconCore.startTranscription(
        sessionId,
        const TranscriptionConfig(diarization: false),
      );

      // Process all audio at once (batch mode)
      // Feed in chunks to simulate real-time behavior
      const chunkSize = 16000 * 3; // 3 seconds at a time
      final allSegments = <Segment>[];

      for (var i = 0; i < samples.length; i += chunkSize) {
        final end = (i + chunkSize).clamp(0, samples.length);
        final chunk = samples.sublist(i, end);

        final segments = await _lexiconCore.processAudio(handle, chunk);
        allSegments.addAll(segments);

        // Update progress
        final progress = (end / samples.length * 100).round();
        state = state.copyWith(
          transcriptionText: 'Processing... $progress%',
        );

        // Small delay to allow UI updates
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Stop transcription
      await _lexiconCore.stopTranscription(handle);

      // Combine all segments
      final transcriptionText =
          allSegments.map((s) => s.text).join(' ').trim();

      // Log results for accuracy comparison
      debugPrint('[AutoTest] ========================================');
      debugPrint('[AutoTest] TRANSCRIPTION RESULT:');
      debugPrint('[AutoTest] $transcriptionText');
      debugPrint('[AutoTest] ----------------------------------------');
      debugPrint('[AutoTest] Segments: ${allSegments.length}');
      if (expectedTranscription != null) {
        debugPrint('[AutoTest] ----------------------------------------');
        debugPrint('[AutoTest] EXPECTED (from accuracy_check.md):');
        debugPrint('[AutoTest] $expectedTranscription');
      }
      debugPrint('[AutoTest] ========================================');

      state = state.copyWith(
        mode: NoteViewMode.playbackReady,
        sessionId: sessionId,
        transcriptionText: transcriptionText.isEmpty
            ? '(No transcription result)'
            : transcriptionText,
        segments: allSegments,
        title: 'Auto Test Result',
      );
    } catch (e) {
      debugPrint('[AutoTest] ========================================');
      debugPrint('[AutoTest] ERROR: $e');
      debugPrint('[AutoTest] ========================================');
      state = state.copyWith(
        mode: NoteViewMode.error,
        errorMessage: 'Auto-test failed: $e',
      );
    }
  }

  /// Clear current session.
  void clearSession() {
    _audioSubscription?.cancel();
    _audioLevelSubscription?.cancel();
    _segmentDebounce?.cancel();
    _pendingSegments.clear();
    state = const NoteState();
    _ref.read(appStateProvider.notifier).setRecording(false);
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _audioLevelSubscription?.cancel();
    _segmentDebounce?.cancel();
    _pendingSegments.clear();
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
