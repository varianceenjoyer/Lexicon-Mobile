# Lexicon Mobile

## Project Description

Lexicon Mobile is a Flutter app for on-device, privacy-first speech transcription. Audio never leaves the phone: speech-to-text runs locally through the Rust `lexicon-flutter` library from [Lexicon Local Server](https://github.com/varianceenjoyer/Lexicon-Local-Server), called over FFI via `flutter_rust_bridge`.

## Features

- **Note** — single-speaker live transcription with editable text, auto-scroll, and TTS playback
- **Chat** — multi-speaker transcription with diarization, shown as chat bubbles with per-speaker labels and colors
- **Files** — browse and full-text search saved sessions, import audio files, export to TXT / VTT / JSON
- **Settings** — audio tuning (silence threshold, chunk size, noise reduction), light/dark themes with color presets, and a mic test tool
- Sessions persist across app restarts

## Project Structure

```
lib/
├── core/          # Constants, router, theme, utilities
├── features/      # note/, chat/, files/, settings/ — each with providers/ screens/ widgets/
├── services/      # Audio capture, TTS playback, Lexicon FFI service (+ mocks)
├── providers/     # App-level Riverpod providers
├── shared/        # Shared widgets (app shell, dialogs)
└── src/rust/      # Auto-generated flutter_rust_bridge bindings
assets/
├── audio/         # Test clips for STT accuracy checks
└── models/        # STT models (git-ignored; fetched by the build script)
```

## Current Status

| Component | Status |
|-----------|--------|
| Android | Primary target, builds via `build_mobile_apk.sh` |
| iOS | Project scaffolded, not yet built/tested |
| STT engine | Parakeet CTC 0.6B (INT8, ORT format) |
| Note / Chat / Files / Settings | Implemented |

Version 0.1.0 — early development.

## Quick Start

This repo is built as part of the Lexicon Suite, alongside `Lexicon-Local-Server`:

```
Lexicon-Suite/
├── Lexicon-Local-Server/
├── Lexicon-Mobile/
└── build/build_mobile_apk.sh
```

Requirements: Flutter (Dart 3), Rust, and the Android SDK + NDK (`ANDROID_NDK_HOME`).

```bash
# Builds the Rust library, downloads the Parakeet model, and builds the APK
./build/build_mobile_apk.sh arm64      # targets: arm64, x86_64 (default), arm32, all
```

For UI work without the native library, the services in `lib/services/mocks/` stand in for the Rust core.

## Hardware

Any modern Android phone with a microphone; arm64 is the recommended target. The x86_64 build is for emulators. Transcription runs entirely on-device, so faster CPUs give lower latency.

## Architecture

```
Microphone → AudioCaptureService → resample to 16 kHz mono
          → FFI processAudio() (lexicon-flutter / Parakeet via ONNX Runtime)
          → transcription segments → Riverpod state → UI
```

- **State:** Riverpod (StateNotifier)
- **Navigation:** GoRouter with bottom tabs
- **Models:** Freezed + json_serializable immutable data classes

## Dependencies

- `flutter_riverpod`, `go_router`
- `record`, `just_audio`, `permission_handler`, `flutter_foreground_task`
- `flutter_rust_bridge`, `ffi`
- `freezed`, `json_serializable`, `shared_preferences`, `path_provider`

See `pubspec.yaml` for the full list.

## Documentation

- [docs/overview.md](docs/overview.md) — codebase overview
- [Lexicon Local Server](https://github.com/varianceenjoyer/Lexicon-Local-Server) — Rust core, server, and FFI crates

## License

MIT
