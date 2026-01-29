import 'dart:async';

/// Service for TTS audio playback.
///
/// Uses the `just_audio` package for cross-platform audio playback.
abstract class TTSPlaybackService {
  /// Stream of playback position updates.
  Stream<Duration> get positionStream;

  /// Stream of buffered position updates.
  Stream<Duration> get bufferedPositionStream;

  /// Stream of playback state updates.
  Stream<PlaybackState> get playbackStateStream;

  /// Current playback position.
  Duration get position;

  /// Total audio duration.
  Duration get duration;

  /// Current playback state.
  PlaybackState get playbackState;

  /// Load audio from bytes.
  Future<void> loadFromBytes(List<int> audioBytes);

  /// Load audio from a file path.
  Future<void> loadFromFile(String path);

  /// Start playback.
  Future<void> play();

  /// Pause playback.
  Future<void> pause();

  /// Stop playback and reset position.
  Future<void> stop();

  /// Seek to a position.
  Future<void> seek(Duration position);

  /// Set playback speed.
  Future<void> setSpeed(double speed);

  /// Dispose of resources.
  Future<void> dispose();
}

/// Playback state enum.
enum PlaybackState {
  idle,
  loading,
  ready,
  playing,
  paused,
  completed,
  error,
}

/// Implementation of TTSPlaybackService.
class TTSPlaybackServiceImpl implements TTSPlaybackService {
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferedPositionController = StreamController<Duration>.broadcast();
  final _playbackStateController = StreamController<PlaybackState>.broadcast();

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  PlaybackState _playbackState = PlaybackState.idle;
  Timer? _mockPlaybackTimer;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get bufferedPositionStream =>
      _bufferedPositionController.stream;

  @override
  Stream<PlaybackState> get playbackStateStream =>
      _playbackStateController.stream;

  @override
  Duration get position => _position;

  @override
  Duration get duration => _duration;

  @override
  PlaybackState get playbackState => _playbackState;

  @override
  Future<void> loadFromBytes(List<int> audioBytes) async {
    _setPlaybackState(PlaybackState.loading);

    // TODO: Replace with actual just_audio implementation
    await Future.delayed(const Duration(milliseconds: 200));

    // Simulate audio duration based on byte size
    _duration = Duration(milliseconds: audioBytes.length ~/ 32);
    _position = Duration.zero;
    _setPlaybackState(PlaybackState.ready);
    _bufferedPositionController.add(_duration);
  }

  @override
  Future<void> loadFromFile(String path) async {
    _setPlaybackState(PlaybackState.loading);

    // TODO: Replace with actual just_audio implementation
    await Future.delayed(const Duration(milliseconds: 200));

    _duration = const Duration(seconds: 30); // Mock duration
    _position = Duration.zero;
    _setPlaybackState(PlaybackState.ready);
    _bufferedPositionController.add(_duration);
  }

  @override
  Future<void> play() async {
    if (_playbackState == PlaybackState.completed) {
      _position = Duration.zero;
    }

    _setPlaybackState(PlaybackState.playing);

    // Mock playback progress
    _mockPlaybackTimer?.cancel();
    _mockPlaybackTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (_playbackState == PlaybackState.playing) {
          _position += const Duration(milliseconds: 100);
          _positionController.add(_position);

          if (_position >= _duration) {
            _setPlaybackState(PlaybackState.completed);
            _mockPlaybackTimer?.cancel();
          }
        }
      },
    );
  }

  @override
  Future<void> pause() async {
    _mockPlaybackTimer?.cancel();
    _setPlaybackState(PlaybackState.paused);
  }

  @override
  Future<void> stop() async {
    _mockPlaybackTimer?.cancel();
    _position = Duration.zero;
    _positionController.add(_position);
    _setPlaybackState(PlaybackState.ready);
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    _positionController.add(_position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    // TODO: Implement with just_audio
  }

  @override
  Future<void> dispose() async {
    _mockPlaybackTimer?.cancel();
    await _positionController.close();
    await _bufferedPositionController.close();
    await _playbackStateController.close();
  }

  void _setPlaybackState(PlaybackState state) {
    _playbackState = state;
    _playbackStateController.add(state);
  }
}
