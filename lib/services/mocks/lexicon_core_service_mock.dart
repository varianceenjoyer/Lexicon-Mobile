import 'package:uuid/uuid.dart';

import '../lexicon_core_service.dart';

/// Mock implementation of LexiconCoreService for development.
class LexiconCoreServiceMock implements LexiconCoreService {
  final _uuid = const Uuid();
  final List<Session> _sessions = [];

  LexiconCoreServiceMock() {
    // Add some mock data
    _sessions.addAll([
      Session(
        id: SessionId(_uuid.v4()),
        title: 'Meeting Notes',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        duration: const Duration(minutes: 15),
        sourceType: 'mic',
        viewType: ViewType.note,
        segments: [
          Segment(
            id: _uuid.v4(),
            text: 'This is a sample transcription from the meeting.',
            startMs: 0,
            endMs: 5000,
          ),
        ],
      ),
      Session(
        id: SessionId(_uuid.v4()),
        title: 'Interview Recording',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        duration: const Duration(minutes: 42),
        sourceType: 'mic',
        viewType: ViewType.chat,
        segments: [
          Segment(
            id: _uuid.v4(),
            speakerId: 0,
            text: 'Hello, welcome to the interview.',
            startMs: 0,
            endMs: 3000,
          ),
          Segment(
            id: _uuid.v4(),
            speakerId: 1,
            text: 'Thank you for having me.',
            startMs: 3500,
            endMs: 5500,
          ),
        ],
      ),
      Session(
        id: SessionId(_uuid.v4()),
        title: 'Quick Memo',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        duration: const Duration(minutes: 2),
        sourceType: 'mic',
        viewType: ViewType.note,
        segments: [
          Segment(
            id: _uuid.v4(),
            text: 'Remember to call the client tomorrow.',
            startMs: 0,
            endMs: 3000,
          ),
        ],
      ),
    ]);
  }

  @override
  Future<SessionId> createSession(SessionConfig config) async {
    await _simulateDelay();
    final id = SessionId(_uuid.v4());
    final now = DateTime.now();
    _sessions.add(Session(
      id: id,
      title: config.title ?? 'Untitled',
      createdAt: now,
      updatedAt: now,
      viewType: config.viewType,
      segments: [],
    ));
    return id;
  }

  @override
  Future<Session?> getSession(SessionId id) async {
    await _simulateDelay();
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SessionSummary>> listSessions() async {
    await _simulateDelay();
    return _sessions
        .map((s) => SessionSummary(
              id: s.id,
              title: s.title,
              createdAt: s.createdAt,
              updatedAt: s.updatedAt,
              duration: s.duration,
              viewType: s.viewType,
            ))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> deleteSession(SessionId id) async {
    await _simulateDelay();
    _sessions.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> renameSession(SessionId id, String newTitle) async {
    await _simulateDelay();
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index != -1) {
      final session = _sessions[index];
      _sessions[index] = Session(
        id: session.id,
        title: newTitle,
        createdAt: session.createdAt,
        updatedAt: DateTime.now(),
        duration: session.duration,
        sourceType: session.sourceType,
        viewType: session.viewType,
        segments: session.segments,
      );
    }
  }

  // Track audio processing state for mock transcription
  final Map<String, _MockTranscriptionState> _transcriptionStates = {};

  @override
  Future<TranscriptionHandle> startTranscription(
    SessionId sessionId,
    TranscriptionConfig config,
  ) async {
    await _simulateDelay();
    final handle = TranscriptionHandle(_uuid.v4());
    _transcriptionStates[handle.value] = _MockTranscriptionState(
      sessionId: sessionId,
      diarization: config.diarization,
    );
    return handle;
  }

  @override
  Future<List<Segment>> processAudio(
    TranscriptionHandle handle,
    List<double> samples,
  ) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final state = _transcriptionStates[handle.value];
    if (state == null) return [];

    // Calculate audio energy to detect if there's actual audio
    var energy = 0.0;
    for (final sample in samples) {
      energy += sample * sample;
    }
    energy = samples.isNotEmpty ? energy / samples.length : 0.0;

    // Only "transcribe" if there's significant audio energy (very low threshold)
    if (energy < 0.0001) {
      state.silenceCount++;
      return [];
    }

    state.silenceCount = 0;
    state.chunkCount++;

    // Generate mock transcription every ~1.5 seconds of audio (15 chunks at ~100ms each)
    if (state.chunkCount % 15 != 0) return [];

    final phrases = [
      'Hello world',
      'This is a test',
      'The quick brown fox',
      'Recording audio',
      'Speech recognition',
      'Transcription working',
      'Mock data here',
      'Testing one two three',
    ];

    final phraseIndex = (state.chunkCount ~/ 15) % phrases.length;
    final startMs = (state.chunkCount - 15) * 100;
    final endMs = state.chunkCount * 100;

    return [
      Segment(
        id: _uuid.v4(),
        speakerId: state.diarization ? (state.chunkCount ~/ 20) % 2 : null,
        text: phrases[phraseIndex],
        startMs: startMs,
        endMs: endMs,
      ),
    ];
  }

  @override
  Future<void> stopTranscription(TranscriptionHandle handle) async {
    await _simulateDelay();
  }

  @override
  Future<void> cancelTranscription(TranscriptionHandle handle) async {
    await _simulateDelay();
  }

  @override
  Future<AudioStream> synthesizeSpeech(String text, {String? voiceId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return AudioStream(_uuid.v4());
  }

  @override
  Future<void> cancelSynthesis(AudioStream stream) async {
    await _simulateDelay();
  }

  @override
  Future<SessionId> importAudioFile(
    String path,
    TranscriptionConfig config,
    void Function(double progress) onProgress,
  ) async {
    // Simulate import progress
    for (var i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      onProgress(i / 100);
    }

    final id = SessionId(_uuid.v4());
    final now = DateTime.now();
    _sessions.add(Session(
      id: id,
      title: path.split('/').last.replaceAll(RegExp(r'\.[^.]+$'), ''),
      createdAt: now,
      updatedAt: now,
      sourceType: 'import',
      viewType: config.diarization ? ViewType.chat : ViewType.note,
      segments: [
        Segment(
          id: _uuid.v4(),
          text: 'Imported audio transcription.',
          startMs: 0,
          endMs: 5000,
        ),
      ],
    ));
    return id;
  }

  @override
  Future<void> cancelImport(SessionId sessionId) async {
    await _simulateDelay();
  }

  @override
  Future<List<SearchResult>> searchTranscriptions(String query) async {
    await _simulateDelay();
    final results = <SearchResult>[];
    for (final session in _sessions) {
      for (final segment in session.segments) {
        if (segment.text.toLowerCase().contains(query.toLowerCase())) {
          results.add(SearchResult(
            sessionId: session.id,
            sessionTitle: session.title,
            matchedText: segment.text,
            segmentStartMs: segment.startMs,
          ));
        }
      }
    }
    return results;
  }

  @override
  void updateSettings({double? silenceThreshold, int? chunkSizeMs}) {
    // Mock doesn't need to do anything with settings
  }

  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

/// Internal state for mock transcription sessions.
class _MockTranscriptionState {
  final SessionId sessionId;
  final bool diarization;
  int chunkCount = 0;
  int silenceCount = 0;

  _MockTranscriptionState({
    required this.sessionId,
    required this.diarization,
  });
}
