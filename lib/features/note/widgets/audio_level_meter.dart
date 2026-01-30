import 'package:flutter/material.dart';

/// A horizontal audio level meter that displays input volume.
class AudioLevelMeter extends StatelessWidget {
  final double level;
  final bool isActive;

  const AudioLevelMeter({
    required this.level,
    required this.isActive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Icon(
            Icons.mic,
            size: 16,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    // Background track
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Level indicator
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 50),
                      widthFactor: isActive ? level.clamp(0.0, 1.0) : 0.0,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              _getLevelColor(level, theme),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.volume_up,
            size: 16,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(double level, ThemeData theme) {
    if (level > 0.8) {
      return theme.colorScheme.error;
    } else if (level > 0.6) {
      return Colors.orange;
    } else {
      return theme.colorScheme.primary;
    }
  }
}
