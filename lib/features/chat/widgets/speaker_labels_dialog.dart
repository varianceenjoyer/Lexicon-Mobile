import 'package:flutter/material.dart';

/// Dialog for editing speaker labels.
class SpeakerLabelsDialog extends StatefulWidget {
  final Map<int, String> currentLabels;
  final ValueChanged<Map<int, String>> onSave;

  const SpeakerLabelsDialog({
    required this.currentLabels,
    required this.onSave,
    super.key,
  });

  @override
  State<SpeakerLabelsDialog> createState() => _SpeakerLabelsDialogState();
}

class _SpeakerLabelsDialogState extends State<SpeakerLabelsDialog> {
  late Map<int, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    // Ensure we have at least 2 speakers
    final labels = Map<int, String>.from(widget.currentLabels);
    if (!labels.containsKey(0)) labels[0] = '';
    if (!labels.containsKey(1)) labels[1] = '';

    _controllers = {
      for (var entry in labels.entries)
        entry.key: TextEditingController(text: entry.value),
    };
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedKeys = _controllers.keys.toList()..sort();

    return AlertDialog(
      title: const Text('Speaker Labels'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Assign names to speakers for easier identification.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
            for (var key in sortedKeys)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: _controllers[key],
                  decoration: InputDecoration(
                    labelText: 'Speaker ${key + 1}',
                    hintText: 'e.g., Alice, Bob',
                    prefixIcon: Icon(
                      Icons.person,
                      color: key % 2 == 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
          ],
        ),
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
    final labels = <int, String>{};
    for (var entry in _controllers.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty) {
        labels[entry.key] = text;
      }
    }
    widget.onSave(labels);
    Navigator.pop(context);
  }
}
