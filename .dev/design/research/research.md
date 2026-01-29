# Research

## Status Summary (Updated 2026-01-29)

| Plan | Status | Key Finding |
|------|--------|-------------|
| [R-FFI-01](R-FFI-01-uniffi-integration.md) | complete | Provided by Local Server WP-FFI |
| [R-ML-01](R-ML-01-ondevice-resource-constraints.md) | complete | Provided by Local Server WP-MODEL |
| [R-DIAR-01](R-DIAR-01-diarization-system.md) | complete | Provided by Local Server WP-STT |
| [R-CORE-01](R-CORE-01-lexicon-core-dependency.md) | complete | Provided by Local Server (FFI, builds working) |
| [R-AUDIO-01](R-AUDIO-01-realtime-audio-pipeline.md) | in-progress | Mobile-specific: interruption handling |
| [R-PLAT-01](R-PLAT-01-platform-version-constraints.md) | in-progress | Mobile-specific: SwiftUI/Compose versions |
| [R-TTS-01](R-TTS-01-tts-pipeline.md) | in-progress | Mobile-specific: playback integration |
| [R-DIST-01](R-DIST-01-build-distribution.md) | in-progress | Mobile-specific: app store compliance |

---

## Complete (Provided by Lexicon Local Server)

These research areas are handled by Lexicon Local Server. Mobile client consumes the provided APIs.

- **[R-FFI-01](R-FFI-01-uniffi-integration.md)** — UniFFI bindings complete (WP-FFI ✅)
- **[R-ML-01](R-ML-01-ondevice-resource-constraints.md)** — Model management complete (WP-MODEL ✅)
- **[R-DIAR-01](R-DIAR-01-diarization-system.md)** — Diarization in progress (WP-STT 🔄)
- **[R-CORE-01](R-CORE-01-lexicon-core-dependency.md)** — API exists, Android builds working (WP-FFI ✅, WP-ANDROID 🔄)

## In Progress (Mobile-Specific)

These research areas are specific to mobile platform integration and cannot be handled by the Local Server.

- **[R-AUDIO-01](R-AUDIO-01-realtime-audio-pipeline.md)** — iOS/Android audio interruption handling
- **[R-PLAT-01](R-PLAT-01-platform-version-constraints.md)** — SwiftUI/Compose version requirements
- **[R-TTS-01](R-TTS-01-tts-pipeline.md)** — Platform audio playback integration, regeneration UX
- **[R-DIST-01](R-DIST-01-build-distribution.md)** — App store compliance, first-launch UX

## Remaining Research Items

All feasibility considerations have been addressed:
- 4 provided by Lexicon Local Server (complete)
- 4 mobile-specific items remain (in progress)
