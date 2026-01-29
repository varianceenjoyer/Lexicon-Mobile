import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../providers/note_provider.dart';

/// Recording controls with mic button and stop button.
class RecordingControls extends StatelessWidget {
  final NoteViewMode mode;
  final VoidCallback onRecordTap;
  final VoidCallback? onStopTap;

  const RecordingControls({
    required this.mode,
    required this.onRecordTap,
    this.onStopTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final showStopButton =
        mode == NoteViewMode.recording || mode == NoteViewMode.paused;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Stop button (visible when recording or paused)
          if (showStopButton) ...[
            _StopButton(onTap: onStopTap),
            const SizedBox(width: 24),
          ],

          // Main mic/pause button
          _MicButton(
            mode: mode,
            onTap: onRecordTap,
          ),

          // Placeholder for symmetry
          if (showStopButton) ...[
            const SizedBox(width: 24),
            const SizedBox(width: 56), // Match stop button width
          ],
        ],
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final NoteViewMode mode;
  final VoidCallback onTap;

  const _MicButton({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRecording = mode == NoteViewMode.recording;
    final isPaused = mode == NoteViewMode.paused;
    final isProcessing = mode == NoteViewMode.processing;

    if (isProcessing) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: (isRecording
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary)
                  .withOpacity(0.3),
              blurRadius: isRecording ? 12 : 8,
              spreadRadius: isRecording ? 2 : 0,
            ),
          ],
        ),
        child: Icon(
          isRecording
              ? Icons.pause
              : isPaused
                  ? Icons.play_arrow
                  : Icons.mic,
          size: 32,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _StopButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap?.call();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: theme.colorScheme.outline,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.stop,
          size: 28,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
