import 'dart:async';

import '../core/constants/app_constants.dart';

/// Service for capturing audio from the device microphone.
///
/// Uses the `record` package for cross-platform audio capture.
abstract class AudioCaptureService {
  /// Stream of audio samples as Float32 data.
  Stream<List<double>> get audioStream;

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

/// Implementation of AudioCaptureService.
class AudioCaptureServiceImpl implements AudioCaptureService {
  final _audioController = StreamController<List<double>>.broadcast();
  bool _isRecording = false;
  Timer? _mockTimer;

  @override
  Stream<List<double>> get audioStream => _audioController.stream;

  @override
  bool get isRecording => _isRecording;

  @override
  Future<void> start() async {
    if (_isRecording) return;

    _isRecording = true;

    // TODO: Replace with actual record package implementation
    // For now, simulate audio capture
    _mockTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.audioBufferMs),
      (_) {
        if (_isRecording) {
          // Generate mock audio samples
          final samples = List.generate(
            (AppConstants.audioSampleRate * AppConstants.audioBufferMs) ~/ 1000,
            (i) => 0.0,
          );
          _audioController.add(samples);
        }
      },
    );
  }

  @override
  Future<void> pause() async {
    _isRecording = false;
  }

  @override
  Future<void> resume() async {
    _isRecording = true;
  }

  @override
  Future<void> stop() async {
    _isRecording = false;
    _mockTimer?.cancel();
    _mockTimer = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _audioController.close();
  }

  @override
  Future<bool> requestPermission() async {
    // TODO: Implement with permission_handler package
    return true;
  }

  @override
  Future<bool> hasPermission() async {
    // TODO: Implement with permission_handler package
    return true;
  }
}
