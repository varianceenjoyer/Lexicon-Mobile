import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

/// Navigation convenience extensions for BuildContext.
extension NavigationExtensions on BuildContext {
  /// Navigate to Note view
  void goToNote() => go(Routes.note);

  /// Navigate to Chat view
  void goToChat() => go(Routes.chat);

  /// Navigate to Files view
  void goToFiles() => go(Routes.files);

  /// Navigate to file detail/preview
  void goToFileDetail(String sessionId) => go('${Routes.files}/$sessionId');

  /// Navigate to Settings
  void goToSettings() => go(Routes.settings);

  /// Push Settings screen on top of current view
  void pushSettings() => push(Routes.settings);
}
