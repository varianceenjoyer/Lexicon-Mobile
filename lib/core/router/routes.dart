/// Route path constants for Lexicon Mobile.
abstract class Routes {
  /// Note view - single-speaker transcription
  static const String note = '/note';

  /// Chat view - multi-speaker diarized transcription
  static const String chat = '/chat';

  /// File manager view
  static const String files = '/files';

  /// File detail view with session ID parameter
  static const String fileDetail = '/files/:id';

  /// Settings screen
  static const String settings = '/settings';
}
