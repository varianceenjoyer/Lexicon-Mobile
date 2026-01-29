import 'package:flutter/material.dart';

import '../providers/chat_provider.dart';
import 'chat_bubble.dart';

/// Scrollable list of chat bubbles.
class ChatBubbleList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final Map<int, String>? speakerLabels;

  const ChatBubbleList({
    required this.messages,
    required this.scrollController,
    this.speakerLabels,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const _EmptyChatView();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isLeftAligned = message.speakerId % 2 == 0;

        return ChatBubble(
          message: message,
          isLeftAligned: isLeftAligned,
          speakerLabel: speakerLabels?[message.speakerId],
        );
      },
    );
  }
}

class _EmptyChatView extends StatelessWidget {
  const _EmptyChatView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the microphone to begin recording.\nSpeakers will be automatically identified.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
