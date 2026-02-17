import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/settings_provider.dart';
import 'audio_test_screen.dart';

/// Audio settings sub-screen.
class AudioSettingsScreen extends ConsumerWidget {
  const AudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio'),
      ),
      body: ListView(
        children: [
          _buildNoiseReductionTile(context, ref, settings),
          _buildSilenceThresholdTile(context, ref, settings),
          _buildChunkSizeTile(context, ref, settings),
          const Divider(),
          _buildAudioTestTile(context),
          _buildResetSettingsTile(context, ref),
        ],
      ),
    );
  }

  Widget _buildNoiseReductionTile(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.noise_aware),
      title: const Text('Noise Reduction'),
      subtitle: const Text(
        'Reduces background noise before transcription. '
        'Enable in noisy environments (wind, traffic). '
        'May slightly affect accuracy in quiet settings.',
      ),
      value: settings.noiseReduction,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).setNoiseReduction(value);
      },
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
      title: const Text('Reset Audio Settings'),
      subtitle: const Text('Noise reduction: Off, Silence: Off, Chunk size: 3s'),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset Audio Settings?'),
            content: const Text(
              'This will reset audio settings to recommended defaults:\n\n'
              '• Noise Reduction: Off\n'
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
          final notifier = ref.read(settingsProvider.notifier);
          await notifier.setNoiseReduction(false);
          await notifier.setSilenceThreshold(0.0);
          await notifier.setChunkSizeMs(3000);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Audio settings reset to defaults')),
            );
          }
        }
      },
    );
  }
}
