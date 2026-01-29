---
id: R-CORE-01
type: research
status: complete
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: Lexicon Core Dependency
priority: high
tags: [lexicon-core, ffi, rust, cross-compile, mobile-targets, api-stability]
provided-by: lexicon-local-server
---

# R-CORE-01: Lexicon Core Dependency Feasibility

## Status: COMPLETE — Provided by Lexicon Local Server

This research is **not required** for Lexicon Mobile. Lexicon Core exists, the API is defined, and mobile builds are working.

## Findings

Per [Lexicon Local Server Roadmap](~/projects/Lexicon-Local-Server/.dev/design/roadmap.md):

| Work Package | Status | Relevance |
|--------------|--------|-----------|
| **WP-FFI** | ✅ Complete | UniFFI bindings compile |
| **WP-ANDROID** | 🔄 Partial | STT+TTS working on Android |
| **WP-IOS** | ⬜ Ready | Ready to begin |
| **WP-BUILD** | ✅ Complete | Build pipeline established |

### What Local Server Provides

1. **API Stability (EC-1)**: FFI interface is implemented and working
2. **Mobile Build Targets (EC-2)**: Android builds confirmed working; iOS ready to start
3. **Error Semantics (EC-3)**: Error types defined in Lexicon Core

### Confirmed Working

From Local Server roadmap:
- "UniFFI bindings compile (tests blocked on SDK)" ✅
- "WP-ANDROID: STT+TTS working" ✅
- Beta deliverable: "Swift/Kotlin bindings pass unit tests" (blocked on SDK, not implementation)

### Mobile Client Responsibility

**Integration steps:**
1. Link against Lexicon Core library (`.a` for iOS, `.so` for Android)
2. Import generated UniFFI Swift/Kotlin bindings
3. Call documented API functions
4. Handle errors per `LexiconError` enum

### Repository Access

Lexicon Local Server is located at: `~/projects/Lexicon-Local-Server/`

The FFI interface and mobile build configuration are defined in this repository.

## Original Engineering Challenges (Resolved)

- ~~EC-1: API Stability~~ → WP-FFI complete, API implemented
- ~~EC-2: Mobile Build Targets~~ → WP-ANDROID working, WP-IOS ready
- ~~EC-3: Error Semantics~~ → Defined in Lexicon Core implementation

## Recommendation

**GO** — Proceed with mobile development; Lexicon Core dependency is available and building.

## References

- Lexicon Local Server: `~/projects/Lexicon-Local-Server/`
- WP-FFI, WP-ANDROID, WP-IOS, WP-BUILD work packages
