# Research

## Status Summary (Updated 2026-01-29)

**All research plans are now complete.**

| Plan | Status | Key Finding |
|------|--------|-------------|
| [R-FFI-01](R-FFI-01-uniffi-integration.md) | complete | Provided by Local Server WP-FFI |
| [R-ML-01](R-ML-01-ondevice-resource-constraints.md) | complete | Provided by Local Server WP-MODEL |
| [R-DIAR-01](R-DIAR-01-diarization-system.md) | complete | Provided by Local Server WP-STT |
| [R-CORE-01](R-CORE-01-lexicon-core-dependency.md) | complete | Provided by Local Server (FFI, builds working) |
| [R-AUDIO-01](R-AUDIO-01-realtime-audio-pipeline.md) | complete | Use AVAudioSession (iOS) / AudioFocus (Android) |
| [R-PLAT-01](R-PLAT-01-platform-version-constraints.md) | complete | iOS 14+, API 26, Compose 1.5+ |
| [R-TTS-01](R-TTS-01-tts-pipeline.md) | complete | AVAudioEngine (iOS) / ExoPlayer (Android) |
| [R-DIST-01](R-DIST-01-build-distribution.md) | complete | ~25MB app, models download on first launch |

---

## Complete (Provided by Lexicon Local Server)

These research areas are handled by Lexicon Local Server. Mobile client consumes the provided APIs.

- **[R-FFI-01](R-FFI-01-uniffi-integration.md)** — UniFFI bindings complete (WP-FFI ✅)
- **[R-ML-01](R-ML-01-ondevice-resource-constraints.md)** — Model management complete (WP-MODEL ✅)
- **[R-DIAR-01](R-DIAR-01-diarization-system.md)** — Diarization in progress (WP-STT 🔄)
- **[R-CORE-01](R-CORE-01-lexicon-core-dependency.md)** — API exists, Android builds working (WP-FFI ✅, WP-ANDROID 🔄)

## Complete (Mobile-Specific)

These research areas were specific to mobile platform integration.

- **[R-AUDIO-01](R-AUDIO-01-realtime-audio-pipeline.md)** — iOS/Android audio interruption handling
  - **Recommendation:** Use `.playAndRecord` (iOS), `AUDIOFOCUS_GAIN` (Android)
  - Support background recording via BGMode (iOS) / Foreground Service (Android)

- **[R-PLAT-01](R-PLAT-01-platform-version-constraints.md)** — SwiftUI/Compose version requirements
  - **Recommendation:** iOS 14.0 minimum (~95% coverage), API 26 minimum (94.8% coverage)
  - Use Compose BOM 2024.01.00+ for Material 3

- **[R-TTS-01](R-TTS-01-tts-pipeline.md)** — Platform audio playback integration
  - **Recommendation:** AVAudioEngine (iOS), ExoPlayer/Media3 (Android)
  - MVP: On-demand synthesis, temp file playback

- **[R-DIST-01](R-DIST-01-build-distribution.md)** — App store compliance
  - **Recommendation:** All clear for submission
  - App binary ~25MB (models download on first launch)
  - Privacy: "Data Not Collected" (on-device processing)

## Summary of Recommendations

### Platform Targets
| Platform | Minimum Version | Coverage |
|----------|-----------------|----------|
| iOS | 14.0 | ~95% |
| Android | API 26 | 94.8% |
| Compose | 1.5+ (BOM 2024.01.00) | N/A |

### Key Implementation Decisions
1. **Audio Interruptions:** Don't deactivate session on interrupt; check shouldResume before auto-resume
2. **TTS Playback:** Start with temp file approach (MVP), add caching in v2
3. **Background Recording:** Support from v1 (user expectation for recording apps)
4. **First-Launch:** Show download progress UI while Lexicon Core downloads models
5. **App Store:** "Data Not Collected" privacy label (all processing on-device)

## Remaining Research Items

All feasibility research is complete. Ready to proceed with implementation.
