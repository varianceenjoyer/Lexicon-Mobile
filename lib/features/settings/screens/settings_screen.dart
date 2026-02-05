import 'package:flutter/material.dart';

import 'about_screen.dart';
import 'audio_settings_screen.dart';
import 'theme_settings_screen.dart';

/// Settings screen with category navigation.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildCategoryTile(
            context,
            icon: Icons.volume_up,
            title: 'Audio',
            subtitle: 'Silence filter, chunk size, microphone test',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AudioSettingsScreen()),
            ),
          ),
          _buildCategoryTile(
            context,
            icon: Icons.palette,
            title: 'Theme',
            subtitle: 'Color scheme and appearance',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
            ),
          ),
          _buildCategoryTile(
            context,
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version info and licenses',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
