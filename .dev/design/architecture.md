# Lexicon Mobile System Architecture

> **Status**: Draft v1.0 | **Last Updated**: 2026-01-29
>
> This document is the authoritative architectural blueprint for Lexicon Mobile. All implementation decisions should reference this document.

---

## Executive Summary

Lexicon Mobile is a native mobile application providing real-time speech transcription, diarized conversation capture, and transcription file management. The application acts as a **thin client** to Lexicon Core (an embedded Rust library), delegating all ML inference, storage, and audio processing to the core library via FFI.

**Key Architectural Principle**: Mobile code handles UI rendering, platform audio capture, and user interaction. Lexicon Core handles everything else.

---

## System Boundaries

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         MOBILE APPLICATION LAYER                             │
│                     (This Project's Responsibility)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         UI LAYER (SwiftUI / Compose)                 │   │
│  │  • View rendering           • Navigation             • Accessibility │   │
│  │  • State management         • User input             • Animations    │   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │                                       │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                      PLATFORM SERVICES LAYER                         │   │
│  │  • Audio Session (iOS)      • Audio Focus (Android)                  │   │
│  │  • Permissions              • Background Tasks                       │   │
│  │  • File Picker              • Notifications                          │   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │                                       │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                        FFI BRIDGE LAYER                              │   │
│  │  • UniFFI Swift Bindings (iOS)    • UniFFI Kotlin Bindings (Android) │   │
│  │  • Callback handling              • Error translation                │   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │                                       │
└──────────────────────────────────────┼──────────────────────────────────────┘
                                       │ FFI Boundary
┌──────────────────────────────────────┴──────────────────────────────────────┐
│                          LEXICON CORE LIBRARY                                │
│                  (Provided by Lexicon Local Server Project)                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │     STT      │  │     TTS      │  │   Storage    │  │    Models    │    │
│  │ (whisper-rs) │  │   (Kokoro)   │  │  (rusqlite)  │  │  (verified)  │    │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                                              │
│  • Audio resampling (16kHz)    • Model selection        • Thermal monitoring│
│  • Diarization                 • Device profiling       • Error handling    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Boundary Definition

| Responsibility | Owner | Rationale |
|----------------|-------|-----------|
| UI Rendering | Mobile | Platform-specific frameworks (SwiftUI, Compose) |
| Audio Capture | Mobile | Platform APIs (AVAudioEngine, AudioRecord) |
| Audio Session Management | Mobile | iOS interruptions, Android focus |
| Permissions | Mobile | Platform permission dialogs |
| Background Recording | Mobile | Foreground service / Background mode |
| Audio Resampling | Lexicon Core | Consistent 16kHz conversion |
| STT Inference | Lexicon Core | Whisper model execution |
| TTS Synthesis | Lexicon Core | Kokoro model execution |
| Diarization | Lexicon Core | Speaker identification |
| Storage (SQLite) | Lexicon Core | Session and segment persistence |
| Model Management | Lexicon Core | Download, verification, selection |
| Thermal Monitoring | Lexicon Core | Model tier adjustment |

---

## Technology Decisions

### Platform Targets

| Platform | Version | Framework | Coverage | Reference |
|----------|---------|-----------|----------|-----------|
| iOS | 14.0+ | SwiftUI | ~95% | [R-PLAT-01](research/R-PLAT-01-platform-version-constraints.md) |
| Android | API 26+ | Jetpack Compose 1.5+ | 94.8% | [R-PLAT-01](research/R-PLAT-01-platform-version-constraints.md) |

### Technology Stack

| Layer | iOS | Android | Shared |
|-------|-----|---------|--------|
| **UI Framework** | SwiftUI | Jetpack Compose (Material 3) | — |
| **State Management** | @StateObject, Combine | ViewModel, Kotlin Flow | — |
| **Audio Capture** | AVAudioEngine | AudioRecord / AAudio | — |
| **Audio Playback** | AVAudioPlayerNode | ExoPlayer (Media3) | — |
| **FFI Bindings** | UniFFI → Swift | UniFFI → Kotlin | UniFFI |
| **Core Library** | liblex.a (static) | liblex.so (shared) | Rust |
| **Storage** | — | — | SQLite (via Lexicon Core) |
| **ML Runtime** | — | — | ONNX Runtime (via Lexicon Core) |

### Key Framework Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| iOS UI | SwiftUI (not UIKit) | Declarative, modern, LazyVStack for chat |
| Android UI | Compose (not XML Views) | Declarative, modern, Material 3 |
| Audio Playback | AVAudioEngine / ExoPlayer | Buffer scheduling, streaming support |
| FFI | UniFFI (not manual C FFI) | Type-safe, generated bindings, async support |
| Storage | Lexicon Core SQLite | Single source of truth, FTS5 search |

---

## Latency Budget

### End-to-End Pipeline Targets

| Operation | Target | Budget Breakdown |
|-----------|--------|------------------|
| **App Launch** | <2s | Cold start to Note View ready |
| **Recording Start** | <100ms | Mic tap → capture begin |
| **STT Segment** | <800ms | Speech end → text display |
| **TTS First Audio** | <300ms | Play tap → audio output |
| **File List Load** | <200ms | View switch → list rendered |
| **Search Results** | <100ms | Query → results displayed |

### STT Pipeline Budget (800ms total)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      STT LATENCY BUDGET (800ms target)                       │
├────────────────┬────────────┬────────────┬────────────┬────────────────────┤
│   Platform     │   FFI      │  Whisper   │   FFI      │      UI            │
│   Audio → FFI  │  Call In   │ Inference  │ Call Out   │    Render          │
├────────────────┼────────────┼────────────┼────────────┼────────────────────┤
│     50ms       │    10ms    │   650ms    │    10ms    │      80ms          │
│                │            │ (model-    │            │                    │
│                │            │ dependent) │            │                    │
└────────────────┴────────────┴────────────┴────────────┴────────────────────┘
```

### TTS Pipeline Budget (300ms to first audio)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    TTS LATENCY BUDGET (300ms target)                         │
├────────────────┬────────────┬────────────┬────────────┬────────────────────┤
│    FFI Call    │  Kokoro    │   FFI      │   Buffer   │    Audio           │
│      In        │ First Chunk│  Call Out  │  Schedule  │   Playback         │
├────────────────┼────────────┼────────────┼────────────┼────────────────────┤
│     10ms       │   200ms    │    10ms    │    50ms    │     30ms           │
└────────────────┴────────────┴────────────┴────────────┴────────────────────┘
```

### Recording Start Budget (100ms)

| Component | Budget | Notes |
|-----------|--------|-------|
| Audio focus request | 20ms | Android only |
| Audio session activation | 30ms | iOS: already active if possible |
| FFI session creation | 20ms | `create_session()` |
| First buffer capture | 30ms | Begin actual recording |

---

## Layer Architecture

### iOS Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              iOS APPLICATION                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                            VIEWS (SwiftUI)                           │   │
│  │  NoteView        ChatView        FileManagerView        SettingsView │   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │ @StateObject                         │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                         VIEW MODELS                                  │   │
│  │  NoteViewModel   ChatViewModel   FileManagerViewModel                │   │
│  │  • @Published state              • Combine pipelines                 │   │
│  │  • Action handlers               • Error handling                    │   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │                                       │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                          SERVICES                                    │   │
│  │  AudioSessionManager    TTSPlaybackManager    LexiconCoreService    │   │
│  │  • AVAudioSession       • AVAudioEngine       • FFI wrapper         │   │
│  │  • Interruption handling• Buffer scheduling   • Async callbacks     │   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │                                       │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                     LEXICON CORE (UniFFI Swift)                      │   │
│  │  import LexiconCore                                                  │   │
│  │  • createSession()  • processAudio()  • synthesizeSpeech()          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Android Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            ANDROID APPLICATION                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         COMPOSABLES (Jetpack Compose)                │   │
│  │  NoteScreen      ChatScreen      FileManagerScreen      SettingsScreen│   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │ collectAsState()                      │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                          VIEW MODELS                                 │   │
│  │  NoteViewModel   ChatViewModel   FileManagerViewModel                │   │
│  │  • StateFlow     • Coroutines    • Error handling                   │   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │                                       │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                          SERVICES                                    │   │
│  │  AudioFocusManager    TTSPlaybackManager    LexiconCoreService      │   │
│  │  • AudioManager       • ExoPlayer           • FFI wrapper           │   │
│  │  • Focus callbacks    • MediaSession        • Callback bridge       │   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │                                       │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                       FOREGROUND SERVICE                             │   │
│  │  RecordingService                                                    │   │
│  │  • FOREGROUND_SERVICE_TYPE_MICROPHONE                               │   │
│  │  • Persistent notification                                          │   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │                                       │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                     LEXICON CORE (UniFFI Kotlin)                     │   │
│  │  import uniffi.lexicon_core.*                                        │   │
│  │  • createSession()  • processAudio()  • synthesizeSpeech()          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Patterns

### Audio Capture → STT Pipeline

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        AUDIO CAPTURE → STT DATA FLOW                          │
└──────────────────────────────────────────────────────────────────────────────┘

 MOBILE                                              LEXICON CORE
┌─────────────────────┐                            ┌─────────────────────┐
│  Platform Mic API   │                            │                     │
│  (44.1/48kHz)       │──[raw audio]──────────────▶│   Resampler         │
└─────────────────────┘                            │   (→ 16kHz mono)    │
                                                   └──────────┬──────────┘
                                                              │
                                                   ┌──────────▼──────────┐
                                                   │   Whisper STT       │
                                                   │   (inference)       │
                                                   └──────────┬──────────┘
                                                              │
                                                   ┌──────────▼──────────┐
                                                   │   Diarization       │
                                                   │   (if enabled)      │
                                                   └──────────┬──────────┘
                                                              │
┌─────────────────────┐                            ┌──────────▼──────────┐
│  UI Update          │◀──[Segment callback]───────│   Segment Builder   │
│  (SwiftUI/Compose)  │                            │   {text, speaker,   │
└─────────────────────┘                            │    start_ms, end_ms}│
                                                   └─────────────────────┘
```

### TTS Playback Pipeline

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                          TTS PLAYBACK DATA FLOW                               │
└──────────────────────────────────────────────────────────────────────────────┘

 MOBILE                                              LEXICON CORE
┌─────────────────────┐                            ┌─────────────────────┐
│  User taps Play     │──[text content]───────────▶│   Kokoro TTS        │
│  (full transcript)  │                            │   (synthesis)       │
└─────────────────────┘                            └──────────┬──────────┘
                                                              │
┌─────────────────────┐                            ┌──────────▼──────────┐
│  Audio Buffer Queue │◀──[PCM chunks]─────────────│   Audio Chunks      │
│  (ring buffer)      │   (22050Hz, 16-bit, mono)  │   (streaming)       │
└──────────┬──────────┘                            └─────────────────────┘
           │
┌──────────▼──────────┐
│  Platform Playback  │
│  AVAudioEngine /    │
│  ExoPlayer          │
└─────────────────────┘
```

### Session State Machine

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           RECORDING STATE MACHINE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│    ┌──────┐                                                                 │
│    │ Idle │◀───────────────────────────────────────────────────────────┐   │
│    └──┬───┘                                                            │   │
│       │ [user taps record]                                             │   │
│       │ + request audio focus                                          │   │
│       │ + create session                                               │   │
│       ▼                                                                │   │
│    ┌───────────┐                                                       │   │
│    │ Recording │───────[user taps stop]───────────────────────────────▶│   │
│    └─────┬─────┘                                                       │   │
│          │                                                             │   │
│    [interruption / focus loss]                                         │   │
│          │                                                             │   │
│          ▼                                                             │   │
│    ┌─────────────┐                                                     │   │
│    │ Interrupted │──────[user cancels]────────────────────────────────▶│   │
│    └──────┬──────┘                                                     │   │
│           │                                                            │   │
│     [focus regained / shouldResume]                                    │   │
│           │                                                            │   │
│           ▼                                                            │   │
│    ┌──────────┐                                                        │   │
│    │ Resuming │────────[resume complete]──────▶ Recording              │   │
│    └──────────┘                                                        │   │
│                                                                         │   │
│    Interruption timeout (30s) ──────────────────────────────────────▶ │   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Audio Session Configuration

### iOS (AVAudioSession)

```swift
// Recommended configuration from R-AUDIO-01
try session.setCategory(.playAndRecord,
                        mode: .measurement,
                        options: [.allowBluetooth,
                                 .defaultToSpeaker,
                                 .allowBluetoothA2DP])
```

| Setting | Value | Rationale |
|---------|-------|-----------|
| Category | `.playAndRecord` | Supports both recording and TTS playback |
| Mode | `.measurement` | Highest quality capture |
| Options | `.allowBluetooth` | Bluetooth headset input |
| Options | `.defaultToSpeaker` | Fallback when no headphones |
| Background | `UIBackgroundModes: audio` | Background recording support |

### Android (AudioFocus)

```kotlin
// Recommended configuration from R-AUDIO-01
AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
    .setAudioAttributes(audioAttributes)
    .setAcceptsDelayedFocusGain(true)
    .setOnAudioFocusChangeListener(focusChangeListener)
    .build()
```

| Setting | Value | Rationale |
|---------|-------|-----------|
| Focus Type | `AUDIOFOCUS_GAIN` | Full focus for recording |
| Content Type | `CONTENT_TYPE_SPEECH` | Speech recording optimization |
| Delayed Gain | `true` | Better system integration |
| Service | Foreground + `TYPE_MICROPHONE` | Background recording |

---

## Error Handling Strategy

### Error Categories

| Category | Examples | User Action | Technical Action |
|----------|----------|-------------|------------------|
| **Permissions** | Mic denied | Open Settings | Block recording |
| **Resources** | Storage full | Clear space | Fail gracefully |
| **Transient** | Network timeout | Retry | Exponential backoff |
| **Fatal** | Model corrupt | Reinstall | Re-download models |
| **Interruption** | Phone call | Auto-pause | State preservation |

### Error Translation (FFI → UI)

```
Lexicon Core Error          →    User-Facing Message
────────────────────────────────────────────────────────
LexiconError::ModelNotFound  →   "Loading speech model..."
LexiconError::InferenceFailed→   "Transcription error. Retry?"
LexiconError::StorageFull    →   "Not enough storage space"
LexiconError::Cancelled      →   (silent, user-initiated)
LexiconError::InvalidAudio   →   "Audio format not supported"
```

---

## Build & Distribution

### Binary Composition

| Component | iOS Size | Android Size |
|-----------|----------|--------------|
| App code (UI) | ~10-15 MB | ~8-12 MB |
| Lexicon Core (.a/.so) | ~5-15 MB | ~5-15 MB |
| **Total** | **~20-30 MB** | **~15-25 MB** |
| Models | Downloaded on first launch | Downloaded on first launch |

### App Store Compliance

| Requirement | iOS | Android |
|-------------|-----|---------|
| Privacy Label | "Data Not Collected" | "No data collected" |
| Microphone Usage | Info.plist description | Manifest permission |
| Background Mode | UIBackgroundModes: audio | Foreground Service |
| Target SDK | iOS 14+ | API 34 (targetSdk) |

Reference: [R-DIST-01](research/R-DIST-01-build-distribution.md)

---

## Risk Register

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| STT latency exceeds 800ms on low-end devices | High | Medium | Lexicon Core tiers models by device capability |
| iOS background recording rejected by Apple | High | Low | Follow Apple guidelines; justify in review notes |
| Flutter audio latency unacceptable | Medium | Medium | Prototype validation before Flutter commitment |
| UniFFI breaking changes | Medium | Low | Pin versions; Local Server maintains bindings |
| Model download fails on first launch | High | Low | Retry logic; offline mode with degraded UX |
| Thermal throttling degrades experience | Medium | Medium | Lexicon Core auto-downgrades model tier |

---

## Cross-Platform Alternative: Flutter

Flutter was evaluated as an alternative to native development. See [R-FLUTTER-01](research/R-FLUTTER-01-cross-platform-viability.md).

| Aspect | Native (Current Plan) | Flutter |
|--------|----------------------|---------|
| Codebases | 2 (iOS + Android) | 1 |
| UI Languages | Swift + Kotlin | Dart |
| FFI Tool | UniFFI (proven) | flutter_rust_bridge (viable) |
| Native Feel | 100% | ~95% |
| Streaming Support | UniFFI callbacks | StreamSink |
| Verdict | **Current plan** | CONDITIONAL GO (prototype needed) |

**Decision**: Proceed with native development. Flutter remains a fallback if native maintenance burden becomes unsustainable.

---

## References

### Research Documents
- [R-FFI-01](research/R-FFI-01-uniffi-integration.md) — UniFFI Integration
- [R-ML-01](research/R-ML-01-ondevice-resource-constraints.md) — ML Resource Constraints
- [R-DIAR-01](research/R-DIAR-01-diarization-system.md) — Diarization System
- [R-CORE-01](research/R-CORE-01-lexicon-core-dependency.md) — Lexicon Core Dependency
- [R-AUDIO-01](research/R-AUDIO-01-realtime-audio-pipeline.md) — Audio Pipeline
- [R-PLAT-01](research/R-PLAT-01-platform-version-constraints.md) — Platform Versions
- [R-TTS-01](research/R-TTS-01-tts-pipeline.md) — TTS Pipeline
- [R-DIST-01](research/R-DIST-01-build-distribution.md) — Build & Distribution
- [R-FLUTTER-01](research/R-FLUTTER-01-cross-platform-viability.md) — Flutter Viability

### External Dependencies
- Lexicon Local Server: `~/projects/Lexicon-Local-Server/`
- UniFFI: https://github.com/mozilla/uniffi-rs
- Whisper.cpp: https://github.com/ggerganov/whisper.cpp
- Kokoro TTS: https://github.com/hexgrad/kokoro

---

*This document serves as the source of truth for Lexicon Mobile architecture. Update as design evolves.*
