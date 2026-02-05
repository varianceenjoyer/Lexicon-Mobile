import 'dart:async';
import 'dart:io';
import 'dart:math' show sqrt;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/spsc_double_buffer.dart';
import '../src/rust/api.dart' as api;
import '../src/rust/error.dart';
import '../src/rust/frb_generated.dart';
import '../src/rust/types.dart' as rust;
import 'lexicon_core_service.dart';

/// Default sherpa model directory name.
const String kDefaultSherpaModelDir = 'sherpa-onnx-zipformer-en-libriheavy-20230926-large';

/// Asset path for the bundled sherpa model directory.
const String kSherpaModelAssetPath = 'assets/models/sherpa/$kDefaultSherpaModelDir';

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

  // Sherpa transcriber for real-time transcription (faster than Whisper)
  api.SherpaTranscriber? _sherpaTranscriber;
  bool _modelLoaded = false;

  // Session storage (in-memory for now, will use SQLite later)
  final Map<String, Session> _sessions = {};

  // Active transcription state
  final Map<String, _ActiveTranscription> _activeTranscriptions = {};

  // Configurable settings (updated via updateSettings)
  double _silenceThreshold = 0.0; // Disabled by default - sherpa handles silence well
  int _chunkSizeMs = 3000; // Default 3 seconds for offline model accuracy

  @override
  void updateSettings({double? silenceThreshold, int? chunkSizeMs}) {
    if (silenceThreshold != null) {
      _silenceThreshold = silenceThreshold.clamp(0.0, 0.1);
      _log('Updated silence threshold: $_silenceThreshold');
    }
    if (chunkSizeMs != null) {
      _chunkSizeMs = chunkSizeMs.clamp(1000, 5000);
      _log('Updated chunk size: ${_chunkSizeMs}ms');
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
    api.initLexicon(dataDir: _dataDir!);

    // Log library version and platform info
    final version = api.getVersion();
    final platformInfo = api.getPlatformInfo();
    debugPrint('[LexiconFlutterService] Lexicon version: $version');
    debugPrint('[LexiconFlutterService] Platform: ${platformInfo.platform}');
    debugPrint('[LexiconFlutterService] Model tier: ${platformInfo.modelTier}');
    debugPrint('[LexiconFlutterService] Available memory: ${platformInfo.availableMemoryMb} MB');

    _initialized = true;
    debugPrint('[LexiconFlutterService] Initialization complete');
  }

  /// Check if the library is initialized.
  static bool get isInitialized => _initialized;

  /// Check if the model is preloaded and ready.
  static bool get isModelPreloaded => _instance?._modelLoaded ?? false;

  /// Preload the default model at app startup.
  /// Call this after initialize() to eagerly load the model.
  /// Returns the load time in milliseconds.
  static Future<int> preloadModel() async {
    if (!_initialized) {
      debugPrint('[LexiconFlutterService] Cannot preload - not initialized');
      return -1;
    }

    final service = LexiconFlutterService();

    // Ensure model files are copied from assets to filesystem
    final modelDir = await service._ensureSherpaModelReady();

    // Create the SherpaTranscriber instance and load the model directly
    service._sherpaTranscriber ??= await api.SherpaTranscriber.newInstance();
    final loadTimeMs = await service._sherpaTranscriber!.loadModel(modelDir: modelDir);
    final loadTime = loadTimeMs.toInt();
    debugPrint('[LexiconFlutterService] Model loaded in ${loadTime}ms');

    service._modelLoaded = true;

    return loadTime;
  }

  /// Handle low memory warning from OS.
  /// Call this from WidgetsBindingObserver.didHaveMemoryPressure().
  static void handleMemoryPressure() {
    // Model is held in transcriber instance - mark as not loaded for lazy reload
    debugPrint('[LexiconFlutterService] Memory pressure - model may need reload');
    _instance?._modelLoaded = false;
  }

  /// Get the data directory path.
  static String? get dataDir => _dataDir;

  /// Get the model directory path.
  static String? get modelDir => _modelDir;

  /// Load the transcription model from a directory path (sherpa-onnx model).
  /// Returns load time in ms.
  Future<int> loadModel(String modelDir) async {
    try {
      _sherpaTranscriber ??= await api.SherpaTranscriber.newInstance();
      final loadTimeMs = await _sherpaTranscriber!.loadModel(modelDir: modelDir);
      final loadTime = loadTimeMs.toInt();
      _modelLoaded = true;
      _log('Sherpa model loaded in ${loadTime}ms from: $modelDir');
      return loadTime;
    } on LexiconFlutterError catch (e) {
      _logError('Failed to load model: $e');
      rethrow;
    }
  }

  /// Load the default bundled sherpa model from assets.
  ///
  /// The sherpa model is a directory containing encoder, decoder, joiner, and tokens files.
  /// These are bundled in assets and loaded directly from the asset path.
  Future<void> loadDefaultModel() async {
    if (_modelLoaded) return;

    try {
      _log('Loading default sherpa model...');
      // Sherpa model is a directory - we pass the asset path directly
      // The native code will handle loading from the app's asset bundle
      final modelDir = await _ensureSherpaModelReady();
      await loadModel(modelDir);
    } on LexiconFlutterError catch (e) {
      // Handle specific Lexicon errors
      if (e is LexiconFlutterError_ModelLoadFailed) {
        _logError('Sherpa model load failed: $e');
        // Re-copy model directory and retry
        final modelDir = await _ensureSherpaModelReady(forceRecopy: true);
        await loadModel(modelDir);
      } else {
        rethrow;
      }
    }
  }

  /// Ensure the sherpa model directory is ready in the filesystem.
  ///
  /// Copies all model files from assets to the filesystem if not already present.
  /// Returns the path to the model directory.
  Future<String> _ensureSherpaModelReady({bool forceRecopy = false}) async {
    final sherpaModelDir = '$_modelDir/sherpa/$kDefaultSherpaModelDir';
    final modelDirObj = Directory(sherpaModelDir);

    // Check if model directory exists and has required files
    final requiredFiles = ['tokens.txt'];
    bool modelComplete = await modelDirObj.exists();

    if (modelComplete && !forceRecopy) {
      // Verify at least tokens.txt exists
      for (final file in requiredFiles) {
        if (!await File('$sherpaModelDir/$file').exists()) {
          modelComplete = false;
          break;
        }
      }
    }

    if (modelComplete && !forceRecopy) {
      _log('Sherpa model already present at: $sherpaModelDir');
      return sherpaModelDir;
    }

    // Create model directory
    if (forceRecopy && await modelDirObj.exists()) {
      await modelDirObj.delete(recursive: true);
    }
    await modelDirObj.create(recursive: true);

    // List of model files to copy from assets
    // Using .ort (ONNX Runtime optimized) format for ~10x faster loading
    final modelFiles = [
      'encoder-epoch-16-avg-3.int8.ort',
      'decoder-epoch-16-avg-3.int8.ort',
      'joiner-epoch-16-avg-3.int8.ort',
      'tokens.txt',
    ];

    _log('Copying sherpa model files from assets...');
    for (final fileName in modelFiles) {
      try {
        final assetPath = '$kSherpaModelAssetPath/$fileName';
        final data = await rootBundle.load(assetPath);
        final destPath = '$sherpaModelDir/$fileName';
        await File(destPath).writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        _log('  Copied: $fileName');
      } catch (e) {
        _logError('  Failed to copy $fileName: $e');
        // Continue - some files may be optional (like non-int8 versions)
      }
    }

    _log('Sherpa model ready at: $sherpaModelDir');
    return sherpaModelDir;
  }

  /// Check if model is loaded and ready.
  bool get isModelLoaded => _modelLoaded && (_sherpaTranscriber?.isModelLoaded() ?? false);

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
    final pipelineStart = DateTime.now();

    final active = _activeTranscriptions[handle.value];
    if (active == null || _sherpaTranscriber == null) {
      // Silently return - this happens during startup before session is ready
      return [];
    }

    // Write samples to front buffer (producer side)
    final dropped = active.audioBuffer.write(samples);
    if (dropped > 0) {
      active.droppedSamples += dropped;
      _logError('WARNING: Dropped $dropped samples - buffer overflow (total: ${active.droppedSamples})');
    }

    // Check RMS of incoming samples for endpoint detection
    final incomingRms = _calculateRms(samples);
    final isIncomingSilent = incomingRms < 0.005; // Low threshold for endpoint detection

    // Track silence duration for endpoint detection
    if (isIncomingSilent) {
      active.consecutiveSilenceMs += (samples.length * 1000) ~/ 16000;
    } else {
      active.consecutiveSilenceMs = 0;
      active.hasSpeechInBuffer = true;
    }

    final buffered = active.audioBuffer.frontAvailable;
    final bufferedMs = (buffered * 1000) ~/ 16000;

    // Minimum audio to process (at least 500ms to have some context)
    const minProcessMs = 500;
    const minSamples = minProcessMs * 16; // 500ms at 16kHz

    // Maximum buffer before forced processing (10 seconds)
    const maxBufferMs = 10000;
    const maxSamples = maxBufferMs * 16;

    // Endpoint detection: process when we detect silence after speech
    // OR when buffer is getting too full
    final endpointDetected = active.hasSpeechInBuffer &&
        active.consecutiveSilenceMs >= 300; // 300ms of silence = endpoint
    final bufferFull = buffered >= maxSamples;
    final hasEnoughAudio = buffered >= minSamples;

    // Decide whether to process
    final shouldProcess = hasEnoughAudio && (endpointDetected || bufferFull);

    if (!shouldProcess) {
      // Log buffering progress periodically
      if (bufferedMs % 1000 < 100) {
        _log('Buffering: ${bufferedMs}ms, silence: ${active.consecutiveSilenceMs}ms, hasSpeech: ${active.hasSpeechInBuffer}');
      }
      return [];
    }

    // Prevent concurrent transcription calls - if already processing, just buffer
    if (active.isProcessing) {
      _log('Already processing, buffering audio (${bufferedMs}ms in buffer)');
      return [];
    }

    _log('Endpoint detected: buffered=${bufferedMs}ms, silence=${active.consecutiveSilenceMs}ms, bufferFull=$bufferFull');

    active.isProcessing = true;
    active.hasSpeechInBuffer = false;
    active.consecutiveSilenceMs = 0;

    // Swap buffers: front becomes back (for processing), back becomes front (for new writes)
    active.audioBuffer.swap();

    // Read samples from back buffer (consumer side)
    final samplesToProcess = active.audioBuffer.readBack();

    // Track timing for VAD
    final vadStart = DateTime.now();

    // Calculate overall RMS of chunk
    final rms = _calculateRms(samplesToProcess);
    // Skip if chunk is almost entirely silent (likely just noise)
    final isSilent = rms < 0.003;

    final vadDuration = DateTime.now().difference(vadStart);
    active.totalVadTime += vadDuration;

    final chunkDurationMs = (samplesToProcess.length * 1000) ~/ 16000;
    _log('Processing ${chunkDurationMs}ms chunk, RMS: ${rms.toStringAsFixed(4)}, silent: $isSilent');

    if (isSilent) {
      // Still advance timestamp to maintain timing
      active.timestampMs += chunkDurationMs;
      active.isProcessing = false;
      active.wasInSilence = true;
      _log('Skipped silent chunk (${chunkDurationMs}ms)');
      return [];
    }

    // Detect silence-to-speech transition for latency tracking
    if (active.wasInSilence) {
      active.speechOnsetTime = DateTime.now();
      active.awaitingFirstTranscription = true;
      _log('[LATENCY T0] Speech detected after silence (RMS: ${rms.toStringAsFixed(4)})');
    }
    active.wasInSilence = false;

    // Track timing for sample conversion
    final conversionStart = DateTime.now();

    // Convert Float64 samples to Float32 bytes (f32le PCM)
    final audioBytes = _samplesToF32Bytes(samplesToProcess);

    final conversionDuration = DateTime.now().difference(conversionStart);
    active.totalConversionTime += conversionDuration;

    // Process through sherpa transcriber (batch mode - faster than streaming whisper)
    const config = rust.TranscriptionConfig(
      language: null, // Auto-detect
      translate: false,
      numThreads: 4,
      initialPrompt: null,
      temperature: 0.0,
    );

    // Track timing for FFI call
    final ffiStart = DateTime.now();

    try {
      // Sherpa transcribe expects List<int> (bytes), not AudioChunk
      final result = await _sherpaTranscriber!.transcribe(
        audioData: audioBytes,
        config: config,
      );
      final rustSegments = result.segments;

      final ffiDuration = DateTime.now().difference(ffiStart);
      active.totalFfiTime += ffiDuration;
      active.totalChunksProcessed++;
      active.totalSamplesProcessed += samplesToProcess.length;

      // Advance timestamp (samples at 16kHz)
      final durationMs = (samplesToProcess.length * 1000) ~/ 16000;
      active.timestampMs += durationMs;

      _log('FFI transcription took ${ffiDuration.inMilliseconds}ms for ${durationMs}ms audio, got ${rustSegments.length} segments');

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

      final pipelineDuration = DateTime.now().difference(pipelineStart);

      if (segments.isNotEmpty) {
        // Log latency for first transcription after speech onset
        if (active.awaitingFirstTranscription && active.speechOnsetTime != null) {
          final latencyMs = DateTime.now().difference(active.speechOnsetTime!).inMilliseconds;
          _log('[LATENCY] ${latencyMs}ms from speech onset to first transcription');
          _log('[LATENCY BREAKDOWN] VAD: ${vadDuration.inMicroseconds / 1000}ms, Conv: ${conversionDuration.inMicroseconds / 1000}ms, FFI: ${ffiDuration.inMilliseconds}ms, Pipeline: ${pipelineDuration.inMilliseconds}ms');
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
      // Clear back buffer after processing and mark as not processing
      active.audioBuffer.clearBack();
      active.isProcessing = false;
    }
  }

  @override
  Future<void> stopTranscription(TranscriptionHandle handle) async {
    final active = _activeTranscriptions.remove(handle.value);
    if (active != null) {
      // Log latency summary for the session
      active.logLatencySummary();

      // Process any remaining buffered audio from front buffer (minimum 100ms = 1600 samples)
      if (active.audioBuffer.frontAvailable >= 1600 && _sherpaTranscriber != null) {
        active.audioBuffer.swap();
        final remainingSamples = active.audioBuffer.readBack();
        final audioBytes = _samplesToF32Bytes(remainingSamples);
        const config = rust.TranscriptionConfig(
          language: null,
          translate: false,
          numThreads: 4,
          initialPrompt: null,
          temperature: 0.0,
        );
        try {
          await _sherpaTranscriber!.transcribe(audioData: audioBytes, config: config);
          _log('Processed final ${remainingSamples.length} samples');
        } catch (e) {
          _logError('Error processing final audio: $e');
        }
      }

      // Log if any samples were dropped
      if (active.droppedSamples > 0) {
        _logError('Session ended with ${active.droppedSamples} dropped samples');
      }
      // Note: SherpaTranscriber doesn't have a stop() method - it's batch-based
    }
  }

  @override
  Future<void> cancelTranscription(TranscriptionHandle handle) async {
    _activeTranscriptions.remove(handle.value);
    // Note: SherpaTranscriber doesn't have a stop() method - it's batch-based
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

  /// SPSC double buffer for lock-free audio accumulation.
  /// Uses two 30-second pre-allocated buffers (480000 samples each).
  /// Producer writes to front, consumer processes back after swap.
  /// No audio loss as long as processing time < 30 seconds.
  final SpscDoubleBuffer audioBuffer = SpscDoubleBuffer(480000);

  /// Tracks dropped samples if buffer overflows (shouldn't happen).
  int droppedSamples = 0;

  /// Flag to prevent concurrent transcription calls.
  bool isProcessing = false;

  /// Tracks whether we were in silence on the previous chunk.
  bool wasInSilence = true;

  /// Consecutive milliseconds of silence for endpoint detection.
  int consecutiveSilenceMs = 0;

  /// Whether we've detected speech in the current buffer.
  bool hasSpeechInBuffer = false;

  /// Timestamp (wall clock) when speech was first detected after silence.
  DateTime? speechOnsetTime;

  /// Whether we're waiting for the first transcription after speech onset.
  bool awaitingFirstTranscription = false;

  // Latency tracking metrics
  int totalChunksProcessed = 0;
  int totalSamplesProcessed = 0;
  Duration totalFfiTime = Duration.zero;
  Duration totalVadTime = Duration.zero;
  Duration totalConversionTime = Duration.zero;

  _ActiveTranscription({
    required this.sessionId,
    required this.diarization,
    this.timestampMs = 0,
  });

  /// Log latency summary statistics
  void logLatencySummary() {
    if (totalChunksProcessed == 0) return;
    final avgFfiMs = totalFfiTime.inMicroseconds / totalChunksProcessed / 1000;
    final avgVadMs = totalVadTime.inMicroseconds / totalChunksProcessed / 1000;
    final avgConvMs = totalConversionTime.inMicroseconds / totalChunksProcessed / 1000;
    debugPrint('[LATENCY SUMMARY] Chunks: $totalChunksProcessed, Samples: $totalSamplesProcessed');
    debugPrint('[LATENCY SUMMARY] Avg FFI: ${avgFfiMs.toStringAsFixed(2)}ms, Avg VAD: ${avgVadMs.toStringAsFixed(2)}ms, Avg Conv: ${avgConvMs.toStringAsFixed(2)}ms');
  }
}
