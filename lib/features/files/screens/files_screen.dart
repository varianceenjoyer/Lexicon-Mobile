import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// File Manager View screen for browsing, previewing, and managing transcriptions.
class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('Files'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Open search
            },
          ),
          PopupMenuButton<_SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (option) {
              // TODO: Change sort order
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _SortOption.dateDesc,
                child: Text('Newest first'),
              ),
              const PopupMenuItem(
                value: _SortOption.dateAsc,
                child: Text('Oldest first'),
              ),
              const PopupMenuItem(
                value: _SortOption.nameAsc,
                child: Text('Name (A-Z)'),
              ),
              const PopupMenuItem(
                value: _SortOption.nameDesc,
                child: Text('Name (Z-A)'),
              ),
            ],
          ),
        ],
      ),
      drawer: const _FileManagerDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Use master-detail layout on larger screens
          if (constraints.maxWidth > 600) {
            return const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _FileList(),
                ),
                VerticalDivider(width: 1),
                Expanded(
                  flex: 3,
                  child: _FilePreview(),
                ),
              ],
            );
          }
          // Single column on smaller screens
          return const _FileList();
        },
      ),
    );
  }
}

class _FileManagerDrawer extends StatelessWidget {
  const _FileManagerDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Lexicon',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text('File Manager'),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import Audio File'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Show file picker
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Selected'),
            enabled: false, // Enable when file is selected
            onTap: () {
              Navigator.pop(context);
              // TODO: Show export dialog
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Show about dialog
            },
          ),
        ],
      ),
    );
  }
}

class _FileList extends StatelessWidget {
  const _FileList();

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual file list from provider
    final files = <_MockFile>[
      _MockFile(
        id: '1',
        title: 'Meeting Notes',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        duration: const Duration(minutes: 15),
        type: 'note',
      ),
      _MockFile(
        id: '2',
        title: 'Interview Recording',
        date: DateTime.now().subtract(const Duration(days: 1)),
        duration: const Duration(minutes: 42),
        type: 'chat',
      ),
      _MockFile(
        id: '3',
        title: 'Quick Memo',
        date: DateTime.now().subtract(const Duration(days: 2)),
        duration: const Duration(minutes: 2),
        type: 'note',
      ),
    ];

    if (files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_off_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No transcriptions yet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a recording or import an audio file',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _FileListItem(file: file);
      },
    );
  }
}

class _FileListItem extends StatelessWidget {
  final _MockFile file;

  const _FileListItem({required this.file});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        file.type == 'note' ? Icons.note_alt : Icons.chat_bubble,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(file.title),
      subtitle: Text(
        '${_formatDate(file.date)} - ${_formatDuration(file.duration)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Select file for preview
      },
      onLongPress: () {
        // TODO: Show context menu (rename, delete)
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _FilePreview extends StatelessWidget {
  const _FilePreview();

  @override
  Widget build(BuildContext context) {
    // TODO: Show selected file preview
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a file to preview',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

enum _SortOption { dateDesc, dateAsc, nameAsc, nameDesc }

class _MockFile {
  final String id;
  final String title;
  final DateTime date;
  final Duration duration;
  final String type;

  _MockFile({
    required this.id,
    required this.title,
    required this.date,
    required this.duration,
    required this.type,
  });
}
