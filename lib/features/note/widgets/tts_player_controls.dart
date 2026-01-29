import 'package:flutter/material.dart';

import '../../../services/tts_playback_service.dart';

/// TTS playback controls with play/pause, seek slider, and time display.
class TTSPlayerControls extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final PlaybackState playbackState;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final ValueChanged<Duration> onSeek;

  const TTSPlayerControls({
    required this.position,
    required this.duration,
    required this.playbackState,
    required this.onPlay,
    required this.onPause,
    required this.onSeek,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlaying = playbackState == PlaybackState.playing;
    final isLoading = playbackState == PlaybackState.loading;
    final maxDuration = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Play/Pause button
          IconButton(
            onPressed: isLoading ? null : (isPlaying ? onPause : onPlay),
            icon: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
            iconSize: 48,
          ),

          // Seek slider
          Expanded(
            child: Slider(
              value: position.inMilliseconds.toDouble().clamp(0, maxDuration),
              min: 0,
              max: maxDuration,
              onChanged: (value) => onSeek(Duration(milliseconds: value.round())),
            ),
          ),

          // Time display
          Text(
            '${_formatDuration(position)} / ${_formatDuration(duration)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
