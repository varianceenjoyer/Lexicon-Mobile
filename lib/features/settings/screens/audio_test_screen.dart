import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/constants/app_constants.dart';

/// Screen for testing microphone recording and playback.
///
/// Allows users to record a short audio clip and play it back to verify
/// that the microphone is capturing audio correctly.
class AudioTestScreen extends StatefulWidget {
  const AudioTestScreen({super.key});

  @override
  State<AudioTestScreen> createState() => _AudioTestScreenState();
}

class _AudioTestScreenState extends State<AudioTestScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  _TestState _state = _TestState.idle;
  String? _recordingPath;
  double _audioLevel = 0.0;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  String? _errorMessage;

  Timer? _durationTimer;
  StreamSubscription<Uint8List>? _levelSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _positionSubscription = _player.positionStream.listen((position) {
      if (mounted) {
        setState(() => _playbackPosition = position);
      }
    });

    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (mounted) {
        if (state.processingState == ProcessingState.completed) {
          setState(() => _state = _TestState.recorded);
        }
      }
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _levelSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // Check permission
      if (!await _recorder.hasPermission()) {
        setState(() {
          _errorMessage = 'Microphone permission denied';
          _state = _TestState.error;
        });
        return;
      }

      // Get temp directory for recording
      final dir = await getTemporaryDirectory();
      _recordingPath = '${dir.path}/audio_test_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Configure for WAV recording at 16kHz mono
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: AppConstants.audioSampleRate,
        numChannels: AppConstants.audioChannels,
        autoGain: true,
        echoCancel: false,
        noiseSuppress: false,
      );

      // Start recording to file
      await _recorder.start(config, path: _recordingPath!);

      // Also start a stream just to get audio levels
      // Note: We need to use a separate approach for levels since we're recording to file
      _startLevelMonitoring();

      setState(() {
        _state = _TestState.recording;
        _recordingDuration = Duration.zero;
        _errorMessage = null;
      });

      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted && _state == _TestState.recording) {
          setState(() {
            _recordingDuration += const Duration(milliseconds: 100);
          });

          // Auto-stop after 10 seconds
          if (_recordingDuration.inSeconds >= 10) {
            _stopRecording();
          }
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start recording: $e';
        _state = _TestState.error;
      });
    }
  }

  void _startLevelMonitoring() {
    // Poll amplitude periodically
    Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_state != _TestState.recording) {
        timer.cancel();
        return;
      }

      try {
        final amplitude = await _recorder.getAmplitude();
        if (mounted) {
          // Convert dB to linear scale (0-1)
          // Amplitude.current is in dB, typically -160 to 0
          final db = amplitude.current;
          final linear = db > -60 ? math.pow(10, db / 20).clamp(0.0, 1.0) : 0.0;
          setState(() => _audioLevel = linear.toDouble());
        }
      } catch (_) {
        // Ignore amplitude errors
      }
    });
  }

  Future<void> _stopRecording() async {
    _durationTimer?.cancel();

    try {
      final path = await _recorder.stop();

      if (path != null && await File(path).exists()) {
        final file = File(path);
        final size = await file.length();

        setState(() {
          _recordingPath = path;
          _state = _TestState.recorded;
          _audioLevel = 0.0;
        });

        debugPrint('Recording saved: $path ($size bytes)');
      } else {
        setState(() {
          _errorMessage = 'Recording file not created';
          _state = _TestState.error;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to stop recording: $e';
        _state = _TestState.error;
      });
    }
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;

    try {
      await _player.setFilePath(_recordingPath!);
      _playbackDuration = _player.duration ?? Duration.zero;

      setState(() => _state = _TestState.playing);

      await _player.play();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to play recording: $e';
        _state = _TestState.error;
      });
    }
  }

  Future<void> _stopPlayback() async {
    await _player.stop();
    setState(() {
      _state = _TestState.recorded;
      _playbackPosition = Duration.zero;
    });
  }

  void _reset() {
    _player.stop();
    if (_recordingPath != null) {
      File(_recordingPath!).delete().catchError((_) => File(_recordingPath!));
    }

    setState(() {
      _state = _TestState.idle;
      _recordingPath = null;
      _audioLevel = 0.0;
      _recordingDuration = Duration.zero;
      _playbackPosition = Duration.zero;
      _playbackDuration = Duration.zero;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Test'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Microphone Test',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Record a short audio clip and play it back to verify '
                        'your microphone is capturing audio clearly.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Audio Level Meter
              if (_state == _TestState.recording) ...[
                Text(
                  'Audio Level',
                  style: theme.textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                _buildAudioLevelMeter(colorScheme),
                const SizedBox(height: 8),
                Text(
                  'Recording: ${_formatDuration(_recordingDuration)} / 10s',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],

              // Playback Progress
              if (_state == _TestState.playing ||
                  (_state == _TestState.recorded && _playbackDuration > Duration.zero)) ...[
                Text(
                  'Playback',
                  style: theme.textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _playbackDuration.inMilliseconds > 0
                      ? _playbackPosition.inMilliseconds / _playbackDuration.inMilliseconds
                      : 0.0,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDuration(_playbackPosition)} / ${_formatDuration(_playbackDuration)}',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],

              // Error Message
              if (_errorMessage != null) ...[
                Card(
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Spacer(),

              // Main Action Button
              _buildMainButton(colorScheme),

              const SizedBox(height: 16),

              // Secondary Actions
              if (_state == _TestState.recorded) ...[
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Record Again'),
                ),
              ],

              if (_state == _TestState.error) ...[
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioLevelMeter(ColorScheme colorScheme) {
    Color levelColor;
    if (_audioLevel > 0.8) {
      levelColor = Colors.red;
    } else if (_audioLevel > 0.5) {
      levelColor = Colors.orange;
    } else {
      levelColor = colorScheme.primary;
    }

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 50),
              width: double.infinity,
              height: 24,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _audioLevel,
                child: Container(
                  decoration: BoxDecoration(
                    color: levelColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton(ColorScheme colorScheme) {
    switch (_state) {
      case _TestState.idle:
        return FilledButton.icon(
          onPressed: _startRecording,
          icon: const Icon(Icons.mic),
          label: const Text('Start Recording'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        );

      case _TestState.recording:
        return FilledButton.icon(
          onPressed: _stopRecording,
          icon: const Icon(Icons.stop),
          label: const Text('Stop Recording'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        );

      case _TestState.recorded:
        return FilledButton.icon(
          onPressed: _playRecording,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Play Recording'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        );

      case _TestState.playing:
        return FilledButton.icon(
          onPressed: _stopPlayback,
          icon: const Icon(Icons.stop),
          label: const Text('Stop Playback'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        );

      case _TestState.error:
        return FilledButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

enum _TestState {
  idle,
  recording,
  recorded,
  playing,
  error,
}
