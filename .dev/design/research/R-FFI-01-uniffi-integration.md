---
id: R-FFI-01
type: research
status: in-progress
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: FFI/UniFFI Integration
priority: high
tags: [uniffi, ffi, rust, swift, kotlin, async, threading]
---

# R-FFI-01: UniFFI Integration Feasibility

## Summary

Research plan for validating FFI/UniFFI integration patterns between Lexicon Core (Rust) and mobile platforms (Swift/Kotlin). Focus areas: async callback semantics for real-time streaming, thread safety for concurrent audio/UI access, and cancellation propagation for interruptible operations.

## Context

Lexicon Mobile depends on Lexicon Core via UniFFI bindings. The mobile app requires:
- Real-time segment delivery during transcription (streaming callbacks)
- Concurrent FFI access from UI thread and audio capture thread
- Clean cancellation of transcription/import operations

These patterns go beyond basic UniFFI usage and require validation before implementation.

## Engineering Challenges

### EC-1: Async Callback Semantics

**Problem Statement:**
Does UniFFI support streaming callbacks from Rust to Swift/Kotlin for real-time segment delivery? What's the memory ownership model for audio buffers crossing the FFI boundary?

**Specific Questions:**
- [ ] Can UniFFI define callback interfaces that Rust invokes repeatedly?
- [ ] How are callbacks scheduled on Swift/Kotlin threads (main, background)?
- [ ] Who owns audio buffer memory after crossing FFI boundary?
- [ ] What's the latency overhead of callback invocation?

**Existing Solutions to Investigate:**
- UniFFI callback interfaces (proc-macro based)
- UniFFI `ForeignExecutor` for thread scheduling
- Mozilla's use of UniFFI in Firefox (similar streaming patterns)

**Research Actions:**
- [ ] Review UniFFI documentation for callback interface patterns
- [ ] Find open-source projects using UniFFI with streaming callbacks
- [ ] Build minimal PoC: Rust → Swift callback with simulated audio chunks
- [ ] Measure callback latency overhead
- [ ] Document memory ownership patterns in UniFFI callbacks

### EC-2: Thread Safety

**Problem Statement:**
How does Lexicon Core handle concurrent FFI calls from UI and audio threads? Is the Rust code `Send + Sync` where needed?

**Specific Questions:**
- [ ] Does Lexicon Core use interior mutability (`Mutex`, `RwLock`) or requires external synchronization?
- [ ] Can `process_audio()` be called from audio thread while UI calls `get_session()`?
- [ ] What happens if UI calls `cancel_transcription()` mid-`process_audio()`?
- [ ] Does UniFFI-generated code add synchronization overhead?

**Existing Solutions to Investigate:**
- UniFFI thread safety guarantees (generated bindings)
- Rust `Send + Sync` traits in FFI context
- Mobile audio callback threading models (Core Audio, AAudio)

**Research Actions:**
- [ ] Review Lexicon Core source for thread-safety markers
- [ ] Document which FFI functions are safe to call concurrently
- [ ] Identify functions requiring serialization (if any)
- [ ] Build PoC with concurrent FFI calls from multiple threads
- [ ] Stress test concurrent access patterns

### EC-3: Cancellation Propagation

**Problem Statement:**
Can `cancel_transcription()` and `cancel_import()` interrupt long-running Rust operations cleanly, or will they block?

**Specific Questions:**
- [ ] Does Lexicon Core implement cooperative cancellation (checking flag periodically)?
- [ ] How quickly does cancellation take effect (latency)?
- [ ] What state is the session left in after cancellation?
- [ ] Are resources (memory, file handles) properly cleaned up?

**Existing Solutions to Investigate:**
- Rust `tokio::CancellationToken` patterns
- `std::sync::atomic` for cancellation flags
- SQLite transaction rollback on abort

**Research Actions:**
- [ ] Review Lexicon Core cancellation implementation
- [ ] Identify cancellation points in transcription pipeline
- [ ] Measure cancellation response time
- [ ] Verify resource cleanup after cancellation
- [ ] Document expected behavior for UI implementation

## Related Inquiry Areas

- **tokio-uniffi bridge:** If Lexicon Core uses async Rust (tokio), how does this interact with UniFFI's blocking model?
- **Error propagation:** How are Rust errors (panics, Results) surfaced to Swift/Kotlin?
- **Object lifecycle:** How do UniFFI-generated handles map to Rust struct lifetimes?

## Success Criteria

| Criterion | Target |
|-----------|--------|
| Callback latency | <5ms overhead per invocation |
| Concurrent access | No crashes under stress test |
| Cancellation response | <100ms from call to effect |
| Memory leaks | Zero in callback/cancel flows |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| | | |

## Recommendation

**Status:** PENDING RESEARCH

## References

- [UniFFI Manual](https://mozilla.github.io/uniffi-rs/)
- [UniFFI Callback Interfaces](https://mozilla.github.io/uniffi-rs/latest/callback_interfaces.html)
- [UniFFI Foreign Executors](https://mozilla.github.io/uniffi-rs/latest/foreign_executors.html)
- Lexicon Core repository (internal)

## Next Agent Actions

1. Start with EC-1 (Async Callback Semantics) - most critical for real-time streaming
2. Review UniFFI documentation and identify callback interface patterns
3. Search for open-source UniFFI projects with streaming/callback usage
4. Build minimal PoC if documentation is insufficient
5. Update this document with findings as you progress
