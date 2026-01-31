# Work Packages Index

> **Status**: Active | **Last Updated**: 2026-01-31
>
> This index tracks all actionable work packages for Lexicon Mobile.

---

## Milestones

| Date       | Milestone                                      | Notes                                          |
|------------|------------------------------------------------|------------------------------------------------|
| 2026-01-30 | **First x86_64 APK running on virtual device** | MVP build confirmed working in Android emulator |

---

## Overview

Work packages are self-contained units of implementation work with:
- Clear scope and deliverables
- Interface contracts
- Acceptance criteria
- Dependencies mapped

---

## Work Package Status

### Ready for Implementation

| ID | Name | Priority | Phase | Dependencies | Blocks |
|----|------|----------|-------|--------------|--------|
| [WP-LATENCY-MOBILE](WP-LATENCY-MOBILE.md) | Mobile Client Latency Optimization | critical | beta | WP-NOTE | - |

### In Progress

| ID | Name | Owner | Started | Notes |
|----|------|-------|---------|-------|

### Completed (MVP)

| ID | Name | Completed | Notes |
|----|------|-----------|-------|
| [WP-SETUP](WP-SETUP.md) | Flutter Project Setup | 2026-01-29 | Structure, dependencies, platform config |
| [WP-STATE](WP-STATE.md) | State Management (Riverpod) | 2026-01-29 | All providers and notifiers |
| [WP-NAV](WP-NAV.md) | Navigation and App Shell | 2026-01-29 | GoRouter, bottom nav, shell |
| [WP-AUDIO](WP-AUDIO.md) | Audio Capture and Playback | 2026-01-29 | Service interfaces and stubs |
| [WP-NOTE](WP-NOTE.md) | Note View Implementation | 2026-01-29 | Full UI with widgets |
| [WP-CHAT](WP-CHAT.md) | Chat View Implementation | 2026-01-29 | Diarized chat bubbles |
| [WP-FILES](WP-FILES.md) | File Manager View | 2026-01-29 | List, preview, import workflow |

---

## Phase Mapping

### MVP Phase

| Work Package | Description | Status |
|--------------|-------------|--------|
| WP-SETUP | Flutter project initialization | complete |
| WP-AUDIO | Audio capture and playback services | complete |
| WP-STATE | Riverpod state management | complete |
| WP-NAV | Navigation and app shell | complete |
| WP-NOTE | Note View (single-speaker transcription + TTS) | complete |
| WP-CHAT | Chat View (multi-speaker diarization) | complete |
| WP-FILES | File Manager (browse, search, import) | complete |

### Beta Phase

| Work Package | Description | Status |
|--------------|-------------|--------|
| [WP-LATENCY-MOBILE](WP-LATENCY-MOBILE.md) | Latency optimization (<2s speech-to-text) | ready |
| (TBD) | Background recording enhancements | planned |
| (TBD) | Export functionality (TXT, VTT, JSON) | planned |
| WP-SETTINGS | Settings screen | complete (2026-01-31) |

### Release Phase

| Work Package | Description | Status |
|--------------|-------------|--------|
| (TBD) | Performance optimization | planned |
| (TBD) | Accessibility audit | planned |
| (TBD) | App Store submission | planned |

---

## Priority Matrix

### Must Complete for MVP

- WP-SETUP (critical, blocks everything)
- WP-AUDIO (critical, recording/playback)
- WP-STATE (high, state management)
- WP-NAV (high, navigation)
- WP-NOTE (high, primary view)
- WP-CHAT (high, secondary view)
- WP-FILES (high, file management)

### Implementation Order

The recommended implementation order based on dependencies:

```
Phase 1 (Foundation):
  └── WP-SETUP ──────────────────────────────────────────┐
                                                          │
Phase 2 (Core Services):                                  │
  ├── WP-AUDIO ◀──────────────────────────────────────────┤
  ├── WP-STATE ◀──────────────────────────────────────────┤
  └── WP-NAV ◀────────────────────────────────────────────┘
                    │
Phase 3 (Views):    │
  ├── WP-NOTE ◀─────┤
  ├── WP-CHAT ◀─────┤
  └── WP-FILES ◀────┘
```

---

## Quick Links

| Work Package | Interface Contract | Key Files |
|--------------|-------------------|-----------|
| [WP-SETUP](WP-SETUP.md) | Project structure, pubspec.yaml | `lib/main.dart`, `lib/app.dart` |
| [WP-AUDIO](WP-AUDIO.md) | AudioCaptureService, TTSPlaybackService | `lib/services/audio_*.dart` |
| [WP-STATE](WP-STATE.md) | Riverpod providers and notifiers | `lib/providers/`, `lib/features/*/providers/` |
| [WP-NAV](WP-NAV.md) | GoRouter configuration | `lib/core/router/app_router.dart` |
| [WP-NOTE](WP-NOTE.md) | NoteScreen widgets | `lib/features/note/` |
| [WP-CHAT](WP-CHAT.md) | ChatScreen widgets | `lib/features/chat/` |
| [WP-FILES](WP-FILES.md) | FilesScreen widgets | `lib/features/files/` |

---

## Dependency Graph

```
                           ┌──────────────────────────────────────────────────────────┐
                           │                      WP-SETUP                            │
                           │             Flutter Project Setup                        │
                           │                    (critical)                            │
                           └────────────┬────────────────────────┬───────────────────┘
                                        │                        │
              ┌─────────────────────────┼────────────────────────┼────────────────────┐
              │                         │                        │                    │
              ▼                         ▼                        ▼                    │
     ┌─────────────────┐      ┌─────────────────┐      ┌──────────────────┐          │
     │   WP-AUDIO      │      │   WP-STATE      │      │    WP-NAV        │          │
     │ Audio Capture   │      │   Riverpod      │      │   GoRouter       │          │
     │   Playback      │      │   Providers     │      │   Navigation     │          │
     │   (critical)    │      │    (high)       │      │     (high)       │          │
     └────────┬────────┘      └────────┬────────┘      └────────┬─────────┘          │
              │                        │                        │                    │
              │                        │                        │                    │
              └────────────────────────┴────────────────────────┘                    │
                                       │                                             │
              ┌────────────────────────┼─────────────────────────────────┐           │
              │                        │                                 │           │
              ▼                        ▼                                 ▼           │
     ┌─────────────────┐      ┌─────────────────┐             ┌─────────────────┐   │
     │   WP-NOTE       │      │   WP-CHAT       │             │   WP-FILES      │   │
     │   Note View     │      │   Chat View     │             │  File Manager   │   │
     │    (high)       │      │    (high)       │             │    (high)       │   │
     └─────────────────┘      └─────────────────┘             └─────────────────┘   │
```

---

## Creating New Work Packages

Work packages should follow the template:

```markdown
---
id: WP-XXX
type: work-plan
status: ready
phase: mvp
created: YYYY-MM-DD
updated: YYYY-MM-DD
author: design-lead
consumers: [developer]
depends-on: [WP-YYY]
blocks: [WP-ZZZ]
priority: high
tags: [tag1, tag2]
---

# WP-XXX: Title

## Overview
Brief description

## Scope
What's included/excluded

## Interface Contract
Code signatures and types

## Acceptance Criteria
Measurable completion criteria

## Dependencies
What this needs/blocks

## Files to Create
Key files to modify/create

## Research References
Related R-XXX documents
```

---

*Last updated: 2026-01-30*
