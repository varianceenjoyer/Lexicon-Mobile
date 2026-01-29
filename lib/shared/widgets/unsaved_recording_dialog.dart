import 'package:flutter/material.dart';

/// Dialog shown when user attempts to navigate away from an active recording.
class UnsavedRecordingDialog extends StatelessWidget {
  const UnsavedRecordingDialog({super.key});

  /// Shows the dialog and returns the user's choice.
  ///
  /// Returns `true` if user chose to discard or save, `false` if cancelled.
  static Future<UnsavedRecordingAction?> show(BuildContext context) async {
    return showDialog<UnsavedRecordingAction>(
      context: context,
      builder: (context) => const UnsavedRecordingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unsaved Recording'),
      content: const Text(
        'You have an active recording. What would you like to do?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, UnsavedRecordingAction.cancel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, UnsavedRecordingAction.discard),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Discard'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, UnsavedRecordingAction.saveAndContinue),
          child: const Text('Save & Continue'),
        ),
      ],
    );
  }
}

/// Actions available when there's an unsaved recording.
enum UnsavedRecordingAction {
  /// User wants to cancel navigation
  cancel,

  /// User wants to discard the recording
  discard,

  /// User wants to save and continue
  saveAndContinue,
}
