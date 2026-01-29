---
id: WP-NAV
type: work-plan
status: ready
phase: mvp
created: 2026-01-29
updated: 2026-01-29
author: design-lead
consumers: [developer]
depends-on: [WP-SETUP]
blocks: [WP-NOTE, WP-CHAT, WP-FILES]
priority: high
tags: [navigation, go_router, scaffold, bottom_nav]
---

# WP-NAV: Navigation and App Shell

## Overview

Implement the app shell with bottom navigation and GoRouter configuration. This provides the navigation structure for switching between Note View, Chat View, and File Manager View.

## Scope

### Included
- GoRouter configuration with bottom navigation shell
- Bottom navigation bar with three tabs (Note, Chat, Files)
- Navigation guards for unsaved recording prompts
- Deep linking support for file opening
- Route path constants

### Excluded
- View content implementations (see WP-NOTE, WP-CHAT, WP-FILES)
- State management (see WP-STATE)

## Interface Contract

### Route Paths

```dart
// lib/core/router/routes.dart

abstract class Routes {
  static const String note = '/note';
  static const String chat = '/chat';
  static const String files = '/files';
  static const String fileDetail = '/files/:id';
  static const String settings = '/settings';
}
```

### Router Configuration

```dart
// lib/core/router/app_router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.note,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.note,
                builder: (context, state) => const NoteScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.chat,
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.files,
                builder: (context, state) => const FilesScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return FileDetailScreen(sessionId: SessionId(id));
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    redirect: (context, state) {
      // Navigation guards here
      return null;
    },
  );
});
```

### App Shell Widget

```dart
// lib/shared/widgets/app_shell.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt),
            label: 'Note',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Files',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    // Check for unsaved recording before navigation
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
```

### Navigation Guard Dialog

```dart
// lib/shared/widgets/unsaved_recording_dialog.dart

class UnsavedRecordingDialog extends StatelessWidget {
  const UnsavedRecordingDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const UnsavedRecordingDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unsaved Recording'),
      content: const Text(
        'You have an active recording. What would you like to do?'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Discard recording
            Navigator.pop(context, true);
          },
          child: const Text('Discard'),
        ),
        FilledButton(
          onPressed: () {
            // Save and continue
            Navigator.pop(context, true);
          },
          child: const Text('Save & Continue'),
        ),
      ],
    );
  }
}
```

### Navigation Extensions

```dart
// lib/core/router/navigation_extensions.dart

extension NavigationExtensions on BuildContext {
  /// Navigate to Note view
  void goToNote() => go(Routes.note);

  /// Navigate to Chat view
  void goToChat() => go(Routes.chat);

  /// Navigate to Files view
  void goToFiles() => go(Routes.files);

  /// Navigate to file detail/preview
  void goToFileDetail(SessionId id) => go('${Routes.files}/${id.value}');

  /// Navigate to Settings
  void goToSettings() => go(Routes.settings);

  /// Open session in appropriate view
  void openSession(SessionId id, ViewType viewType) {
    switch (viewType) {
      case ViewType.note:
        goToNote();
        // Load session via provider
        break;
      case ViewType.chat:
        goToChat();
        // Load session via provider
        break;
    }
  }
}
```

## Acceptance Criteria

- [ ] Bottom navigation shows three tabs (Note, Chat, Files)
- [ ] Tab switching preserves state within each branch
- [ ] Active tab is visually indicated
- [ ] Tapping active tab scrolls to top (standard behavior)
- [ ] Navigation to Settings works via route
- [ ] Deep link to file detail works (/files/:id)
- [ ] Opening file from Files view loads in Note/Chat view correctly
- [ ] Navigation guard prompts for unsaved recording
- [ ] Material 3 NavigationBar styling applies correctly
- [ ] Navigation persists across app lifecycle
- [ ] Unit tests pass for router configuration

## Dependencies

### Requires
- WP-SETUP complete (Flutter project structure, go_router dependency)

### Blocks
- WP-NOTE (needs navigation shell)
- WP-CHAT (needs navigation shell)
- WP-FILES (needs navigation shell)

## Files to Create

| File | Purpose |
|------|---------|
| `lib/core/router/routes.dart` | Route path constants |
| `lib/core/router/app_router.dart` | GoRouter configuration |
| `lib/core/router/navigation_extensions.dart` | Navigation convenience methods |
| `lib/shared/widgets/app_shell.dart` | Bottom navigation shell |
| `lib/shared/widgets/unsaved_recording_dialog.dart` | Navigation guard dialog |
| `test/router/app_router_test.dart` | Router unit tests |

## Navigation Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                          APP SHELL                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    CONTENT AREA                               │  │
│  │                                                                │  │
│  │    ┌────────────┐ ┌────────────┐ ┌────────────┐              │  │
│  │    │  Note View │ │  Chat View │ │ Files View │              │  │
│  │    │ (branch 0) │ │ (branch 1) │ │ (branch 2) │              │  │
│  │    └────────────┘ └────────────┘ └────────────┘              │  │
│  │                                                                │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                  NAVIGATION BAR                               │  │
│  │     [Note]          [Chat]          [Files]                   │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘

Deep Links:
  /note                    → Note View
  /chat                    → Chat View
  /files                   → Files List
  /files/:id              → File Detail (opens in Note/Chat)
  /settings               → Settings (pushed on top)
```

## Research References

- [Architecture: Navigation Structure](../design/architecture.md#navigation-structure)
- [project.md: Navigation Rules](../project.md)

## Notes

- Use StatefulShellRoute for state preservation across tabs
- Navigation bar is Material 3 (NavigationBar, not BottomNavigationBar)
- Consider recording state when switching tabs
- File detail can open in Note or Chat view based on session type

---

*Work package created: 2026-01-29*
