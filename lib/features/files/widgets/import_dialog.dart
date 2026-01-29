import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/import_provider.dart';

/// Import workflow dialog with progress indicator.
class ImportDialog extends ConsumerWidget {
  const ImportDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(importProvider);

    return AlertDialog(
      title: Text(_title(importState)),
      content: _buildContent(context, importState),
      actions: _buildActions(context, ref, importState),
    );
  }

  String _title(ImportState state) {
    return switch (state) {
      ImportIdle() => 'Import Audio',
      ImportSelecting() => 'Select File',
      ImportProcessing() => 'Processing',
      ImportComplete() => 'Import Complete',
      ImportError() => 'Import Failed',
    };
  }

  Widget _buildContent(BuildContext context, ImportState state) {
    final theme = Theme.of(context);

    return switch (state) {
      ImportIdle() => const Text('Select an audio file to transcribe.'),
      ImportSelecting() => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      ImportProcessing(:final progress, :final fileName) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Transcribing:',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              fileName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ImportComplete(:final fileName) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text('Transcription complete!'),
            const SizedBox(height: 8),
            Text(
              'Saved as: $fileName',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ImportError(:final message) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ),
    };
  }

  List<Widget> _buildActions(
      BuildContext context, WidgetRef ref, ImportState state) {
    final notifier = ref.read(importProvider.notifier);

    return switch (state) {
      ImportIdle() => [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ImportSelecting() => [
          TextButton(
            onPressed: () {
              notifier.reset();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ImportProcessing() => [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              notifier.cancelImport();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ImportComplete() => [
          TextButton(
            onPressed: () {
              notifier.reset();
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
          FilledButton(
            onPressed: () {
              notifier.reset();
              Navigator.pop(context);
              // TODO: Navigate to preview the imported session
            },
            child: const Text('Preview'),
          ),
        ],
      ImportError() => [
          FilledButton(
            onPressed: () {
              notifier.reset();
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
    };
  }
}
