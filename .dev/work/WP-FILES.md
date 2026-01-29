---
id: WP-FILES
type: work-plan
status: complete
phase: mvp
created: 2026-01-29
updated: 2026-01-29
author: design-lead
consumers: [developer]
depends-on: [WP-SETUP, WP-STATE, WP-NAV]
blocks: []
priority: high
tags: [files, manager, import, export, search]
---

# WP-FILES: File Manager View Implementation

## Overview

Implement the File Manager View for browsing, previewing, searching, and importing transcription files. This view provides file management capabilities with a master-detail layout.

## Scope

### Included
- FilesScreen with file list and preview pane
- Session list with sorting and filtering
- Full-text search across transcriptions
- File preview with metadata display
- Hamburger menu with import/export/settings
- Import audio file workflow with progress modal
- Rename, delete file operations
- Open file in Note/Chat view

### Excluded
- State management logic (provided by WP-STATE)
- Navigation shell (provided by WP-NAV)
- Audio capture (not needed in Files view)

## Interface Contract

### FilesScreen Widget

```dart
// lib/features/files/screens/files_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesState = ref.watch(filesNotifierProvider);

    return Scaffold(
      appBar: FilesAppBar(
        onSearch: (query) => ref.read(filesNotifierProvider.notifier).search(query),
        onMenuAction: (action) => _handleMenuAction(context, ref, action),
      ),
      body: filesState.when(
        data: (state) => _buildContent(context, ref, state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorView(message: error.toString()),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, FilesState state) {
    // Responsive layout: side-by-side on tablet, stacked on phone
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (isTablet) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: FileList(
              sessions: state.sessions,
              selectedId: state.selectedSession?.id,
              onSelect: (id) => ref.read(filesNotifierProvider.notifier).selectSession(id),
              onDelete: (id) => ref.read(filesNotifierProvider.notifier).deleteSession(id),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 3,
            child: FilePreview(
              session: state.selectedSession,
              onOpen: (id, type) => _openSession(context, id, type),
            ),
          ),
        ],
      );
    }

    return FileList(
      sessions: state.sessions,
      selectedId: null,
      onSelect: (id) => _showPreviewSheet(context, ref, id),
      onDelete: (id) => ref.read(filesNotifierProvider.notifier).deleteSession(id),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'import':
        _showImportDialog(context, ref);
        break;
      case 'settings':
        context.goToSettings();
        break;
    }
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ImportDialog(),
    );
    ref.read(importNotifierProvider.notifier).selectFile();
  }

  void _openSession(BuildContext context, SessionId id, ViewType type) {
    context.openSession(id, type);
  }
}
```

### FilesAppBar Widget

```dart
// lib/features/files/widgets/files_app_bar.dart

class FilesAppBar extends StatefulWidget implements PreferredSizeWidget {
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onMenuAction;

  const FilesAppBar({
    required this.onSearch,
    required this.onMenuAction,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<FilesAppBar> createState() => _FilesAppBarState();
}

class _FilesAppBarState extends State<FilesAppBar> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: _isSearching
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() {
                _isSearching = false;
                _searchController.clear();
                widget.onSearch('');
              }),
            )
          : Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _showDrawer(context),
              ),
            ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search transcriptions...',
                border: InputBorder.none,
              ),
              onChanged: widget.onSearch,
            )
          : const Text('Files'),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            if (_isSearching) {
              _searchController.clear();
              widget.onSearch('');
            }
            setState(() => _isSearching = !_isSearching);
          },
        ),
      ],
    );
  }

  void _showDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FilesMenu(
        onAction: widget.onMenuAction,
      ),
    );
  }
}
```

### FileList Widget

```dart
// lib/features/files/widgets/file_list.dart

class FileList extends StatelessWidget {
  final List<SessionSummary> sessions;
  final SessionId? selectedId;
  final ValueChanged<SessionId> onSelect;
  final ValueChanged<SessionId> onDelete;

  const FileList({
    required this.sessions,
    this.selectedId,
    required this.onSelect,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const EmptyFilesView();
    }

    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return FileListTile(
          session: session,
          isSelected: session.id == selectedId,
          onTap: () => onSelect(session.id),
          onDelete: () => _confirmDelete(context, session),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, SessionSummary session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Delete "${session.title}"? This cannot be undone.'),
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
              onDelete(session.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
```

### FileListTile Widget

```dart
// lib/features/files/widgets/file_list_tile.dart

class FileListTile extends StatelessWidget {
  final SessionSummary session;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const FileListTile({
    required this.session,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: Icon(
          session.viewType == ViewType.note
              ? Icons.note_alt
              : Icons.chat_bubble,
        ),
        title: Text(session.title),
        subtitle: Text(_formatMetadata()),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.outline,
        ),
        selected: isSelected,
        onTap: onTap,
      ),
    );
  }

  String _formatMetadata() {
    final date = _formatDate(session.createdAt);
    final duration = session.duration != null
        ? _formatDuration(session.duration!)
        : '';
    return '$date${duration.isNotEmpty ? ' • $duration' : ''}';
  }

  String _formatDate(DateTime date) {
    // Today, Yesterday, or date
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month) {
      if (date.day == now.day) return 'Today';
      if (date.day == now.day - 1) return 'Yesterday';
    }
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    if (d.inHours < 1) return '${d.inMinutes}m';
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
}
```

### FilePreview Widget

```dart
// lib/features/files/widgets/file_preview.dart

class FilePreview extends StatelessWidget {
  final Session? session;
  final void Function(SessionId, ViewType) onOpen;

  const FilePreview({
    this.session,
    required this.onOpen,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (session == null) {
      return const Center(
        child: Text('Select a file to preview'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with metadata
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session!.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              _MetadataRow(session: session!),
            ],
          ),
        ),
        const Divider(),

        // Text preview
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              _previewText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _export(context),
                  icon: const Icon(Icons.share),
                  label: const Text('Export'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onOpen(session!.id, session!.viewType),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _previewText {
    return session!.segments
        .map((s) => s.text)
        .join('\n\n');
  }

  void _export(BuildContext context) {
    // Show export options
  }
}

class _MetadataRow extends StatelessWidget {
  final Session session;

  const _MetadataRow({required this.session});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      children: [
        _MetadataChip(
          icon: Icons.calendar_today,
          label: _formatDate(session.createdAt),
        ),
        if (session.duration != null)
          _MetadataChip(
            icon: Icons.timer,
            label: _formatDuration(session.duration!),
          ),
        _MetadataChip(
          icon: session.viewType == ViewType.note
              ? Icons.note_alt
              : Icons.chat_bubble,
          label: session.viewType == ViewType.note ? 'Note' : 'Chat',
        ),
        _MetadataChip(
          icon: Icons.segment,
          label: '${session.segments.length} segments',
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    if (d.inHours < 1) return '${d.inMinutes}m';
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetadataChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
```

### ImportDialog Widget

```dart
// lib/features/files/widgets/import_dialog.dart

class ImportDialog extends ConsumerWidget {
  const ImportDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(importNotifierProvider);

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
    return switch (state) {
      ImportIdle() => const Text('Select an audio file to transcribe.'),
      ImportSelecting() => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      ImportProcessing(:final progress, :final fileName) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Transcribing: $fileName'),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text('${(progress * 100).toInt()}%'),
          ],
        ),
      ImportComplete(:final fileName) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text('Saved as: $fileName'),
          ],
        ),
      ImportError(:final message) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
    };
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref, ImportState state) {
    final notifier = ref.read(importNotifierProvider.notifier);

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
            onPressed: () => notifier.cancelImport(),
            child: const Text('Cancel'),
          ),
        ],
      ImportComplete(:final sessionId) => [
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
              // Open the imported session
              context.goToFileDetail(sessionId);
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
```

### FilesMenu Widget

```dart
// lib/features/files/widgets/files_menu.dart

class FilesMenu extends StatelessWidget {
  final ValueChanged<String> onAction;

  const FilesMenu({required this.onAction, super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import Audio File'),
            onTap: () {
              Navigator.pop(context);
              onAction('import');
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Selected'),
            subtitle: const Text('SRT, TXT, JSON'),
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
        ],
      ),
    );
  }
}
```

## Layout Specification

### Phone Layout

```
┌────────────────────────────────────────────┐
│  [App Bar]                                 │
│  ☰ Files                               🔍  │
├────────────────────────────────────────────┤
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │ 📝 Directions                        │ │
│  │    Today • 5m                      > │ │
│  ├──────────────────────────────────────┤ │
│  │ 💬 Team Standup                      │ │
│  │    Yesterday • 15m                 > │ │
│  ├──────────────────────────────────────┤ │
│  │ 📝 Groceries                         │ │
│  │    Yesterday • 2m                  > │ │
│  ├──────────────────────────────────────┤ │
│  │ 📝 Todo List                         │ │
│  │    1/25/2026 • 8m                  > │ │
│  └──────────────────────────────────────┘ │
│                                            │
├────────────────────────────────────────────┤
│           [Bottom Navigation]              │
└────────────────────────────────────────────┘
```

### Tablet Layout

```
┌──────────────────────────────────────────────────────────────────────────┐
│  [App Bar]                                                                │
│  ☰ Files                                                             🔍   │
├───────────────────────┬──────────────────────────────────────────────────┤
│                       │                                                   │
│  File List            │  Preview / Metadata                              │
│                       │                                                   │
│  ┌─────────────────┐ │  Meeting Notes                                    │
│  │ 📝 Directions   │ │  ─────────────────────────────────                │
│  │ 📝 Groceries ●  │ │  📅 Today  ⏱ 5m  📝 Note  📄 12 segments         │
│  │ 💬 Standup      │ │                                                   │
│  │ 📝 Todo         │ │  Lorem ipsum dolor sit amet,                      │
│  │ 📝 Pricequote   │ │  consectetur adipiscing elit.                     │
│  │    ...          │ │  Sed do eiusmod tempor...                         │
│  └─────────────────┘ │                                                   │
│                       │  [Export]              [Open]                     │
│                       │                                                   │
├───────────────────────┴──────────────────────────────────────────────────┤
│                          [Bottom Navigation]                              │
└──────────────────────────────────────────────────────────────────────────┘
```

## Acceptance Criteria

- [ ] FilesScreen displays list of sessions
- [ ] Sessions show title, date, duration, and type icon
- [ ] Tapping session shows preview (sheet on phone, side pane on tablet)
- [ ] Preview shows metadata and text content
- [ ] Open button navigates to Note/Chat view with session loaded
- [ ] Swipe-to-delete removes session with confirmation
- [ ] Search bar filters sessions by text content (FTS5)
- [ ] Hamburger menu shows import/export/settings options
- [ ] Import workflow shows file picker
- [ ] Import progress displays percentage
- [ ] Import cancel stops transcription cleanly
- [ ] Import complete shows success with preview option
- [ ] Empty state displays when no sessions exist
- [ ] Responsive layout adapts to phone/tablet
- [ ] Widget tests pass for all components

## Dependencies

### Requires
- WP-SETUP complete (Flutter project)
- WP-STATE complete (FilesNotifier, ImportNotifier)
- WP-NAV complete (Navigation shell)

### Blocks
- None (end-point work package)

## Files to Create

| File | Purpose |
|------|---------|
| `lib/features/files/screens/files_screen.dart` | Main screen widget |
| `lib/features/files/widgets/files_app_bar.dart` | App bar with search |
| `lib/features/files/widgets/file_list.dart` | Session list |
| `lib/features/files/widgets/file_list_tile.dart` | List item widget |
| `lib/features/files/widgets/file_preview.dart` | Preview pane |
| `lib/features/files/widgets/import_dialog.dart` | Import workflow modal |
| `lib/features/files/widgets/files_menu.dart` | Hamburger menu sheet |
| `lib/features/files/widgets/empty_files_view.dart` | Empty state |
| `test/features/files/files_screen_test.dart` | Screen widget tests |
| `test/features/files/widgets/` | Widget unit tests |

## Research References

- [project.md: File Manager View Specification](../project.md#3-file-manager-view)
- [Architecture: File Manager Architecture](../design/architecture.md#file-manager-architecture)
- [R-DIST-01](../design/research/R-DIST-01-build-distribution.md) — Export formats

## Notes

- Responsive layout: use `LayoutBuilder` or `MediaQuery`
- FTS5 search provided by Lexicon Core
- Export formats: TXT, VTT, JSON (per project.md)
- File picker uses platform native UI via file_picker package
- Consider pagination for large file lists

---

*Work package created: 2026-01-29*
