import 'package:flutter/material.dart';

import '../../../services/lexicon_core_service.dart';
import 'file_list_tile.dart';

/// Scrollable list of session files.
class FileList extends StatelessWidget {
  final List<SessionSummary> sessions;
  final SessionId? selectedId;
  final ValueChanged<SessionId> onSelect;
  final ValueChanged<SessionId> onDelete;
  final void Function(SessionId, String)? onRename;

  const FileList({
    required this.sessions,
    this.selectedId,
    required this.onSelect,
    required this.onDelete,
    this.onRename,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const _EmptyFilesView();
    }

    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return FileListTile(
          session: session,
          isSelected: session.id == selectedId,
          onTap: () => onSelect(session.id),
          onDelete: () => onDelete(session.id),
          onRename: onRename != null
              ? () => _showRenameDialog(context, session)
              : null,
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, SessionSummary session) {
    final controller = TextEditingController(text: session.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Title',
          ),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              onRename?.call(session.id, value.trim());
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                onRename?.call(session.id, title);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilesView extends StatelessWidget {
  const _EmptyFilesView();

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
              Icons.folder_off_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No transcriptions yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a recording or import an audio file',
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
