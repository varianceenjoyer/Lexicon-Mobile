Lexicon Mobile — Codebase Overview

Lexicon Mobile is a Flutter/Dart mobile app for on-device, privacy-first speech transcription — no cloud required. It uses an embedded Rust speech-to-text
engine (NVIDIA Parakeet CTC 0.6B via ONNX Runtime) via FFI (flutter_rust_bridge).

Tech Stack

- Flutter/Dart 3.0+ (iOS & Android)
- Riverpod — state management (StateNotifier pattern)
- GoRouter — declarative navigation with bottom tabs
- flutter_rust_bridge — FFI to Rust-based Lexicon Core library
- Parakeet CTC 0.6B (INT8, ORT format) — STT model, fetched by the build script
- Freezed + json_serializable — immutable data models

Key Features (3 main tabs)
┌───────┬──────────────────────────────────────────────────────────────────────────────┐
│  Tab  │                                   Purpose                                    │
├───────┼──────────────────────────────────────────────────────────────────────────────┤
│ Note  │ Single-speaker transcription, live text display, TTS playback, editable text │
├───────┼──────────────────────────────────────────────────────────────────────────────┤
│ Chat  │ Multi-speaker diarization with chat-bubble UI, speaker labeling/coloring     │
├───────┼──────────────────────────────────────────────────────────────────────────────┤
│ Files │ Browse, search (FTS), import audio files, export to TXT/VTT/JSON             │
└───────┴──────────────────────────────────────────────────────────────────────────────┘
Plus a Settings screen for audio tuning (silence threshold, chunk size), theme customization (light/dark, color presets), and a mic test tool.

Architecture

lib/
├── core/          # Constants, router, theme, utilities
├── features/      # Feature modules (note/, chat/, files/, settings/)
│   └── each has:  providers/ screens/ widgets/
├── services/      # Business logic (audio capture, TTS, FFI bridge)
├── providers/     # App-level Riverpod providers
├── shared/        # Shared widgets (app shell, dialogs)
└── src/rust/      # Auto-generated FFI bindings

Audio Pipeline

Microphone → AudioCaptureService → resample to 16kHz mono → FFI processAudio() → receive transcription segments → update UI in real-time with auto-scroll.