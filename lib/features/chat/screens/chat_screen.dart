import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';

/// Chat View screen for multi-speaker diarized transcription.
///
/// Displays conversation as a chat-like interface with speaker bubbles.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
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
          // Chat messages area
          Expanded(
            child: _ChatMessageList(),
          ),
          // Recording indicator
          _RecordingStatus(),
        ],
      ),
      floatingActionButton: const _RecordButton(),
    );
  }
}

class _ChatMessageList extends StatelessWidget {
  const _ChatMessageList();

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual messages from provider
    final messages = <_MockMessage>[
      _MockMessage(speakerId: 0, text: 'Hello, how are you?'),
      _MockMessage(speakerId: 1, text: "I'm doing great, thanks!"),
      _MockMessage(speakerId: 0, text: 'Wonderful to hear.'),
    ];

    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Tap the microphone to start a conversation recording',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _ChatBubble(
          text: message.text,
          speakerId: message.speakerId,
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final int speakerId;

  const _ChatBubble({
    required this.text,
    required this.speakerId,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = speakerId % 2 == 0;
    final colorScheme = Theme.of(context).colorScheme;

    final bubbleColor = isLeft
        ? Color(AppConstants.speakerLeftColorValue).withOpacity(0.15)
        : Color(AppConstants.speakerRightColorValue).withOpacity(0.15);

    return Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isLeft ? 0 : 48,
          right: isLeft ? 48 : 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isLeft ? 4 : 16),
            bottomRight: Radius.circular(isLeft ? 16 : 4),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _RecordingStatus extends StatelessWidget {
  const _RecordingStatus();

  @override
  Widget build(BuildContext context) {
    // TODO: Show actual recording status from provider
    return const SizedBox.shrink();
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

class _MockMessage {
  final int speakerId;
  final String text;

  _MockMessage({required this.speakerId, required this.text});
}
