import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_preset.dart';
import '../../../providers/settings_provider.dart';

/// Theme settings screen for color scheme and appearance.
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeModeSelector(context, ref, settings),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Color Scheme'),
          const SizedBox(height: 8),
          _buildPresetGrid(context, ref, settings),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildThemeModeSelector(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto),
          label: Text('System'),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode),
          label: Text('Light'),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode),
          label: Text('Dark'),
        ),
      ],
      selected: {settings.themeMode},
      onSelectionChanged: (Set<ThemeMode> selection) {
        ref.read(settingsProvider.notifier).setThemeMode(selection.first);
      },
    );
  }

  Widget _buildPresetGrid(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: ThemePreset.values.length,
      itemBuilder: (context, index) {
        final preset = ThemePreset.values[index];
        final isSelected = preset == settings.themePreset;

        return _PresetCard(
          preset: preset,
          isSelected: isSelected,
          onTap: () {
            ref.read(settingsProvider.notifier).setThemePreset(preset);
          },
        );
      },
    );
  }
}

class _PresetCard extends StatelessWidget {
  final ThemePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Color preview circles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: preset.primary,
                ),
                const SizedBox(width: 4),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: preset.secondary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Preset name
            Text(
              preset.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            // Selection indicator
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
