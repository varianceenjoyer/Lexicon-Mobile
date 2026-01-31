import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/settings_provider.dart';

/// Settings screen for configuring app preferences.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Audio'),
          _buildSilenceThresholdTile(context, ref, settings),
          _buildChunkSizeTile(context, ref, settings),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('0.1.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSilenceThresholdTile(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    // Convert threshold to percentage for display (0.01 = 1%)
    final percentage = (settings.silenceThreshold * 100).round();

    return ListTile(
      leading: const Icon(Icons.volume_off),
      title: const Text('Silence Threshold'),
      subtitle: Text(
        percentage == 0
            ? 'Disabled (process all audio)'
            : '$percentage% - Skip audio below this level',
      ),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: settings.silenceThreshold,
          min: 0.0,
          max: 0.1,
          divisions: 20,
          label: percentage == 0 ? 'Off' : '$percentage%',
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setSilenceThreshold(value);
          },
        ),
      ),
    );
  }

  Widget _buildChunkSizeTile(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return ListTile(
      leading: const Icon(Icons.timer),
      title: const Text('Audio Chunk Size'),
      subtitle: Text(
        '${settings.chunkSizeMs}ms - ${_chunkSizeDescription(settings.chunkSizeMs)}',
      ),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: settings.chunkSizeMs.toDouble(),
          min: 100,
          max: 1000,
          divisions: 9,
          label: '${settings.chunkSizeMs}ms',
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setChunkSizeMs(value.round());
          },
        ),
      ),
    );
  }

  String _chunkSizeDescription(int ms) {
    if (ms <= 100) return 'Lowest latency, higher CPU';
    if (ms <= 300) return 'Low latency';
    if (ms <= 500) return 'Balanced';
    if (ms <= 700) return 'Better accuracy';
    return 'Best accuracy, higher latency';
  }
}
