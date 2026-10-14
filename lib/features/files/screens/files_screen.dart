import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/navigation_extensions.dart';
import '../../../services/lexicon_core_service.dart';
import '../../note/providers/note_provider.dart';
import '../providers/files_provider.dart';
import '../providers/import_provider.dart';
import '../widgets/file_list.dart';
import '../widgets/file_preview.dart';
import '../widgets/files_app_bar.dart';
import '../widgets/import_dialog.dart';

/// File Manager View screen for browsing, previewing, and managing transcriptions.
class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesState = ref.watch(filesProvider);

    return Scaffold(
      appBar: FilesAppBar(
        onSearch: (query) => ref.read(filesProvider.notifier).search(query),
        onMenuAction: (action) => _handleMenuAction(context, ref, action),
        onSortTap: () => _showSortOptions(context, ref),
      ),
      body: filesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filesState.errorMessage != null
              ? _ErrorView(
                  message: filesState.errorMessage!,
                  onRetry: () => ref.read(filesProvider.notifier).refresh(),
                )
              : _buildContent(context, ref, filesState),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, FilesState state) {
    // Use search results if searching
    final sessions =
        state.searchQuery.isNotEmpty ? _filterBySearch(state) : state.sessions;

    // Responsive layout: side-by-side on tablet, stacked on phone
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        if (isTablet) {
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: FileList(
                  sessions: sessions,
                  selectedId: state.selectedSession?.id,
                  onSelect: (id) =>
                      ref.read(filesProvider.notifier).selectSession(id),
                  onDelete: (id) =>
                      ref.read(filesProvider.notifier).deleteSession(id),
                  onRename: (id, title) =>
                      ref.read(filesProvider.notifier).renameSession(id, title),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 3,
                child: FilePreview(
                  session: state.selectedSessionDetail,
                  onOpen: (id, type) => _openSession(context, ref, id, type),
                ),
              ),
            ],
          );
        }

        return FileList(
          sessions: sessions,
          selectedId: null,
          onSelect: (id) => _showPreviewSheet(context, ref, id),
          onDelete: (id) => ref.read(filesProvider.notifier).deleteSession(id),
          onRename: (id, title) =>
              ref.read(filesProvider.notifier).renameSession(id, title),
        );
      },
    );
  }

  List<SessionSummary> _filterBySearch(FilesState state) {
    final searchIds = state.searchResults.map((r) => r.sessionId).toSet();
    return state.sessions.where((s) => searchIds.contains(s.id)).toList();
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'import':
        _showImportDialog(context, ref);
        break;
      case 'export':
        // TODO: Show export options
        break;
      case 'settings':
        context.pushSettings();
        break;
      case 'about':
        _showAboutDialog(context);
        break;
    }
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ImportDialog(),
    );
    ref.read(importProvider.notifier).selectFile();
  }

  void _showSortOptions(BuildContext context, WidgetRef ref) {
    final currentSort = ref.read(filesProvider).sortOrder;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Sort by',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _SortOption(
              label: 'Newest first',
              isSelected: currentSort == SortOrder.dateDesc,
              onTap: () {
                ref.read(filesProvider.notifier).setSortOrder(SortOrder.dateDesc);
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: 'Oldest first',
              isSelected: currentSort == SortOrder.dateAsc,
              onTap: () {
                ref.read(filesProvider.notifier).setSortOrder(SortOrder.dateAsc);
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: 'Name (A-Z)',
              isSelected: currentSort == SortOrder.nameAsc,
              onTap: () {
                ref.read(filesProvider.notifier).setSortOrder(SortOrder.nameAsc);
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: 'Name (Z-A)',
              isSelected: currentSort == SortOrder.nameDesc,
              onTap: () {
                ref.read(filesProvider.notifier).setSortOrder(SortOrder.nameDesc);
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: 'Duration (longest)',
              isSelected: currentSort == SortOrder.durationDesc,
              onTap: () {
                ref
                    .read(filesProvider.notifier)
                    .setSortOrder(SortOrder.durationDesc);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPreviewSheet(BuildContext context, WidgetRef ref, SessionId id) {
    ref.read(filesProvider.notifier).selectSession(id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(filesProvider);
              return FilePreview(
                session: state.selectedSessionDetail,
                onOpen: (id, type) {
                  Navigator.pop(context);
                  _openSession(context, ref, id, type);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _openSession(
      BuildContext context, WidgetRef ref, SessionId id, ViewType type) {
    switch (type) {
      case ViewType.note:
        ref.read(noteProvider.notifier).loadSession(id);
        context.goToNote();
        break;
      case ViewType.chat:
        context.goToChat();
        break;
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Lexicon',
      applicationVersion: '0.1.0',
      applicationLegalese: '© 2026 Variance Enjoyer',
      children: [
        const SizedBox(height: 16),
        const Text('Cross-platform speech transcription powered by local AI.'),
      ],
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
