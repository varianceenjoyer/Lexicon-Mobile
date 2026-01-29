import 'package:flutter/material.dart';

/// Text area for displaying and editing transcription text.
class TranscriptionTextArea extends StatelessWidget {
  final TextEditingController controller;
  final ScrollController scrollController;
  final bool isEditable;
  final ValueChanged<String> onTextChanged;
  final String? hintText;

  const TranscriptionTextArea({
    required this.controller,
    required this.scrollController,
    required this.isEditable,
    required this.onTextChanged,
    this.hintText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          scrollController: scrollController,
          maxLines: null,
          expands: true,
          readOnly: !isEditable,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hintText ?? 'Tap the microphone to start recording...',
            hintStyle: TextStyle(
              color: theme.colorScheme.outline,
            ),
          ),
          style: theme.textTheme.bodyLarge,
          onChanged: onTextChanged,
        ),
      ),
    );
  }
}
