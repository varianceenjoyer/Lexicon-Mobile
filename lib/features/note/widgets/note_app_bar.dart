import 'package:flutter/material.dart';

import 'title_edit_dialog.dart';

/// App bar for the Note View with editable title and overflow menu.
class NoteAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final ValueChanged<String> onTitleEdit;
  final VoidCallback? onExport;
  final VoidCallback? onClearText;
  final VoidCallback? onAutoTest;
  final VoidCallback? onDelete;

  const NoteAppBar({
    this.title,
    required this.onTitleEdit,
    this.onExport,
    this.onClearText,
    this.onAutoTest,
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
                title?.isNotEmpty == true ? title! : 'New Note',
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
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Export'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: ListTile(
                leading: Icon(Icons.clear_all),
                title: Text('Clear Text'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'autotest',
              child: ListTile(
                leading: Icon(Icons.science),
                title: Text('Auto Test'),
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
      case 'export':
        onExport?.call();
        break;
      case 'clear':
        _confirmClearText(context);
        break;
      case 'autotest':
        onAutoTest?.call();
        break;
      case 'delete':
        _confirmDelete(context);
        break;
    }
  }

  void _confirmClearText(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Text'),
        content: const Text('Clear all transcription text? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onClearText?.call();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Delete "${title ?? 'this note'}"? This cannot be undone.'),
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
