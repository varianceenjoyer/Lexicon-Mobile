---
id: R-FFI-01
type: research
status: complete
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: FFI/UniFFI Integration
priority: high
tags: [uniffi, ffi, rust, swift, kotlin, async, threading]
provided-by: lexicon-local-server
---

# R-FFI-01: UniFFI Integration Feasibility

## Status: COMPLETE — Provided by Lexicon Local Server

This research is **not required** for Lexicon Mobile. All FFI/UniFFI integration concerns are handled by Lexicon Local Server.

## Findings

Per [Lexicon Local Server Roadmap](~/projects/Lexicon-Local-Server/.dev/design/roadmap.md):

| Work Package | Status | Relevance |
|--------------|--------|-----------|
| **WP-FFI** | ✅ Complete | UniFFI bindings implemented and working |
| Beta Exit Criteria | Tests blocked on SDK | Swift/Kotlin bindings compile successfully |

### What Local Server Provides

1. **Async Callback Semantics (EC-1)**: Streaming callbacks from Rust to Swift/Kotlin are implemented in WP-FFI
2. **Thread Safety (EC-2)**: Lexicon Core handles concurrent FFI calls; `Send + Sync` compliance resolved
3. **Cancellation Propagation (EC-3)**: `cancel_transcription()` and `cancel_import()` implemented with cooperative cancellation

### Mobile Client Responsibility

The mobile client simply **consumes** the generated UniFFI bindings. No additional research needed.

- Import the generated Swift/Kotlin bindings
- Call FFI functions per the documented API
- Handle returned errors and callbacks in platform-idiomatic ways

## Original Engineering Challenges (Resolved)

- ~~EC-1: Async Callback Semantics~~ → Implemented in WP-FFI
- ~~EC-2: Thread Safety~~ → Implemented in WP-FFI
- ~~EC-3: Cancellation Propagation~~ → Implemented in WP-FFI

## Recommendation

**GO** — Proceed with mobile development using Local Server's UniFFI bindings.

## References

- Lexicon Local Server: `~/projects/Lexicon-Local-Server/`
- WP-FFI work package in Local Server roadmap
