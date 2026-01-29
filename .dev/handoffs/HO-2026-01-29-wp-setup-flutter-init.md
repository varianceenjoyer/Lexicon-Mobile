---
id: HO-2026-01-29-wp-setup
type: handoff
status: ready
created: 2026-01-29
updated: 2026-01-29
from: design-lead
to: developer
work-package: WP-SETUP
priority: critical
tags: [flutter, setup, initialization]
---

# Handoff: Flutter Project Initialization

## Summary

The design phase for Lexicon Mobile is complete. All feasibility research has been validated, architecture documents are finalized, and work packages are ready for implementation.

**First task**: Initialize the Flutter project following WP-SETUP specifications.

## Context

Lexicon Mobile is a Flutter-based cross-platform app (iOS/Android) for speech transcription. The architecture has been thoroughly researched and documented:

- [Architecture Document](../design/architecture.md) — Full technical specification
- [Project Specification](../project.md) — Product requirements and view layouts
- [Research Index](../design/research/_index.md) — All feasibility research (8 completed studies)

Key decisions already made:
- **Framework**: Flutter (not native) for ~50% maintenance reduction
- **FFI**: flutter_rust_bridge v2 for Rust integration
- **State**: Riverpod for reactive state management
- **Navigation**: GoRouter with bottom navigation
- **Audio**: `record` + `just_audio` plugins

## Task

Complete [WP-SETUP](../work/WP-SETUP.md):

1. **Create Flutter project**
   ```bash
   flutter create --org com.lexicon lexicon_mobile
   ```

2. **Set up directory structure**
   ```
   lib/
   ├── main.dart
   ├── app.dart
   ├── core/
   │   ├── theme/
   │   ├── router/
   │   └── constants/
   ├── features/
   │   ├── note/
   │   ├── chat/
   │   └── files/
   ├── services/
   └── shared/
       └── widgets/
   ```

3. **Add dependencies** (see WP-SETUP for full pubspec.yaml)
   - flutter_riverpod
   - go_router
   - freezed_annotation
   - riverpod_annotation

4. **Configure platforms**
   - iOS: Info.plist (mic permission, background audio)
   - Android: AndroidManifest.xml (record audio, foreground service)

5. **Create base files**
   - `lib/main.dart` with ProviderScope
   - `lib/app.dart` with MaterialApp
   - `lib/core/theme/app_theme.dart` with Material 3 theme

## Acceptance Criteria

From WP-SETUP:
- [ ] Flutter project builds for iOS simulator
- [ ] Flutter project builds for Android emulator
- [ ] All dependencies resolve
- [ ] `flutter doctor` shows no critical issues
- [ ] Directory structure matches spec
- [ ] Material 3 theme applies
- [ ] Hot reload works
- [ ] Unit test framework runs

## Deliverables

1. Working Flutter project in repository root
2. Passing `flutter build ios --simulator`
3. Passing `flutter build apk --debug`
4. Updated WP-SETUP status to `in-progress` then `complete`

## Next Steps (after WP-SETUP)

After completing WP-SETUP, the following work packages are unblocked:

| Work Package | Priority | Can Start |
|--------------|----------|-----------|
| WP-AUDIO | critical | Yes (after WP-SETUP) |
| WP-STATE | high | Yes (after WP-SETUP) |
| WP-NAV | high | Yes (after WP-SETUP) |

These can be developed in parallel by multiple developers.

## Questions / Decisions Needed

None — all decisions have been made in the architecture document. If you encounter blockers, document them and create a handoff back to design-lead.

## References

- [WP-SETUP](../work/WP-SETUP.md) — Full work package specification
- [Architecture](../design/architecture.md) — Technical architecture
- [R-FLUTTER-01](../design/research/R-FLUTTER-01-cross-platform-viability.md) — Flutter viability research

---

*Handoff created: 2026-01-29 by design-lead*
