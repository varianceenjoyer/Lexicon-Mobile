import 'dart:async';
import 'dart:io';

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

  final _uuid = const Uuid();

  // Streaming transcriber for real-time transcription
  StreamingTranscriber? _streamingTranscriber;
  bool _modelLoaded = false;

  // Session storage (in-memory for now, will use SQLite later)
  final Map<String, Session> _sessions = {};

  // Active transcription state
  final Map<String, _ActiveTranscription> _activeTranscriptions = {};

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
      _log('processAudio: no active transcription or transcriber null');
      return [];
    }

    // Debug: log incoming samples
    _log('processAudio: received ${samples.length} samples');

    // Buffer incoming samples
    active.audioBuffer.addAll(samples);

    // Only process when we have enough audio (0.5 seconds at 16kHz)
    if (active.audioBuffer.length < _ActiveTranscription.minSamplesForProcessing) {
      return [];
    }

    // Prevent concurrent transcription calls - if already processing, just buffer
    if (active.isProcessing) {
      _log('Already processing, buffering ${active.audioBuffer.length} samples');
      return [];
    }

    active.isProcessing = true;
    _log('Processing ${active.audioBuffer.length} buffered samples');

    // Take buffered samples for processing
    final samplesToProcess = List<double>.from(active.audioBuffer);
    active.audioBuffer.clear();

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
      _log('Calling processChunk with ${audioBytes.length} bytes...');
      final rustSegments = await _streamingTranscriber!.processChunk(
        chunk: chunk,
        config: config,
      );
      _log('processChunk returned ${rustSegments.length} segments');

      // Advance timestamp (samples at 16kHz)
      final durationMs = (samplesToProcess.length * 1000) ~/ 16000;
      active.timestampMs += durationMs;

      // Convert to our Segment type
      final segments = rustSegments.map((s) {
        _log('Segment: "${s.text}" (${s.startMs}-${s.endMs}ms)');
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
        _log('Transcribed ${segments.length} segments from ${durationMs}ms audio');
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
  /// Whisper needs minimum 100ms, but 3 seconds gives better quality.
  final List<double> audioBuffer = [];

  /// Minimum samples before processing (0.5 seconds at 16kHz).
  static const int minSamplesForProcessing = 8000;

  /// Flag to prevent concurrent transcription calls.
  bool isProcessing = false;

  _ActiveTranscription({
    required this.sessionId,
    required this.diarization,
    this.timestampMs = 0,
  });
}
