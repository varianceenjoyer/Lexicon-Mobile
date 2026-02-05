/// Interface for Lexicon Core FFI service.
///
/// This will be implemented by the actual FFI bindings when integrated
/// with Lexicon Local Server. For now, a mock implementation is used.
abstract class LexiconCoreService {
  /// Create a new transcription session.
  Future<SessionId> createSession(SessionConfig config);

  /// Get a session by ID.
  Future<Session?> getSession(SessionId id);

  /// List all sessions.
  Future<List<SessionSummary>> listSessions();

  /// Delete a session.
  Future<void> deleteSession(SessionId id);

  /// Rename a session.
  Future<void> renameSession(SessionId id, String newTitle);

  /// Start transcription for a session.
  Future<TranscriptionHandle> startTranscription(
    SessionId sessionId,
    TranscriptionConfig config,
  );

  /// Process audio samples and return transcribed segments.
  Future<List<Segment>> processAudio(
    TranscriptionHandle handle,
    List<double> samples,
  );

  /// Stop transcription.
  Future<void> stopTranscription(TranscriptionHandle handle);

  /// Cancel transcription.
  Future<void> cancelTranscription(TranscriptionHandle handle);

  /// Synthesize speech from text.
  Future<AudioStream> synthesizeSpeech(String text, {String? voiceId});

  /// Cancel speech synthesis.
  Future<void> cancelSynthesis(AudioStream stream);

  /// Import audio file and transcribe.
  Future<SessionId> importAudioFile(
    String path,
    TranscriptionConfig config,
    void Function(double progress) onProgress,
  );

  /// Cancel an ongoing import.
  Future<void> cancelImport(SessionId sessionId);

  /// Search transcriptions using full-text search.
  Future<List<SearchResult>> searchTranscriptions(String query);

  /// Update the segments for a session.
  Future<void> updateSessionSegments(SessionId id, List<Segment> segments);

  /// Update audio processing settings.
  void updateSettings({double? silenceThreshold, int? chunkSizeMs});
}

/// Session identifier
class SessionId {
  final String value;

  const SessionId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'SessionId($value)';
}

/// Configuration for creating a new session.
class SessionConfig {
  final String? title;
  final ViewType viewType;

  const SessionConfig({
    this.title,
    required this.viewType,
  });
}

/// Type of view for a session.
enum ViewType { note, chat }

/// Full session data.
class Session {
  final SessionId id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Duration? duration;
  final String? sourceType;
  final ViewType viewType;
  final List<Segment> segments;

  const Session({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.duration,
    this.sourceType,
    required this.viewType,
    required this.segments,
  });

  Map<String, dynamic> toJson() => {
        'id': id.value,
        'title': title,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'duration': duration?.inMilliseconds,
        'sourceType': sourceType,
        'viewType': viewType.name,
        'segments': segments.map((s) => s.toJson()).toList(),
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: SessionId(json['id'] as String),
        title: json['title'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
        duration: json['duration'] != null
            ? Duration(milliseconds: json['duration'] as int)
            : null,
        sourceType: json['sourceType'] as String?,
        viewType: ViewType.values.byName(json['viewType'] as String),
        segments: (json['segments'] as List)
            .map((s) => Segment.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

/// Session summary for list views.
class SessionSummary {
  final SessionId id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Duration? duration;
  final ViewType viewType;

  const SessionSummary({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.duration,
    required this.viewType,
  });
}

/// Transcription configuration.
class TranscriptionConfig {
  final bool diarization;
  final String? language;
  final bool translateToEnglish;

  const TranscriptionConfig({
    this.diarization = false,
    this.language,
    this.translateToEnglish = false,
  });
}

/// Handle for an active transcription.
class TranscriptionHandle {
  final String value;

  const TranscriptionHandle(this.value);
}

/// A transcribed segment.
class Segment {
  final String id;
  final int? speakerId;
  final String text;
  final int startMs;
  final int endMs;
  final double? confidence;

  const Segment({
    required this.id,
    this.speakerId,
    required this.text,
    required this.startMs,
    required this.endMs,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'speakerId': speakerId,
        'text': text,
        'startMs': startMs,
        'endMs': endMs,
        'confidence': confidence,
      };

  factory Segment.fromJson(Map<String, dynamic> json) => Segment(
        id: json['id'] as String,
        speakerId: json['speakerId'] as int?,
        text: json['text'] as String,
        startMs: json['startMs'] as int,
        endMs: json['endMs'] as int,
        confidence: (json['confidence'] as num?)?.toDouble(),
      );
}

/// Audio stream handle for TTS.
class AudioStream {
  final String value;

  const AudioStream(this.value);
}

/// Search result.
class SearchResult {
  final SessionId sessionId;
  final String sessionTitle;
  final String matchedText;
  final int segmentStartMs;

  const SearchResult({
    required this.sessionId,
    required this.sessionTitle,
    required this.matchedText,
    required this.segmentStartMs,
  });
}
