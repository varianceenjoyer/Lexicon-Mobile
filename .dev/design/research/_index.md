---
type: index
updated: 2026-01-29
---

# Research Index

> Technical research for Lexicon Mobile. 4 items complete (provided by Local Server), 4 mobile-specific items in progress.

---

## Summary

Initial feasibility research revealed that **half of the research areas are handled by Lexicon Local Server**. The remaining research focuses exclusively on mobile platform integration concerns that the Local Server cannot address.

**Key Reference:** [Lexicon Local Server Roadmap](~/projects/Lexicon-Local-Server/.dev/design/roadmap.md)

---

## Complete (Provided by Lexicon Local Server)

These areas are implemented in Lexicon Local Server. Mobile client consumes the APIs.

| Plan | Local Server WP | Status |
|------|-----------------|--------|
| [R-FFI-01](R-FFI-01-uniffi-integration.md) | WP-FFI | ✅ UniFFI bindings complete |
| [R-ML-01](R-ML-01-ondevice-resource-constraints.md) | WP-MODEL | ✅ Device profiling, model selection |
| [R-DIAR-01](R-DIAR-01-diarization-system.md) | WP-STT | 🔄 Diarization in progress |
| [R-CORE-01](R-CORE-01-lexicon-core-dependency.md) | WP-FFI, WP-ANDROID | ✅ API exists, Android working |

---

## In Progress (Mobile-Specific)

These areas require mobile-specific research and implementation.

| Plan | Focus | Scope |
|------|-------|-------|
| [R-AUDIO-01](R-AUDIO-01-realtime-audio-pipeline.md) | Audio interruption handling | iOS AVAudioSession, Android AudioFocus |
| [R-PLAT-01](R-PLAT-01-platform-version-constraints.md) | UI framework versions | SwiftUI iOS 14+, Compose 1.5+ |
| [R-TTS-01](R-TTS-01-tts-pipeline.md) | Playback integration | AVAudioEngine, ExoPlayer, regeneration UX |
| [R-DIST-01](R-DIST-01-build-distribution.md) | App store compliance | Privacy details, Data Safety, licensing |

---

## Research Template

New research should use this format:

```markdown
---
id: R-XXX-NN
type: research
status: complete  # in-progress | complete | superseded
created: YYYY-MM-DD
updated: YYYY-MM-DD
author: design-lead
category: Category
tags: []
scope: mobile-specific  # or provided-by: lexicon-local-server
---

# R-XXX-NN: Title

## Summary
One-paragraph summary of findings.

## Context
Why this research was needed.

## Findings
Detailed findings...

## Recommendation
GO | NO-GO | CONDITIONAL with rationale.

## References
- Links to external resources
```

---

## Archived


