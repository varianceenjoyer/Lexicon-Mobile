---
type: index
updated: 2026-01-29
---

# Research Index

> Technical research for Lexicon Mobile. **All 9 research plans are complete.**

---

## Summary

All feasibility research has been completed. The project is ready to proceed with implementation.

**Key Reference:** [Lexicon Local Server Roadmap](~/projects/Lexicon-Local-Server/.dev/design/roadmap.md)

---

## Complete (Provided by Lexicon Local Server)

These areas are implemented in Lexicon Local Server. Mobile client consumes the APIs.

| Plan | Local Server WP | Status | Recommendation |
|------|-----------------|--------|----------------|
| [R-FFI-01](R-FFI-01-uniffi-integration.md) | WP-FFI | ✅ Complete | GO - Use provided bindings |
| [R-ML-01](R-ML-01-ondevice-resource-constraints.md) | WP-MODEL | ✅ Complete | GO - Models managed by Core |
| [R-DIAR-01](R-DIAR-01-diarization-system.md) | WP-STT | ✅ Complete | GO - Diarization via API |
| [R-CORE-01](R-CORE-01-lexicon-core-dependency.md) | WP-FFI, WP-ANDROID | ✅ Complete | GO - Builds working |

---

## Complete (Mobile-Specific)

These areas required mobile-specific research and have been completed with recommendations.

| Plan | Focus | Status | Recommendation |
|------|-------|--------|----------------|
| [R-AUDIO-01](R-AUDIO-01-realtime-audio-pipeline.md) | Audio interruptions | ✅ Complete | `.playAndRecord` / `AUDIOFOCUS_GAIN` |
| [R-PLAT-01](R-PLAT-01-platform-version-constraints.md) | Platform versions | ✅ Complete | iOS 14+, API 26, Compose 1.5+ |
| [R-TTS-01](R-TTS-01-tts-pipeline.md) | TTS playback | ✅ Complete | AVAudioEngine / ExoPlayer |
| [R-DIST-01](R-DIST-01-build-distribution.md) | App store | ✅ Complete | ~25MB, "Data Not Collected" |

---

## Cross-Platform Alternative

| Plan | Focus | Status | Recommendation |
|------|-------|--------|----------------|
| [R-FLUTTER-01](R-FLUTTER-01-cross-platform-viability.md) | Flutter viability | ✅ Complete | CONDITIONAL GO — prototype needed |

**Key Finding**: `flutter_rust_bridge` supports all required FFI patterns (StreamSink for streaming, zero-copy arrays). Thermal APIs available via `thermal` package. Audio latency validation requires prototype.

---

## Key Findings Summary

### Platform Targets (Confirmed)
| Platform | Minimum | Coverage | Rationale |
|----------|---------|----------|-----------|
| iOS | 14.0 | ~95% | SwiftUI features (LazyVStack, @StateObject) |
| Android | API 26 | 94.8% | Per project.md, good coverage |
| Compose | 1.5+ | N/A | Material 3, modern features |

### Implementation Guidance

**Audio Recording:**
- iOS: Use `.playAndRecord` category with `.measurement` mode
- Android: Use `AUDIOFOCUS_GAIN` with `CONTENT_TYPE_SPEECH`
- Both: Support background recording from v1

**TTS Playback:**
- iOS: AVAudioEngine with buffer scheduling
- Android: ExoPlayer/Media3 with temp file approach
- MVP: On-demand synthesis, no caching

**App Store:**
- Binary size: ~25MB (models download on first launch)
- Privacy: "Data Not Collected" label
- All licenses commercially compatible

**Flutter Alternative (if chosen):**
- FFI: `flutter_rust_bridge` with StreamSink for streaming
- Audio: `record` or `flutter_voice_processor` plugins
- Thermal: `thermal` package wraps platform APIs
- Condition: Prototype validation of audio latency required

---

## Research Template

For future research, use this format:

```markdown
---
id: R-XXX-NN
type: research
status: complete
created: YYYY-MM-DD
updated: YYYY-MM-DD
author: design-lead
category: Category
tags: []
scope: mobile-specific
---

# R-XXX-NN: Title

## Summary
One-paragraph summary of findings.

## Research Findings
Detailed findings with code examples where applicable.

## Recommendation
GO | NO-GO | CONDITIONAL with rationale.
```

---

## Archived

(None - all research is current)
