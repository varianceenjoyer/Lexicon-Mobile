---
# PROJECT CONFIGURATION
projectName: Lexicon Mobile
---

# [projectName]

## Project Mission

Provide a cross-platform mobile client for real-time speech transcription, diarized conversation capture, and transcription file management, powered by Lexicon Local Server.

## Project Description

Lexicon Mobile is a native mobile application (iOS/Android) that interfaces with Lexicon Local Server's embedded Rust library via FFI. The app provides three primary views for different transcription workflows:

1. **Note View** — Single-speaker transcription with TTS playback for review
2. **Chat View** — Multi-speaker diarized transcription displayed as a conversation
3. **File Manager View** — Browse, preview, rename, and import transcription files

All speech processing (STT, diarization, TTS) is performed locally on-device via the embedded Lexicon Core library. No cloud connectivity required for core functionality.

## Target Platforms

| Platform | Min Version | Framework | Lexicon Integration |
|----------|-------------|-----------|---------------------|
| iOS | iOS 14+ | SwiftUI | Static lib via UniFFI → Swift |
| Android | API 26+ | Jetpack Compose | Shared lib via UniFFI → Kotlin |

> **Note:** iOS 14+ required for SwiftUI features (LazyVStack, @StateObject, ScrollViewReader). See [R-PLAT-01](design/research/R-PLAT-01-platform-version-constraints.md).

## Implementation Languages

| Component | Language | Rationale |
|-----------|----------|-----------|
| iOS UI | Swift (SwiftUI) | Native iOS development, declarative UI |
| Android UI | Kotlin (Compose) | Native Android development, declarative UI |
| Shared Logic | Rust (via Lexicon Core) | Cross-platform STT/TTS/Storage via FFI |

## Dependencies

### Core (via Lexicon Local Server)
- `lexicon-core` — Embedded Rust library providing STT, TTS, and storage
- `lexicon-ffi` — UniFFI bindings for Swift/Kotlin interop

### iOS-Specific
- SwiftUI — Declarative UI framework
- AVFoundation — Audio capture and playback
- Combine — Reactive data flow

### Android-Specific
- Jetpack Compose — Declarative UI framework
- Media3 (ExoPlayer) — Audio capture and playback
- Kotlin Coroutines + Flow — Reactive data flow

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         LEXICON MOBILE APP                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────────────┐  │
│  │  Note View   │  │  Chat View   │  │       File Manager View          │  │
│  │              │  │              │  │                                  │  │
│  │ • Mic input  │  │ • Mic input  │  │ • File list        • Metadata   │  │
│  │ • Text area  │  │ • Chat UI    │  │ • Preview pane     • Import     │  │
│  │ • TTS player │  │ • Diarized   │  │ • Rename/Delete    • Export     │  │
│  └──────┬───────┘  └──────┬───────┘  └────────────┬─────────────────────┘  │
│         │                 │                       │                         │
│  ┌──────┴─────────────────┴───────────────────────┴──────────────────────┐  │
│  │                    PLATFORM AUDIO LAYER                               │  │
│  │           (AVFoundation on iOS / Media3 on Android)                   │  │
│  └───────────────────────────────┬───────────────────────────────────────┘  │
│                                  │                                          │
│  ┌───────────────────────────────┴───────────────────────────────────────┐  │
│  │                      VIEW MODEL / STATE LAYER                         │  │
│  │              (Combine/SwiftUI State or Kotlin Flow/State)             │  │
│  └───────────────────────────────┬───────────────────────────────────────┘  │
└──────────────────────────────────┼──────────────────────────────────────────┘
                                   │ FFI (UniFFI)
┌──────────────────────────────────┴──────────────────────────────────────────┐
│                         LEXICON CORE LIBRARY                                │
│                              (Embedded Rust)                                │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │     STT      │  │     TTS      │  │   Storage    │  │    Models    │    │
│  │ (whisper-rs) │  │   (Kokoro)   │  │  (rusqlite)  │  │  (verified)  │    │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

## View Specifications

### 1. Note View

**Purpose:** Single-speaker transcription optimized for note-taking, memos, and voice journaling.

**Layout:**
```
┌────────────────────────────────┐
│ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~   │  ← Title/Header (editable)
├────────────────────────────────┤
│                                │
│   Transcription Text Area      │  ← Scrollable, selectable text
│   (live updating during        │
│    recording)                  │
│                                │
├────────────────────────────────┤
│ ▶ ───●────────────── 0:04/0:17 │  ← TTS Playback Controls
├────────────────────────────────┤
│         [  NAV BAR  ]          │  ← Bottom Navigation
└────────────────────────────────┘
```

**Functional Requirements:**

| ID | Requirement | Details |
|----|-------------|---------|
| NV-01 | Mic capture | Capture audio via platform APIs, resample to 16kHz mono |
| NV-02 | STT request | Send audio chunks to Lexicon Core with `diarization: false` |
| NV-03 | Live text update | Append transcribed segments to text area in real-time |
| NV-04 | TTS generation | On stop/pause, send full text to TTS engine |
| NV-05 | TTS buffering | Buffer TTS audio chunks for gapless playback |
| NV-06 | Playback controls | Play/pause, seek via progress slider, time display |
| NV-07 | Auto-save | Save transcription to SQLite on stop or app background |
| NV-08 | Edit support | Allow manual text edits (regenerates TTS on next play) |

**State Machine:**
```
[Idle] ──(mic tap)──▶ [Recording] ──(stop tap)──▶ [Processing]
                           │                            │
                      (pause tap)                  (TTS ready)
                           ▼                            ▼
                      [Paused] ◀────────────────── [Playback Ready]
                                                        │
                                                   (play tap)
                                                        ▼
                                                   [Playing]
```

---

### 2. Chat View

**Purpose:** Multi-speaker conversation capture with visual diarization, resembling a messaging app.

**Layout:**
```
┌────────────────────────────────┐
│ Chat Title                 ... │  ← Header with overflow menu
├────────────────────────────────┤
│                                │
│  ┌──────────────┐              │  ← Speaker 0 (left-aligned)
│  │ Hello, how   │              │
│  │ are you?     │              │
│  └──────────────┘              │
│                                │
│              ┌──────────────┐  │  ← Speaker 1 (right-aligned)
│              │ I'm doing    │  │
│              │ great!       │  │
│              └──────────────┘  │
│                                │
│  ┌──────────────┐              │  ← Speaker 0 continues
│  │ Wonderful... │              │
│  └──────────────┘              │
│                                │
├────────────────────────────────┤
│         [  NAV BAR  ]          │
└────────────────────────────────┘
```

**Functional Requirements:**

| ID | Requirement | Details |
|----|-------------|---------|
| CV-01 | Mic capture | Identical to Note View (16kHz mono) |
| CV-02 | STT request | Send audio chunks with `diarization: true` |
| CV-03 | Speaker alignment | Display segments based on `speaker_id % 2`: left (0), right (1) |
| CV-04 | Live bubbles | Append new chat bubbles as segments arrive |
| CV-05 | Speaker colors | Visually distinguish speakers (color-coded bubbles) |
| CV-06 | Timestamps | Optional: show segment timestamps on long-press |
| CV-07 | Auto-save | Save conversation to SQLite with speaker metadata |
| CV-08 | No TTS | TTS playback not supported (future consideration) |

**Speaker Mapping Logic:**
```
speaker_id │ Alignment │ Visual
───────────┼───────────┼─────────────────
    0      │   Left    │ Blue bubble
    1      │   Right   │ Green bubble
    2      │   Left    │ Blue bubble (same as 0)
    3      │   Right   │ Green bubble (same as 1)
   ...     │   ...     │ Pattern continues
```

**Data Model per Segment:**
```
ChatSegment {
    id: UUID
    speaker_id: Int
    text: String
    start_ms: Int64
    end_ms: Int64
    confidence: Float?
}
```

---

### 3. File Manager View

**Purpose:** Browse, preview, rename, import, and manage saved transcriptions.

**Layout:**
```
┌────────────────────────────────┐
│ ☰ File Manager            🔍   │  ← Hamburger menu + Search
├────────────────────────────────┤
│ ┌────────────┬───────────────┐ │
│ │ File List  │   Preview/    │ │
│ │            │   Metadata    │ │
│ │ Directions │               │ │
│ │ Groceries  │  [Selected    │ │
│ │ Todo_1  ●  │   file info   │ │
│ │ Schedule   │   and text    │ │
│ │ Pricequote │   preview]    │ │
│ │    ...     │               │ │
│ └────────────┴───────────────┘ │
├────────────────────────────────┤
│         [  NAV BAR  ]          │
└────────────────────────────────┘
```

**Hamburger Menu Options:**
- Import Audio File
- Export Selected (SRT/TXT/JSON)
- Settings
- About

**Functional Requirements:**

| ID | Requirement | Details |
|----|-------------|---------|
| FM-01 | File list | Query SQLite for all sessions, display as scrollable list |
| FM-02 | Selection | Tap to select, show metadata + text preview in right pane |
| FM-03 | Rename | Long-press or context menu to rename session |
| FM-04 | Delete | Swipe-to-delete or context menu with confirmation |
| FM-05 | Search | FTS5 full-text search across all transcriptions |
| FM-06 | Sort | Sort by date, name, duration (toggle in header) |
| FM-07 | Open | Double-tap or "Open" button → Note View with loaded file |
| FM-08 | Import | Hamburger → Import → OS file picker → Processing modal |

**Import Audio Flow:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         IMPORT AUDIO WORKFLOW                               │
└─────────────────────────────────────────────────────────────────────────────┘

User taps "Import Audio File" in hamburger menu
                │
                ▼
┌───────────────────────────────┐
│   OS File Picker              │  ← Platform native (Files app / SAF)
│   [Select audio file]         │     Supported: .wav, .mp3, .m4a, .flac, .ogg
└───────────────────────────────┘
                │
          (file selected)
                │
                ▼
┌───────────────────────────────┐
│   Confirmation Dialog         │
│                               │
│   "Import [filename]?"        │
│                               │
│   [Cancel]        [Confirm]   │
└───────────────────────────────┘
                │
            (confirm)
                │
                ▼
┌───────────────────────────────┐
│   Processing Modal            │
│                               │
│      ◠ ◡ ◠  Processing...     │  ← Spinner animation
│                               │
│   Progress: 45%               │  ← Optional progress indicator
│                               │
│   [ OK (disabled) ] [Cancel]  │  ← Cancel = red, stops transcription
└───────────────────────────────┘
                │
       (transcription complete)
                │
                ▼
┌───────────────────────────────┐
│   Completion Modal            │
│                               │
│   ✓ Transcription complete!   │
│                               │
│   Saved as: "Meeting_2026..." │  ← Auto-generated name
│                               │
│   [ OK ]    [ Preview... ]    │  ← Preview opens in Note View
└───────────────────────────────┘
```

**Processing Modal States:**

| State | OK Button | Cancel Button | Behavior |
|-------|-----------|---------------|----------|
| Processing | Disabled (gray) | Enabled (red) | Cancel stops transcription cleanly |
| Complete | Enabled | Hidden or "Preview..." (blue) | OK dismisses, Preview opens file |
| Error | Enabled | Hidden | OK dismisses with error message |

**Cancel Behavior:**
- Immediately signals Lexicon Core to abort transcription
- Partial results are discarded (not saved)
- Modal dismisses, returns to File Manager
- User notified: "Import cancelled"

---

## Navigation Structure

**Bottom Navigation Bar (NAV):**

| Icon | Label | Destination |
|------|-------|-------------|
| 📝 | Note | Note View |
| 💬 | Chat | Chat View |
| 📁 | Files | File Manager View |

**Navigation Rules:**
- Switching views while recording: Prompt to stop/save or discard
- Deep links: Files can open directly into Note/Chat view
- Back navigation: Standard platform behavior (swipe/button)

---

## Data Flow

### Audio Capture → STT Pipeline

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Platform    │    │   Resample   │    │  Lexicon     │    │    View      │
│  Mic API     │───▶│  to 16kHz    │───▶│  Core STT    │───▶│   Update     │
│              │    │              │    │  (FFI call)  │    │              │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
     44.1/48kHz          16kHz           Segments[]         UI State
```

### TTS Pipeline (Note View only)

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│    Text      │    │  Lexicon     │    │   Audio      │    │   Platform   │
│   Content    │───▶│  Core TTS    │───▶│   Buffer     │───▶│   Playback   │
│              │    │  (FFI call)  │    │   Queue      │    │              │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
     String          AudioChunks[]       Ring buffer       AVAudioPlayer/
                                                           ExoPlayer
```

---

## Storage Schema (via Lexicon Core)

Lexicon Mobile uses Lexicon Core's SQLite database. Relevant tables:

```sql
-- Sessions represent individual recordings/transcriptions
sessions (
    id              TEXT PRIMARY KEY,
    title           TEXT NOT NULL,
    created_at      INTEGER NOT NULL,  -- Unix timestamp ms
    updated_at      INTEGER NOT NULL,
    duration_ms     INTEGER,
    source_type     TEXT,              -- 'mic' | 'import'
    view_type       TEXT,              -- 'note' | 'chat'
    metadata        TEXT               -- JSON blob
)

-- Segments are individual transcription chunks
segments (
    id              TEXT PRIMARY KEY,
    session_id      TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    speaker_id      INTEGER,           -- NULL for non-diarized
    text            TEXT NOT NULL,
    start_ms        INTEGER NOT NULL,
    end_ms          INTEGER NOT NULL,
    confidence      REAL,
    created_at      INTEGER NOT NULL
)

-- FTS5 virtual table for full-text search
segments_fts (
    text,
    content='segments',
    content_rowid='rowid'
)
```

---

## FFI Interface (Lexicon Core Bindings)

Expected UniFFI interface used by mobile apps:

```rust
// Session management
fn create_session(config: SessionConfig) -> Result<SessionId, LexiconError>;
fn get_session(id: SessionId) -> Result<Session, LexiconError>;
fn list_sessions() -> Result<Vec<SessionSummary>, LexiconError>;
fn delete_session(id: SessionId) -> Result<(), LexiconError>;
fn rename_session(id: SessionId, title: String) -> Result<(), LexiconError>;

// STT operations
fn start_transcription(session_id: SessionId, config: TranscriptionConfig) -> Result<TranscriptionHandle, LexiconError>;
fn process_audio(handle: TranscriptionHandle, samples: Vec<f32>) -> Result<Vec<Segment>, LexiconError>;
fn stop_transcription(handle: TranscriptionHandle) -> Result<(), LexiconError>;
fn cancel_transcription(handle: TranscriptionHandle) -> Result<(), LexiconError>;

// TTS operations
fn synthesize_speech(text: String, voice_id: Option<String>) -> Result<AudioStream, LexiconError>;
fn cancel_synthesis(stream: AudioStream) -> Result<(), LexiconError>;

// File import
fn import_audio_file(path: String, config: TranscriptionConfig, callback: ProgressCallback) -> Result<SessionId, LexiconError>;
fn cancel_import(session_id: SessionId) -> Result<(), LexiconError>;

// Search
fn search_transcriptions(query: String) -> Result<Vec<SearchResult>, LexiconError>;

// Configuration structs
struct SessionConfig {
    title: Option<String>,
    view_type: ViewType,  // Note | Chat
}

struct TranscriptionConfig {
    diarization: bool,
    language: Option<String>,
    translate_to_english: bool,
}

enum ViewType {
    Note,
    Chat,
}
```

---

## Error Handling

### User-Facing Errors

| Error Type | User Message | Recovery Action |
|------------|--------------|-----------------|
| Mic permission denied | "Microphone access required" | Open Settings button |
| Model not loaded | "Loading speech model..." | Show progress, block recording |
| Storage full | "Not enough storage space" | Suggest deleting old files |
| Import failed | "Could not read audio file" | Return to file picker |
| Transcription failed | "Transcription error occurred" | Option to retry |

### Error Display Patterns

- **Toast/Snackbar:** Transient errors (network timeout, minor failures)
- **Modal Dialog:** Blocking errors requiring user action
- **Inline:** Validation errors (empty title, invalid file)

---

## Performance Requirements

| Metric | Target | Measurement |
|--------|--------|-------------|
| App launch to ready | <2s | Cold start to Note View ready |
| Recording start latency | <100ms | Mic tap to capture begin |
| STT segment latency | <800ms | Speech end to text display (base model) |
| TTS first audio | <300ms | Play tap to audio output |
| File list load | <200ms | View switch to list rendered |
| Search results | <100ms | Query to results displayed |

---

## Accessibility Requirements

| Feature | iOS | Android |
|---------|-----|---------|
| VoiceOver/TalkBack | Full support | Full support |
| Dynamic Type | Supported | Supported |
| High Contrast | Supported | Supported |
| Reduce Motion | Respect setting | Respect setting |
| Haptic Feedback | Recording start/stop | Recording start/stop |

---

## Testing Strategy

### Unit Tests
- ViewModel state transitions
- Audio buffer management
- Speaker alignment logic (Chat View)
- File name generation

### Integration Tests
- FFI round-trips (Swift/Kotlin ↔ Rust)
- Audio capture → STT → UI update
- Database queries via Lexicon Core

### UI Tests
- Navigation flows
- Recording/playback interactions
- File import workflow
- Error state handling

### Device Testing Matrix

| Device Class | iOS | Android |
|--------------|-----|---------|
| Low-end | iPhone SE 2 | Pixel 4a |
| Mid-range | iPhone 12 | Pixel 7 |
| High-end | iPhone 15 Pro | Pixel 8 Pro |
| Tablet | iPad Air | Galaxy Tab S8 |

---

## Open Questions

1. **Diarization algorithm:** Lexicon Core architecture lists this as "configurable" (Decision D3). Which algorithm will be used for Chat View? (pyannote, whisper clustering, sherpa-onnx)

2. **Speaker labeling:** Should Chat View allow users to assign names to speaker_id values? (e.g., "Speaker 0 = Alice")
    - YES

3. **Export formats:** Which export formats should File Manager support? (SRT, TXT, JSON, VTT)
    - TXT, VTT, JSON
4. **Sync/backup:** Future consideration for cloud backup of transcriptions?

5. **Localization:** Which languages for UI localization? (STT language support is separate)
    - English to start
6. **Tablet layout:** Should tablet devices show master-detail File Manager by default?

---

## Feasibility Considerations

> **Status:** All feasibility research is complete. See [Research Index](design/research/_index.md) for full details.

### Summary of Findings

| Area | Status | Key Decision | Research |
|------|--------|--------------|----------|
| FFI/UniFFI Integration | ✅ GO | Provided by Lexicon Local Server WP-FFI | [R-FFI-01](design/research/R-FFI-01-uniffi-integration.md) |
| On-Device ML | ✅ GO | Models managed by Lexicon Core WP-MODEL | [R-ML-01](design/research/R-ML-01-ondevice-resource-constraints.md) |
| Real-Time Audio | ✅ GO | `.playAndRecord` (iOS), `AUDIOFOCUS_GAIN` (Android) | [R-AUDIO-01](design/research/R-AUDIO-01-realtime-audio-pipeline.md) |
| Diarization | ✅ GO | Provided by Lexicon Local Server WP-STT | [R-DIAR-01](design/research/R-DIAR-01-diarization-system.md) |
| Lexicon Core Dependency | ✅ GO | API exists, builds working | [R-CORE-01](design/research/R-CORE-01-lexicon-core-dependency.md) |
| Platform Versions | ✅ GO | iOS 14+, API 26, Compose 1.5+ | [R-PLAT-01](design/research/R-PLAT-01-platform-version-constraints.md) |
| TTS Pipeline | ✅ GO | AVAudioEngine (iOS), ExoPlayer (Android) | [R-TTS-01](design/research/R-TTS-01-tts-pipeline.md) |
| Build & Distribution | ✅ GO | ~25MB app, "Data Not Collected" privacy | [R-DIST-01](design/research/R-DIST-01-build-distribution.md) |

### Key Implementation Decisions

1. **Audio Interruptions:** Don't deactivate audio session on interrupt; check `shouldResume` before auto-resume
2. **TTS Playback:** Start with temp file approach (MVP), add caching in v2
3. **Background Recording:** Support from v1 (user expectation for recording apps)
4. **First-Launch:** Show download progress UI while Lexicon Core downloads models
5. **App Store:** "Data Not Collected" privacy label (all processing on-device)

### Cross-Platform Alternative: Flutter

A Flutter-based approach was evaluated as an alternative to native iOS/Android development.

| Aspect | Finding |
|--------|---------|
| **Verdict** | CONDITIONAL GO |
| **FFI** | `flutter_rust_bridge` supports StreamSink (equivalent to UniFFI callbacks) |
| **Performance** | Zero-copy array transfer, SSE codec optimized |
| **Maturity** | 5.1k GitHub stars, Flutter Favorite designation |
| **Thermal APIs** | `thermal` package wraps platform APIs (no platform channels needed) |
| **Condition** | Prototype required to validate audio plugin latency (<100ms) |

See [R-FLUTTER-01](design/research/R-FLUTTER-01-cross-platform-viability.md) for full analysis.

**Trade-off Summary:**
- Flutter: 1 codebase, 1 UI language (Dart), ~95% native feel
- Native: 2 codebases, 2 UI languages (Swift/Kotlin), 100% native feel, proven UniFFI path

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0 | 2026-01-27 | — | Initial draft from whiteboard design |
| 0.2.0 | 2026-01-29 | — | Update iOS minimum to 14+; replace feasibility questions with completed research findings |