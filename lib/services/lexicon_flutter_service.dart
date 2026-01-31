import 'dart:async';
import 'dart:io';
import 'dart:math' show sqrt;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../src/rust/api.dart';
import '../src/rust/error.dart';
import '../src/rust/frb_generated.dart';
import '../src/rust/types.dart' as rust;
import 'lexicon_core_service.dart';

/// Default model filename.
const String kDefaultModelName = 'ggml-tiny-q5_1.bin';

/// Asset path for the bundled model.
const String kModelAssetPath = 'assets/models/$kDefaultModelName';

/// Real implementation of LexiconCoreService using native Lexicon library.
class LexiconFlutterService implements LexiconCoreService {
  static bool _initialized = false;
  static String? _dataDir;
  static String? _modelDir;

  // Singleton instance
  static LexiconFlutterService? _instance;

  /// Get the singleton instance of the service.
  factory LexiconFlutterService() {
    _instance ??= LexiconFlutterService._internal();
    return _instance!;
  }

  LexiconFlutterService._internal();

  final _uuid = const Uuid();

  // Streaming transcriber for real-time transcription
  StreamingTranscriber? _streamingTranscriber;
  bool _modelLoaded = false;

  // Session storage (in-memory for now, will use SQLite later)
  final Map<String, Session> _sessions = {};

  // Active transcription state
  final Map<String, _ActiveTranscription> _activeTranscriptions = {};

  // Configurable settings (updated via updateSettings)
  double _silenceThreshold = 0.01;
  int _chunkSizeMs = 100;

  @override
  void updateSettings({double? silenceThreshold, int? chunkSizeMs}) {
    if (silenceThreshold != null) {
      _silenceThreshold = silenceThreshold.clamp(0.0, 0.1);
    }
    if (chunkSizeMs != null) {
      _chunkSizeMs = chunkSizeMs.clamp(100, 1000);
    }
  }

  /// Initialize the Lexicon library. Call once at app startup.
  static Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('[LexiconFlutterService] Initializing...');

    // Initialize flutter_rust_bridge
    await LexiconFlutter.init();
    debugPrint('[LexiconFlutterService] Flutter-Rust bridge initialized');

    // Get app directories
    final appDir = await getApplicationDocumentsDirectory();
    _dataDir = appDir.path;
    _modelDir = '${appDir.path}/models';
    debugPrint('[LexiconFlutterService] Data dir: $_dataDir');
    debugPrint('[LexiconFlutterService] Model dir: $_modelDir');

    // Initialize Lexicon core
    initLexicon(dataDir: _dataDir!);

    // Log library version and platform info
    final version = getVersion();
    final platformInfo = getPlatformInfo();
    debugPrint('[LexiconFlutterService] Lexicon version: $version');
    debugPrint('[LexiconFlutterService] Platform: ${platformInfo.platform}');
    debugPrint('[LexiconFlutterService] Model tier: ${platformInfo.modelTier}');
    debugPrint('[LexiconFlutterService] Available memory: ${platformInfo.availableMemoryMb} MB');

    _initialized = true;
    debugPrint('[LexiconFlutterService] Initialization complete');
  }

  /// Check if the library is initialized.
  static bool get isInitialized => _initialized;

  /// Get the data directory path.
  static String? get dataDir => _dataDir;

  /// Get the model directory path.
  static String? get modelDir => _modelDir;

  /// Load the transcription model from a path.
  Future<void> loadModel(String modelPath) async {
    try {
      _streamingTranscriber ??= await StreamingTranscriber.newInstance();
      await _streamingTranscriber!.loadModel(modelPath: modelPath);
      _modelLoaded = true;
      _log('Model loaded successfully from: $modelPath');
    } on LexiconFlutterError catch (e) {
      _logError('Failed to load model: $e');
      rethrow;
    }
  }

  /// Load the default bundled model from assets.
  ///
  /// Copies the model from assets to the filesystem on first run.
  Future<void> loadDefaultModel() async {
    if (_modelLoaded) return;

    try {
      _log('Loading default model...');
      final modelPath = await _ensureModelCopied();
      await loadModel(modelPath);
    } on LexiconFlutterError catch (e) {
      // Handle specific Lexicon errors
      if (e is LexiconFlutterError_ModelLoadFailed) {
        // Model might be corrupted - try to re-copy from assets
        _logError('Model load failed, attempting recovery: $e');
        final modelPath = '$_modelDir/$kDefaultModelName';
        final modelFile = File(modelPath);
        if (await modelFile.exists()) {
          await modelFile.delete();
        }
        // Re-copy and retry once
        final newPath = await _ensureModelCopied();
        await loadModel(newPath);
      } else {
        rethrow;
      }
    }
  }

  /// Ensure the model file is copied from assets to the filesystem.
  ///
  /// Returns the path to the model file.
  Future<String> _ensureModelCopied() async {
    final modelPath = '$_modelDir/$kDefaultModelName';
    final modelFile = File(modelPath);

    // Create models directory if needed
    final modelDir = Directory(_modelDir!);
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }

    // Copy from assets if not already present
    if (!await modelFile.exists()) {
      final data = await rootBundle.load(kModelAssetPath);
      await modelFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }

    return modelPath;
  }

  /// Check if model is loaded and ready.
  bool get isModelLoaded => _modelLoaded && (_streamingTranscriber?.isReady() ?? false);

  @override
  Future<SessionId> createSession(SessionConfig config) async {
    final id = SessionId(_uuid.v4());
    final now = DateTime.now();
    _sessions[id.value] = Session(
      id: id,
      title: config.title ?? 'Untitled',
      createdAt: now,
      updatedAt: now,
      viewType: config.viewType,
      segments: [],
    );
    return id;
  }

  @override
  Future<Session?> getSession(SessionId id) async {
    return _sessions[id.value];
  }

  @override
  Future<List<SessionSummary>> listSessions() async {
    return _sessions.values
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
    _sessions.remove(id.value);
  }

  @override
  Future<void> renameSession(SessionId id, String newTitle) async {
    final session = _sessions[id.value];
    if (session != null) {
      _sessions[id.value] = Session(
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

  @override
  Future<TranscriptionHandle> startTranscription(
    SessionId sessionId,
    TranscriptionConfig config,
  ) async {
    // Auto-load model if not already loaded
    if (!isModelLoaded) {
      await loadDefaultModel();
    }

    final handle = TranscriptionHandle(_uuid.v4());
    _activeTranscriptions[handle.value] = _ActiveTranscription(
      sessionId: sessionId,
      diarization: config.diarization,
      timestampMs: 0,
    );
    return handle;
  }

  @override
  Future<List<Segment>> processAudio(
    TranscriptionHandle handle,
    List<double> samples,
  ) async {
    final active = _activeTranscriptions[handle.value];
    if (active == null || _streamingTranscriber == null) {
      // Silently return - this happens during startup before session is ready
      return [];
    }

    // Buffer incoming samples
    active.audioBuffer.addAll(samples);

    // Calculate minimum samples from chunk size (at 16kHz)
    final minSamples = (_chunkSizeMs * 16000) ~/ 1000;

    // Only process when we have enough audio
    if (active.audioBuffer.length < minSamples) {
      return [];
    }

    // Prevent concurrent transcription calls - if already processing, just buffer
    if (active.isProcessing) {
      return [];
    }

    active.isProcessing = true;

    // Take buffered samples for processing
    final samplesToProcess = List<double>.from(active.audioBuffer);
    active.audioBuffer.clear();

    // Lightweight VAD: skip silence to avoid Whisper hallucinations
    final rms = _calculateRms(samplesToProcess);
    final isSilent = rms < _silenceThreshold;

    if (isSilent) {
      // Still advance timestamp to maintain timing
      final durationMs = (samplesToProcess.length * 1000) ~/ 16000;
      active.timestampMs += durationMs;
      active.isProcessing = false;
      active.wasInSilence = true;
      return [];
    }

    // Detect silence-to-speech transition for latency tracking
    if (active.wasInSilence) {
      active.speechOnsetTime = DateTime.now();
      active.awaitingFirstTranscription = true;
      _log('Speech detected after silence (RMS: ${rms.toStringAsFixed(4)})');
    }
    active.wasInSilence = false;

    // Convert Float64 samples to Float32 bytes (f32le PCM)
    final audioBytes = _samplesToF32Bytes(samplesToProcess);

    // Create audio chunk
    final chunk = AudioChunk(
      data: audioBytes,
      timestampMs: active.timestampMs,
      isFinal: false,
    );

    // Process through native library
    const config = rust.TranscriptionConfig(
      language: null, // Auto-detect
      translate: false,
      numThreads: 4,
      initialPrompt: null,
      temperature: 0.0,
    );

    try {
      final rustSegments = await _streamingTranscriber!.processChunk(
        chunk: chunk,
        config: config,
      );

      // Advance timestamp (samples at 16kHz)
      final durationMs = (samplesToProcess.length * 1000) ~/ 16000;
      active.timestampMs += durationMs;

      // Convert to our Segment type
      final segments = rustSegments.map((s) {
        return Segment(
          id: _uuid.v4(),
          speakerId: s.speakerId,
          text: s.text.trim(),
          startMs: s.startMs.toInt(),
          endMs: s.endMs.toInt(),
          confidence: s.confidence,
        );
      }).where((s) => s.text.isNotEmpty).toList();

      if (segments.isNotEmpty) {
        // Log latency for first transcription after speech onset
        if (active.awaitingFirstTranscription && active.speechOnsetTime != null) {
          final latencyMs = DateTime.now().difference(active.speechOnsetTime!).inMilliseconds;
          _log('LATENCY: ${latencyMs}ms from speech onset to first transcription');
          active.awaitingFirstTranscription = false;
        }
        _log('Transcribed: "${segments.map((s) => s.text).join(" ")}"');
      }

      return segments;
    } on LexiconFlutterError catch (e) {
      // Handle specific Lexicon errors
      _logError('Transcription error: $e');
      return [];
    } catch (e) {
      // Log unexpected errors but don't crash - return empty segments
      _logError('Unexpected transcription error: $e');
      return [];
    } finally {
      active.isProcessing = false;
    }
  }

  @override
  Future<void> stopTranscription(TranscriptionHandle handle) async {
    final active = _activeTranscriptions.remove(handle.value);
    if (active != null) {
      // Process any remaining buffered audio (minimum 100ms = 1600 samples)
      if (active.audioBuffer.length >= 1600 && _streamingTranscriber != null) {
        final audioBytes = _samplesToF32Bytes(active.audioBuffer);
        final chunk = AudioChunk(
          data: audioBytes,
          timestampMs: active.timestampMs,
          isFinal: true,
        );
        const config = rust.TranscriptionConfig(
          language: null,
          translate: false,
          numThreads: 4,
          initialPrompt: null,
          temperature: 0.0,
        );
        try {
          await _streamingTranscriber!.processChunk(chunk: chunk, config: config);
          _log('Processed final ${active.audioBuffer.length} samples');
        } catch (e) {
          _logError('Error processing final audio: $e');
        }
      }
      _streamingTranscriber?.stop();
    }
  }

  @override
  Future<void> cancelTranscription(TranscriptionHandle handle) async {
    _activeTranscriptions.remove(handle.value);
    _streamingTranscriber?.stop();
  }

  @override
  Future<AudioStream> synthesizeSpeech(String text, {String? voiceId}) async {
    // TTS not yet implemented
    return AudioStream(_uuid.v4());
  }

  @override
  Future<void> cancelSynthesis(AudioStream stream) async {
    // TTS not yet implemented
  }

  @override
  Future<SessionId> importAudioFile(
    String path,
    TranscriptionConfig config,
    void Function(double progress) onProgress,
  ) async {
    // File import not yet implemented
    throw UnimplementedError('File import not yet implemented');
  }

  @override
  Future<void> cancelImport(SessionId sessionId) async {
    // File import not yet implemented
  }

  @override
  Future<List<SearchResult>> searchTranscriptions(String query) async {
    final results = <SearchResult>[];
    for (final session in _sessions.values) {
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

  /// Convert Float64 samples (List<double>) to Float32 PCM bytes (Uint8List).
  Uint8List _samplesToF32Bytes(List<double> samples) {
    final floats = Float32List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      floats[i] = samples[i].toDouble();
    }
    return floats.buffer.asUint8List();
  }

  /// Calculate RMS (root mean square) energy of audio samples.
  /// This is a lightweight voice activity detection method.
  /// Returns a value between 0.0 (silence) and 1.0 (max amplitude).
  double _calculateRms(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    var sumSquares = 0.0;
    for (final sample in samples) {
      sumSquares += sample * sample;
    }
    return sqrt(sumSquares / samples.length);
  }

  /// Log info message.
  void _log(String message) {
    debugPrint('[LexiconFlutterService] $message');
  }

  /// Log error message.
  void _logError(String message) {
    debugPrint('[LexiconFlutterService ERROR] $message');
  }
}

/// Internal state for active transcription sessions.
class _ActiveTranscription {
  final SessionId sessionId;
  final bool diarization;
  int timestampMs;

  /// Audio buffer to accumulate samples before processing.
  /// Whisper needs minimum 100ms (1600 samples at 16kHz).
  final List<double> audioBuffer = [];

  /// Minimum samples before processing (100ms at 16kHz).
  static const int minSamplesForProcessing = 1600;

  /// RMS threshold for voice activity detection.
  /// Audio below this level is considered silence and skipped.
  /// Normalized samples range from -1.0 to 1.0, so 0.01 is very quiet.
  static const double silenceThreshold = 0.01;

  /// Flag to prevent concurrent transcription calls.
  bool isProcessing = false;

  /// Tracks whether we were in silence on the previous chunk.
  bool wasInSilence = true;

  /// Timestamp (wall clock) when speech was first detected after silence.
  DateTime? speechOnsetTime;

  /// Whether we're waiting for the first transcription after speech onset.
  bool awaitingFirstTranscription = false;

  _ActiveTranscription({
    required this.sessionId,
    required this.diarization,
    this.timestampMs = 0,
  });
}
