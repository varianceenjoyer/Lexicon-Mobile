import 'package:flutter/material.dart';

/// Hamburger menu for file manager actions.
class FilesMenu extends StatelessWidget {
  final ValueChanged<String> onAction;

  const FilesMenu({required this.onAction, super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import Audio File'),
            subtitle: const Text('Transcribe an audio file'),
            onTap: () {
              Navigator.pop(context);
              onAction('import');
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Selected'),
            subtitle: const Text('TXT, VTT, JSON'),
            onTap: () {
              Navigator.pop(context);
              onAction('export');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              onAction('settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              onAction('about');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
