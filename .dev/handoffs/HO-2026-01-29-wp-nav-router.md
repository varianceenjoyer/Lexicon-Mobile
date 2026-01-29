---
id: HO-2026-01-29-wp-nav
type: handoff
status: ready
created: 2026-01-29
updated: 2026-01-29
from: design-lead
to: developer
work-package: WP-NAV
priority: high
blocked-by: WP-SETUP
tags: [navigation, go_router, bottom_nav, shell]
---

# Handoff: Navigation and App Shell

## Summary

Implement the app shell with bottom navigation and GoRouter configuration. This provides the navigation structure for switching between Note View, Chat View, and File Manager View.

**Blocked by**: WP-SETUP must be completed first.

## Context

Navigation requirements:
- Bottom navigation with 3 tabs (Note, Chat, Files)
- State preservation across tab switches
- Navigation guards for unsaved recordings
- Deep linking support for file opening

## Task

Complete [WP-NAV](../work/WP-NAV.md):

1. **Create route constants**
   - `lib/core/router/routes.dart`

2. **Configure GoRouter**
   - `lib/core/router/app_router.dart`
   - StatefulShellRoute for state preservation
   - Three branches for Note, Chat, Files

3. **Create app shell**
   - `lib/shared/widgets/app_shell.dart`
   - Material 3 NavigationBar
   - Tab switching logic

4. **Create navigation guard**
   - `lib/shared/widgets/unsaved_recording_dialog.dart`
   - Prompts when switching tabs during recording

## Key Structure

```dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.note,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/note', ...)]),
          StatefulShellBranch(routes: [GoRoute(path: '/chat', ...)]),
          StatefulShellBranch(routes: [GoRoute(path: '/files', ...)]),
        ],
      ),
    ],
  );
});
```

## Acceptance Criteria

From WP-NAV:
- [ ] Bottom navigation shows three tabs
- [ ] Tab switching preserves state
- [ ] Active tab is visually indicated
- [ ] Deep link to file detail works (/files/:id)
- [ ] Navigation guard prompts for unsaved recording
- [ ] Material 3 NavigationBar styling applies
- [ ] Unit tests pass for router

## Notes

- Use StatefulShellRoute for state preservation
- NavigationBar (Material 3) not BottomNavigationBar
- Consider recording state when switching tabs

---

*Handoff created: 2026-01-29 by design-lead*
