import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

import '../core/constants/app_constants.dart';

/// Service for capturing audio from the device microphone.
///
/// Uses the `record` package for cross-platform audio capture.
abstract class AudioCaptureService {
  /// Stream of audio samples as Float32 data (normalized -1.0 to 1.0).
  Stream<List<double>> get audioStream;

  /// Stream of audio level (0.0 to 1.0) for visualization.
  Stream<double> get audioLevelStream;

  /// Whether the service is currently recording.
  bool get isRecording;

  /// Start audio capture.
  Future<void> start();

  /// Pause audio capture.
  Future<void> pause();

  /// Resume audio capture.
  Future<void> resume();

  /// Stop audio capture.
  Future<void> stop();

  /// Dispose of resources.
  Future<void> dispose();

  /// Request microphone permission.
  Future<bool> requestPermission();

  /// Check if microphone permission is granted.
  Future<bool> hasPermission();
}

/// Implementation of AudioCaptureService using the record package.
class AudioCaptureServiceImpl implements AudioCaptureService {
  final _audioController = StreamController<List<double>>.broadcast();
  final _audioLevelController = StreamController<double>.broadcast();
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordSubscription;
  bool _isRecording = false;
  bool _isPaused = false;

  @override
  Stream<List<double>> get audioStream => _audioController.stream;

  @override
  Stream<double> get audioLevelStream => _audioLevelController.stream;

  @override
  bool get isRecording => _isRecording;

  @override
  Future<void> start() async {
    if (_isRecording) return;

    // Configure for 16kHz mono PCM16
    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: AppConstants.audioSampleRate,
      numChannels: AppConstants.audioChannels,
      autoGain: true,
      echoCancel: false,
      noiseSuppress: false,
    );

    // Start streaming audio
    final stream = await _recorder.startStream(config);

    _isRecording = true;
    _isPaused = false;

    // Process incoming audio data
    _recordSubscription = stream.listen(
      (data) {
        if (!_isRecording || _isPaused) return;

        // Convert PCM16 bytes to normalized Float32 samples
        final samples = _pcm16ToFloat32(data);
        _audioController.add(samples);

        // Calculate RMS audio level for visualization
        final level = _calculateRmsLevel(samples);
        _audioLevelController.add(level);
      },
      onError: (error) {
        _audioLevelController.add(0.0);
      },
    );
  }

  @override
  Future<void> pause() async {
    if (!_isRecording) return;
    _isPaused = true;
    await _recorder.pause();
    _audioLevelController.add(0.0);
  }

  @override
  Future<void> resume() async {
    if (!_isRecording) return;
    _isPaused = false;
    await _recorder.resume();
  }

  @override
  Future<void> stop() async {
    if (!_isRecording) return;

    _isRecording = false;
    _isPaused = false;

    await _recordSubscription?.cancel();
    _recordSubscription = null;

    await _recorder.stop();
    _audioLevelController.add(0.0);
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _audioController.close();
    await _audioLevelController.close();
    _recorder.dispose();
  }

  @override
  Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }

  @override
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Convert PCM16 little-endian bytes to normalized Float32 samples.
  List<double> _pcm16ToFloat32(Uint8List bytes) {
    final sampleCount = bytes.length ~/ 2;
    final samples = List<double>.filled(sampleCount, 0.0);

    for (var i = 0; i < sampleCount; i++) {
      // Read 16-bit signed integer (little-endian)
      final low = bytes[i * 2];
      final high = bytes[i * 2 + 1];
      var sample = (high << 8) | low;

      // Convert to signed
      if (sample >= 32768) {
        sample -= 65536;
      }

      // Normalize to -1.0 to 1.0
      samples[i] = sample / 32768.0;
    }

    return samples;
  }

  /// Calculate RMS (root mean square) level from samples.
  /// Returns value between 0.0 and 1.0.
  double _calculateRmsLevel(List<double> samples) {
    if (samples.isEmpty) return 0.0;

    var sumSquares = 0.0;
    for (final sample in samples) {
      sumSquares += sample * sample;
    }

    final rms = math.sqrt(sumSquares / samples.length);

    // Scale RMS to a more usable range for visualization
    // RMS of full-scale sine wave is ~0.707, speech typically 0.05-0.3
    // Map to 0-1 range with some headroom
    return (rms * 3.0).clamp(0.0, 1.0);
  }
}
