/// Application-wide constants for Lexicon Mobile.
class AppConstants {
  AppConstants._();

  /// Application name
  static const String appName = 'Lexicon';

  /// Audio configuration
  static const int audioSampleRate = 16000;
  static const int audioChannels = 1; // Mono
  static const int audioBufferMs = 100;

  /// Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  /// UI constants
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  /// Chat bubble speaker colors
  static const int speakerLeftColorValue = 0xFF1565C0; // Blue
  static const int speakerRightColorValue = 0xFF2E7D32; // Green

  /// File extensions supported for import
  static const List<String> supportedAudioExtensions = [
    '.wav',
    '.mp3',
    '.m4a',
    '.flac',
    '.ogg',
  ];

  /// Export formats
  static const List<String> exportFormats = ['txt', 'vtt', 'json'];
}
