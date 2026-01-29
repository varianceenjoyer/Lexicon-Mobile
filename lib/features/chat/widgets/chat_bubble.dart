import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/chat_provider.dart';

/// Individual chat bubble widget for displaying a message.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLeftAligned;
  final String? speakerLabel;

  const ChatBubble({
    required this.message,
    required this.isLeftAligned,
    this.speakerLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final speakerColor = isLeftAligned
        ? Color(AppConstants.speakerLeftColorValue)
        : Color(AppConstants.speakerRightColorValue);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isLeftAligned ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isLeftAligned) const Spacer(flex: 1),
          Flexible(
            flex: 3,
            child: GestureDetector(
              onLongPress: () => _showTimestamp(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: speakerColor.withOpacity(0.15),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isLeftAligned ? 4 : 16),
                    bottomRight: Radius.circular(isLeftAligned ? 16 : 4),
                  ),
                  border: Border.all(
                    color: speakerColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speakerLabel ?? 'Speaker ${message.speakerId + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: speakerColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      message.text,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLeftAligned) const Spacer(flex: 1),
        ],
      ),
    );
  }

  void _showTimestamp(BuildContext context) {
    final startTime = Duration(milliseconds: message.startMs);
    final formatted = _formatDuration(startTime);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Timestamp: $formatted'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
