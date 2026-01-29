# Lexicon Mobile System Architecture

> **Status**: Draft v2.0 | **Last Updated**: 2026-01-29
>
> This document is the authoritative architectural blueprint for Lexicon Mobile. All implementation decisions should reference this document.

---

## Executive Summary

Lexicon Mobile is a **Flutter-based cross-platform application** providing real-time speech transcription, diarized conversation capture, and transcription file management. The application acts as a **thin client** to Lexicon Core (an embedded Rust library), delegating all ML inference, storage, and audio processing to the core library via FFI.

**Key Architectural Decisions**:
1. **Flutter over Native** — Single Dart codebase for iOS and Android reduces maintenance burden by ~50%
2. **flutter_rust_bridge for FFI** — Mature library (5.1k stars, Flutter Favorite) with StreamSink for streaming callbacks
3. **Thin client pattern** — Mobile code handles UI and platform audio; Lexicon Core handles everything else

**Prerequisite**: Validate audio capture latency (<100ms) with prototype before full implementation commitment.

---

## System Boundaries

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         MOBILE APPLICATION LAYER                             │
│                     (This Project's Responsibility)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         UI LAYER (Flutter/Dart)                      │   │
│  │  • Widget rendering         • Navigation             • Accessibility │   │
│  │  • State management         • User input             • Animations    │   │
│  │  • Material 3 theming       • Platform-adaptive UI                   │   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │                                       │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                      PLATFORM PLUGINS LAYER                          │   │
│  │  • record (audio capture)   • thermal (thermal state)                │   │
│  │  • permission_handler       • flutter_foreground_task                │   │
│  │  • file_picker              • just_audio (playback)                  │   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │                                       │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                        FFI BRIDGE LAYER                              │   │
│  │  • flutter_rust_bridge          • StreamSink for callbacks           │   │
│  │  • Zero-copy array transfer     • Async/await support                │   │
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
| iOS | 12.0+ | Flutter | ~99% | Flutter minimum |
| Android | API 21+ | Flutter | ~99% | Flutter minimum |
| **Effective** | iOS 14+ / API 26+ | Flutter | ~95% | Per device capability for ML |

> **Note**: Flutter supports iOS 12+ and API 21+, but Lexicon Core's ML models may require newer devices for acceptable performance. The app will run on older devices but may show degraded STT latency.

### Technology Stack

| Layer | Technology | Notes |
|-------|------------|-------|
| **UI Framework** | Flutter 3.x + Dart | Single codebase for iOS/Android |
| **UI Components** | Material 3 | Platform-adaptive theming |
| **State Management** | Riverpod or flutter_bloc | Reactive state with streams |
| **Audio Capture** | `record` plugin | Real-time streaming to Rust |
| **Audio Playback** | `just_audio` | Buffer scheduling, streaming |
| **Thermal Monitoring** | `thermal` plugin | Wraps platform APIs |
| **FFI Bindings** | flutter_rust_bridge v2 | StreamSink, zero-copy arrays |
| **Core Library** | liblex.so / liblex.a | Rust via FFI |
| **Storage** | — | SQLite (via Lexicon Core) |
| **ML Runtime** | — | ONNX Runtime (via Lexicon Core) |

### Key Framework Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Cross-platform | Flutter (not native) | 1 codebase vs 2, ~50% less maintenance |
| FFI | flutter_rust_bridge (not UniFFI) | Dart bindings, StreamSink for streaming, 5.1k stars |
| State | Riverpod or bloc | Dart-native reactive patterns |
| Audio Capture | `record` plugin | Stream API for real-time capture |
| Audio Playback | `just_audio` | Proven Flutter audio solution |
| Thermal | `thermal` plugin | No platform channels needed |
| Storage | Lexicon Core SQLite | Single source of truth, FTS5 search |

### Why Flutter Over Native?

| Factor | Native (SwiftUI + Compose) | Flutter | Winner |
|--------|---------------------------|---------|--------|
| **Codebases to maintain** | 2 | 1 | Flutter |
| **Languages to learn** | Swift + Kotlin + Rust | Dart + Rust | Flutter |
| **UI consistency** | Manual alignment | Automatic | Flutter |
| **FFI tool** | UniFFI (proven) | flutter_rust_bridge (mature) | Tie |
| **Native feel** | 100% | ~95% | Native |
| **Long-term maintenance** | Higher effort | Lower effort | Flutter |
| **Hot reload** | Limited | Full | Flutter |

**Decision**: The maintenance burden reduction outweighs the ~5% native feel difference. Flutter is the recommended approach.

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

### Flutter Application Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         FLUTTER APPLICATION                                  │
│                      (Single Codebase: iOS + Android)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                          SCREENS (Flutter Widgets)                   │   │
│  │  NoteScreen      ChatScreen      FileManagerScreen      SettingsScreen│   │
│  │  • Material 3 theming           • Platform-adaptive UI               │   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │ watch() / ref.read()                  │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                       STATE MANAGEMENT (Riverpod)                    │   │
│  │  NoteNotifier    ChatNotifier    FileManagerNotifier                 │   │
│  │  • StateNotifier / AsyncNotifier • Stream subscriptions             │   │
│  │  • Action handlers               • Error handling                    │   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │                                       │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                          SERVICES (Dart)                             │   │
│  │  AudioCaptureService    TTSPlaybackService    LexiconCoreService    │   │
│  │  • record plugin        • just_audio          • FFI wrapper         │   │
│  │  • Stream<Uint8List>    • Buffer scheduling   • StreamSink callbacks│   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │                                       │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                     PLATFORM PLUGINS                                 │   │
│  │  thermal             permission_handler     flutter_foreground_task │   │
│  │  • Thermal state     • Mic permission       • Background recording  │   │
│  └───────────────────────────────────┬─────────────────────────────────┘   │
│                                      │                                       │
│  ┌───────────────────────────────────┴─────────────────────────────────┐   │
│  │                     LEXICON CORE (flutter_rust_bridge)               │   │
│  │  import 'package:lexicon_core/lexicon_core.dart';                   │   │
│  │  • createSession()  • processAudio()  • synthesizeSpeech()          │   │
│  │  • StreamSink<Segment> for callbacks  • Zero-copy Float32List       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Flutter Packages

| Package | Purpose | Replaces (Native) |
|---------|---------|-------------------|
| `flutter_rust_bridge` | Rust FFI with StreamSink | UniFFI Swift/Kotlin |
| `record` | Audio capture with streaming | AVAudioEngine / AudioRecord |
| `just_audio` | Audio playback | AVAudioPlayerNode / ExoPlayer |
| `thermal` | Thermal state monitoring | ProcessInfo / PowerManager |
| `permission_handler` | Runtime permissions | Platform-specific |
| `flutter_foreground_task` | Background recording | Foreground Service |
| `riverpod` | State management | Combine / Flow |
| `go_router` | Navigation | NavigationStack / NavHost |

---

## View Architecture

### View Overview

| View | Purpose | Key Components | Lexicon Core APIs |
|------|---------|----------------|-------------------|
| **Note View** | Single-speaker transcription | Text area, TTS player, mic control | `startTranscription(diarization: false)`, `synthesizeSpeech()` |
| **Chat View** | Multi-speaker diarized capture | Chat bubbles, speaker colors | `startTranscription(diarization: true)` |
| **File Manager** | Browse, search, import files | File list, preview pane, search | `listSessions()`, `searchTranscriptions()`, `importAudioFile()` |

### Note View State Machine

```
┌────────────────────────────────────────────────────────────────────────────┐
│                           NOTE VIEW STATES                                  │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   [Idle] ──(mic tap)──▶ [Recording] ──(stop tap)──▶ [Processing]          │
│     ▲                        │                            │                │
│     │                   (pause tap)                  (TTS ready)           │
│     │                        ▼                            ▼                │
│     │                   [Paused] ◀────────────────── [Playback Ready]     │
│     │                                                      │               │
│     │                                                 (play tap)           │
│     │                                                      ▼               │
│     └──────────────────────────────────────────────── [Playing]           │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

### Chat View Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CHAT VIEW DATA FLOW                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   [Mic] → [Lexicon Core (diarization: true)] → [Segment with speaker_id]   │
│                                                          │                   │
│                                                          ▼                   │
│                                                 ┌─────────────────┐         │
│                                                 │  speaker_id % 2 │         │
│                                                 └────────┬────────┘         │
│                                                          │                   │
│                                    ┌─────────────────────┼─────────────────┐│
│                                    │                     │                 ││
│                                    ▼                     ▼                 ││
│                            ┌─────────────┐       ┌─────────────┐          ││
│                            │  Left (0)   │       │  Right (1)  │          ││
│                            │  Blue bubble│       │ Green bubble│          ││
│                            └─────────────┘       └─────────────┘          ││
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### File Manager Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      FILE MANAGER OPERATIONS                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────┐                                                        │
│  │   File List     │◀──── listSessions() ────── [Lexicon Core SQLite]      │
│  │   (LazyColumn/  │                                                        │
│  │    LazyVStack)  │                                                        │
│  └────────┬────────┘                                                        │
│           │                                                                  │
│      [Select]                                                                │
│           │                                                                  │
│           ▼                                                                  │
│  ┌─────────────────┐                                                        │
│  │  Preview Pane   │◀──── getSession() ──────── [Lexicon Core SQLite]      │
│  │  (metadata +    │                                                        │
│  │   text preview) │                                                        │
│  └─────────────────┘                                                        │
│                                                                              │
│  ┌─────────────────┐                                                        │
│  │  Search Bar     │──── searchTranscriptions() ─▶ [FTS5 Full-Text Search] │
│  └─────────────────┘                                                        │
│                                                                              │
│  ┌─────────────────┐     ┌─────────────────────────────────────────────┐   │
│  │  Import Button  │────▶│  importAudioFile(path, callback) → Progress │   │
│  └─────────────────┘     │  • Progress callback updates UI              │   │
│                          │  • Cancel via cancelImport()                 │   │
│                          └─────────────────────────────────────────────┘   │
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

## Audio Configuration

### Flutter Audio Capture (`record` plugin)

```dart
import 'package:record/record.dart';

class AudioCaptureService {
  final _recorder = AudioRecorder();

  Future<Stream<Uint8List>> startRecording() async {
    // Check and request permission
    if (!await _recorder.hasPermission()) {
      throw PermissionDeniedException();
    }

    // Start streaming audio at 16kHz mono (Whisper-compatible)
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    return stream;
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
  }
}
```

### Flutter Audio Playback (`just_audio`)

```dart
import 'package:just_audio/just_audio.dart';

class TTSPlaybackService {
  final _player = AudioPlayer();

  Future<void> playPCMStream(Stream<Uint8List> audioStream) async {
    // Create a StreamAudioSource from TTS output
    final source = StreamAudioSource(audioStream);
    await _player.setAudioSource(source);
    await _player.play();
  }

  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);
}
```

### Background Recording

```dart
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// Android: Uses foreground service with FOREGROUND_SERVICE_TYPE_MICROPHONE
// iOS: Uses UIBackgroundModes: audio (configured in Info.plist)

Future<void> startBackgroundRecording() async {
  await FlutterForegroundTask.startService(
    notificationTitle: 'Lexicon Recording',
    notificationText: 'Recording in progress...',
  );
}
```

### Platform Configuration Files

**iOS (Info.plist)**:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Lexicon uses the microphone to transcribe speech.</string>
<key>UIBackgroundModes</key>
<array><string>audio</string></array>
```

**Android (AndroidManifest.xml)**:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
```

---

## FFI Interface Contract

The mobile app consumes Lexicon Core via `flutter_rust_bridge`-generated bindings. Key API surface:

### Session Management

```rust
// Create/manage transcription sessions
fn create_session(config: SessionConfig) -> Result<SessionId, LexiconError>
fn get_session(id: SessionId) -> Result<Session, LexiconError>
fn list_sessions() -> Result<Vec<SessionSummary>, LexiconError>
fn delete_session(id: SessionId) -> Result<(), LexiconError>
fn rename_session(id: SessionId, title: String) -> Result<(), LexiconError>
```

### STT Operations

```rust
// Real-time transcription with streaming callbacks
fn start_transcription(
    session_id: SessionId,
    config: TranscriptionConfig  // { diarization: bool, language: Option<String> }
) -> Result<TranscriptionHandle, LexiconError>

fn process_audio(
    handle: TranscriptionHandle,
    samples: Vec<f32>  // Raw audio samples
) -> Result<Vec<Segment>, LexiconError>  // Returns new segments

fn stop_transcription(handle: TranscriptionHandle) -> Result<(), LexiconError>
fn cancel_transcription(handle: TranscriptionHandle) -> Result<(), LexiconError>
```

### TTS Operations

```rust
// Speech synthesis with streaming audio output
fn synthesize_speech(
    text: String,
    voice_id: Option<String>
) -> Result<AudioStream, LexiconError>  // Streams PCM chunks via callback

fn cancel_synthesis(stream: AudioStream) -> Result<(), LexiconError>
```

### File Import

```rust
// Import external audio files with progress reporting
fn import_audio_file(
    path: String,
    config: TranscriptionConfig,
    callback: ProgressCallback  // Reports progress percentage
) -> Result<SessionId, LexiconError>

fn cancel_import(session_id: SessionId) -> Result<(), LexiconError>
```

### Search

```rust
// Full-text search via FTS5
fn search_transcriptions(query: String) -> Result<Vec<SearchResult>, LexiconError>
```

### Data Types

```rust
struct Segment {
    id: String,
    speaker_id: Option<i32>,  // None for non-diarized
    text: String,
    start_ms: i64,
    end_ms: i64,
    confidence: Option<f32>,
}

struct SessionConfig {
    title: Option<String>,
    view_type: ViewType,  // Note | Chat
}

struct TranscriptionConfig {
    diarization: bool,
    language: Option<String>,
    translate_to_english: bool,
}
```

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
| Flutter `record` plugin latency >100ms | High | Low | Prototype validation before full implementation; native fallback available |
| STT latency exceeds 800ms on low-end devices | High | Medium | Lexicon Core tiers models by device capability |
| iOS background recording rejected by Apple | High | Low | Follow Apple guidelines; justify in review notes |
| flutter_rust_bridge breaking changes | Medium | Low | Pin versions; v2.x is stable |
| Model download fails on first launch | High | Low | Retry logic; offline mode with degraded UX |
| Thermal throttling degrades experience | Medium | Medium | Lexicon Core auto-downgrades model tier |
| Flutter plugin gaps | Medium | Low | Platform channels for missing APIs; native fallback |

---

## Native Fallback Option

If Flutter proves unsuitable (e.g., audio latency unacceptable after prototype validation), native development remains viable. See [R-FLUTTER-01](research/R-FLUTTER-01-cross-platform-viability.md) for comparison.

| Aspect | Flutter (Primary) | Native (Fallback) |
|--------|-------------------|-------------------|
| Codebases | 1 | 2 (iOS + Android) |
| UI Languages | Dart | Swift + Kotlin |
| FFI Tool | flutter_rust_bridge | UniFFI (already built) |
| Native Feel | ~95% | 100% |
| Maintenance | Lower | Higher |
| Streaming | StreamSink | Callback traits |

### When to Fall Back to Native

Consider switching to native if:
1. **Audio latency prototype fails** — `record` plugin adds >50ms latency
2. **Critical plugin gap** — Required platform API not available via Flutter plugin
3. **Performance issues** — UI jank or memory issues on target devices

### Native Architecture (Reference)

If fallback is needed, use:
- **iOS**: SwiftUI + UniFFI Swift bindings + AVAudioEngine
- **Android**: Jetpack Compose + UniFFI Kotlin bindings + ExoPlayer
- **Shared**: Lexicon Core already has UniFFI bindings from Local Server project

The UniFFI bindings from Lexicon Local Server (WP-FFI) would be used directly.

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
