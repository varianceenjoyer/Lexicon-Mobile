import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Note View screen for single-speaker transcription with TTS playback.
///
/// This is the primary view for note-taking, memos, and voice journaling.
class NoteScreen extends ConsumerWidget {
  const NoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show overflow menu
            },
          ),
        ],
      ),
      body: const Column(
        children: [
          // Transcription text area
          Expanded(
            child: _TranscriptionArea(),
          ),
          // TTS playback controls
          _PlaybackControls(),
        ],
      ),
      floatingActionButton: const _RecordButton(),
    );
  }
}

class _TranscriptionArea extends StatelessWidget {
  const _TranscriptionArea();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Editable title
          TextField(
            decoration: const InputDecoration(
              hintText: 'Untitled Note',
              border: InputBorder.none,
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          // Transcription text
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SingleChildScrollView(
                child: Text(
                  'Tap the microphone to start recording...',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              // TODO: Start TTS playback
            },
          ),
          Expanded(
            child: Slider(
              value: 0,
              onChanged: (value) {
                // TODO: Seek playback
              },
            ),
          ),
          const Text('0:00 / 0:00'),
        ],
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.large(
      onPressed: () {
        // TODO: Toggle recording
      },
      child: const Icon(Icons.mic),
    );
  }
}
