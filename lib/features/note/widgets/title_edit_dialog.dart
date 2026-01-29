import 'package:flutter/material.dart';

/// Dialog for editing a note or chat session title.
class TitleEditDialog extends StatefulWidget {
  final String currentTitle;
  final ValueChanged<String> onSave;

  const TitleEditDialog({
    required this.currentTitle,
    required this.onSave,
    super.key,
  });

  @override
  State<TitleEditDialog> createState() => _TitleEditDialogState();
}

class _TitleEditDialogState extends State<TitleEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Title'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Enter a title',
        ),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    final title = _controller.text.trim();
    if (title.isNotEmpty) {
      widget.onSave(title);
    }
    Navigator.pop(context);
  }
}
