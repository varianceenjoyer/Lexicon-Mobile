# Work Packages Index

> **Status**: Active | **Last Updated**: 2026-01-29
>
> This index tracks all actionable work packages for Lexicon Mobile.

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
| [WP-SETUP](WP-SETUP.md) | Flutter Project Setup | critical | mvp | none | WP-AUDIO, WP-STATE, WP-NAV |
| [WP-AUDIO](WP-AUDIO.md) | Audio Capture and Playback | critical | mvp | WP-SETUP | WP-NOTE, WP-CHAT |
| [WP-STATE](WP-STATE.md) | State Management (Riverpod) | high | mvp | WP-SETUP | WP-NOTE, WP-CHAT, WP-FILES |
| [WP-NAV](WP-NAV.md) | Navigation and App Shell | high | mvp | WP-SETUP | WP-NOTE, WP-CHAT, WP-FILES |
| [WP-NOTE](WP-NOTE.md) | Note View Implementation | high | mvp | WP-SETUP, WP-AUDIO, WP-STATE, WP-NAV | none |
| [WP-CHAT](WP-CHAT.md) | Chat View Implementation | high | mvp | WP-SETUP, WP-AUDIO, WP-STATE, WP-NAV | none |
| [WP-FILES](WP-FILES.md) | File Manager View | high | mvp | WP-SETUP, WP-STATE, WP-NAV | none |

### In Progress

| ID | Name | Owner | Started | Notes |
|----|------|-------|---------|-------|

### Completed (MVP)

| ID | Name | Completed | Notes |
|----|------|-----------|-------|

---

## Phase Mapping

### MVP Phase

| Work Package | Description | Status |
|--------------|-------------|--------|
| WP-SETUP | Flutter project initialization | ready |
| WP-AUDIO | Audio capture and playback services | ready |
| WP-STATE | Riverpod state management | ready |
| WP-NAV | Navigation and app shell | ready |
| WP-NOTE | Note View (single-speaker transcription + TTS) | ready |
| WP-CHAT | Chat View (multi-speaker diarization) | ready |
| WP-FILES | File Manager (browse, search, import) | ready |

### Beta Phase

| Work Package | Description | Status |
|--------------|-------------|--------|
| (TBD) | Background recording enhancements | planned |
| (TBD) | Export functionality (TXT, VTT, JSON) | planned |
| (TBD) | Settings screen | planned |

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

*Last updated: 2026-01-29*
