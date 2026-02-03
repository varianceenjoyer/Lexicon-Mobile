import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/settings_provider.dart';
import 'audio_test_screen.dart';

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
          _buildAudioTestTile(context),
          _buildResetSettingsTile(context, ref),
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
      title: const Text('Silence Filter'),
      subtitle: Text(
        percentage == 0
            ? 'Off (recommended) - process all audio'
            : '$percentage% - may skip quiet speech!',
      ),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: settings.silenceThreshold,
          min: 0.0,
          max: 0.05, // Reduced max - high values filter out speech
          divisions: 10,
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
        '${(settings.chunkSizeMs / 1000).toStringAsFixed(1)}s - ${_chunkSizeDescription(settings.chunkSizeMs)}',
      ),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: settings.chunkSizeMs.toDouble(),
          min: 1000,
          max: 5000,
          divisions: 8,
          label: '${(settings.chunkSizeMs / 1000).toStringAsFixed(1)}s',
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setChunkSizeMs(value.round());
          },
        ),
      ),
    );
  }

  String _chunkSizeDescription(int ms) {
    if (ms <= 1500) return 'Faster updates, lower accuracy';
    if (ms <= 2500) return 'Balanced';
    if (ms <= 3500) return 'Better accuracy';
    return 'Best accuracy, slower updates';
  }

  Widget _buildAudioTestTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.mic),
      title: const Text('Test Microphone'),
      subtitle: const Text('Record and playback to verify audio quality'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AudioTestScreen(),
          ),
        );
      },
    );
  }

  Widget _buildResetSettingsTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.restore),
      title: const Text('Reset to Defaults'),
      subtitle: const Text('Silence: Off, Chunk size: 3s'),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset Settings?'),
            content: const Text(
              'This will reset audio settings to recommended defaults:\n\n'
              '• Silence Filter: Off\n'
              '• Chunk Size: 3 seconds',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Reset'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await ref.read(settingsProvider.notifier).resetToDefaults();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings reset to defaults')),
            );
          }
        }
      },
    );
  }
}
