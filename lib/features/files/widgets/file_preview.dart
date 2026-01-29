import 'package:flutter/material.dart';

import '../../../services/lexicon_core_service.dart';

/// Preview pane for displaying session details.
class FilePreview extends StatelessWidget {
  final Session? session;
  final void Function(SessionId, ViewType) onOpen;
  final VoidCallback? onExport;

  const FilePreview({
    this.session,
    required this.onOpen,
    this.onExport,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (session == null) {
      return const _EmptyPreview();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with metadata
        _PreviewHeader(session: session!),
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
        _PreviewActions(
          onOpen: () => onOpen(session!.id, session!.viewType),
          onExport: onExport,
        ),
      ],
    );
  }

  String get _previewText {
    return session!.segments.map((s) => s.text).join('\n\n');
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a file to preview',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  final Session session;

  const _PreviewHeader({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.title,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
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
          ),
        ],
      ),
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
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _PreviewActions extends StatelessWidget {
  final VoidCallback onOpen;
  final VoidCallback? onExport;

  const _PreviewActions({
    required this.onOpen,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.share),
              label: const Text('Export'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open'),
            ),
          ),
        ],
      ),
    );
  }
}
