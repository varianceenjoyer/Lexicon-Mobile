import 'package:flutter/material.dart';

import '../../note/widgets/title_edit_dialog.dart';
import 'speaker_labels_dialog.dart';

/// App bar for the Chat View with editable title and overflow menu.
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final ValueChanged<String> onTitleEdit;
  final Map<int, String>? speakerLabels;
  final ValueChanged<Map<int, String>>? onSpeakerLabelsEdit;
  final VoidCallback? onExport;
  final VoidCallback? onDelete;

  const ChatAppBar({
    this.title,
    required this.onTitleEdit,
    this.speakerLabels,
    this.onSpeakerLabelsEdit,
    this.onExport,
    this.onDelete,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: GestureDetector(
        onTap: () => _showTitleEditor(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title?.isNotEmpty == true ? title! : 'New Conversation',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Rename'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'speakers',
              child: ListTile(
                leading: Icon(Icons.people),
                title: Text('Speaker Labels'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Export'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showTitleEditor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TitleEditDialog(
        currentTitle: title ?? '',
        onSave: onTitleEdit,
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'rename':
        _showTitleEditor(context);
        break;
      case 'speakers':
        _showSpeakerLabelsEditor(context);
        break;
      case 'export':
        onExport?.call();
        break;
      case 'delete':
        _confirmDelete(context);
        break;
    }
  }

  void _showSpeakerLabelsEditor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SpeakerLabelsDialog(
        currentLabels: speakerLabels ?? {0: '', 1: ''},
        onSave: onSpeakerLabelsEdit ?? (_) {},
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content:
            Text('Delete "${title ?? 'this conversation'}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
