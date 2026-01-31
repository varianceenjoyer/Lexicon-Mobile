import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/screens/chat_screen.dart';
import '../../features/files/screens/files_screen.dart';
import '../../features/note/screens/note_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/widgets/app_shell.dart';
import 'routes.dart';

/// Global navigator key for accessing navigator from anywhere
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter provider for navigation
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.note,
    debugLogDiagnostics: true,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Note View Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.note,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: NoteScreen(),
                ),
              ),
            ],
          ),
          // Chat View Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.chat,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ChatScreen(),
                ),
              ),
            ],
          ),
          // Files View Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.files,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FilesScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      // Settings route (pushed on top of shell)
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    redirect: (context, state) {
      // Navigation guards can be added here
      // For example, checking for unsaved recordings
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
});
