---
id: R-CORE-01
type: research
status: in-progress
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: Lexicon Core Dependency
priority: high
tags: [lexicon-core, ffi, rust, cross-compile, mobile-targets, api-stability]
---

# R-CORE-01: Lexicon Core Dependency Feasibility

## Summary

Research plan for validating Lexicon Core as a viable dependency for Lexicon Mobile. Focus areas: API stability and completeness of the FFI interface, mobile platform build target support, and error handling semantics for robust mobile app implementation.

## Context

Lexicon Mobile's core functionality depends entirely on Lexicon Core (embedded Rust library) via UniFFI bindings. The project.md defines an expected FFI interface, but it's unclear whether this interface exists today or is aspirational. Mobile apps require:
- Stable, well-defined API contract
- Successful compilation for iOS and Android targets
- Clear error semantics for UI recovery logic

This is a blocking dependency—if Lexicon Core cannot meet these requirements, the project architecture must change.

## Engineering Challenges

### EC-1: API Stability

**Problem Statement:**
Is the `lexicon-ffi` interface defined in project.md finalized, or aspirational? Which functions exist today vs. need development?

**Expected Interface (from project.md):**

```rust
// Session management
fn create_session(config: SessionConfig) -> Result<SessionId, LexiconError>;
fn get_session(id: SessionId) -> Result<Session, LexiconError>;
fn list_sessions() -> Result<Vec<SessionSummary>, LexiconError>;
fn delete_session(id: SessionId) -> Result<(), LexiconError>;
fn rename_session(id: SessionId, title: String) -> Result<(), LexiconError>;

// STT operations
fn start_transcription(...) -> Result<TranscriptionHandle, LexiconError>;
fn process_audio(...) -> Result<Vec<Segment>, LexiconError>;
fn stop_transcription(...) -> Result<(), LexiconError>;
fn cancel_transcription(...) -> Result<(), LexiconError>;

// TTS operations
fn synthesize_speech(...) -> Result<AudioStream, LexiconError>;
fn cancel_synthesis(...) -> Result<(), LexiconError>;

// File import
fn import_audio_file(...) -> Result<SessionId, LexiconError>;
fn cancel_import(...) -> Result<(), LexiconError>;

// Search
fn search_transcriptions(...) -> Result<Vec<SearchResult>, LexiconError>;
```

**Specific Questions:**
- [ ] Does Lexicon Core repository exist and is it accessible?
- [ ] Which of the expected functions are implemented today?
- [ ] Which functions are missing or have different signatures?
- [ ] Is UniFFI already integrated, or needs to be added?
- [ ] What's the versioning/release strategy for the API?
- [ ] Are there breaking changes planned before mobile launch?

**Research Actions:**
- [ ] Obtain access to Lexicon Core repository
- [ ] Audit current FFI interface against project.md expectations
- [ ] Create gap analysis: implemented vs. missing functions
- [ ] Review Lexicon Core roadmap for API stability timeline
- [ ] Identify functions that need mobile-specific modifications
- [ ] Document API differences and propose resolutions

**Gap Analysis Template:**

| Function | Expected | Actual Status | Notes |
|----------|----------|---------------|-------|
| create_session | Yes | ? | |
| get_session | Yes | ? | |
| start_transcription | Yes | ? | |
| process_audio | Yes | ? | Streaming callback needed |
| synthesize_speech | Yes | ? | |
| import_audio_file | Yes | ? | Progress callback needed |
| search_transcriptions | Yes | ? | FTS5 integration |

### EC-2: Mobile Build Targets

**Problem Statement:**
Does Lexicon Core currently build for mobile platforms? Are there blocking dependencies that prevent cross-compilation?

**Required Build Targets:**

| Target Triple | Platform | Architecture | Priority |
|---------------|----------|--------------|----------|
| `aarch64-apple-ios` | iOS | ARM64 | Critical |
| `aarch64-apple-ios-sim` | iOS Simulator | ARM64 (Apple Silicon) | Critical |
| `x86_64-apple-ios` | iOS Simulator | x86_64 (Intel) | Medium |
| `aarch64-linux-android` | Android | ARM64 | Critical |
| `armv7-linux-androideabi` | Android | ARM32 | Low (API 26 includes some) |
| `x86_64-linux-android` | Android Emulator | x86_64 | Medium |

**Specific Questions:**
- [ ] Does Lexicon Core's `Cargo.toml` include mobile targets?
- [ ] Are there CUDA or GPU dependencies that block mobile builds?
- [ ] Which system libraries are required (OpenSSL, SQLite, etc.)?
- [ ] Are all Rust dependencies compatible with mobile targets?
- [ ] What's the compiled library size per target?
- [ ] Is there a CI pipeline for mobile builds?

**Potential Blocking Dependencies:**

| Dependency | Risk | Mitigation |
|------------|------|------------|
| CUDA/cuDNN | High | Must use CPU-only inference |
| OpenSSL | Medium | Use rustls or ring instead |
| System SQLite | Low | Bundle SQLite via rusqlite |
| libc dependencies | Medium | Verify NDK/iOS SDK compatibility |
| proc-macro crates | Low | Usually work, verify UniFFI |

**Research Actions:**
- [ ] Attempt cross-compilation for each target
- [ ] Document build errors and missing dependencies
- [ ] Identify Cargo features to disable GPU/CUDA paths
- [ ] Verify all crate dependencies support mobile targets
- [ ] Measure compiled `.a` (iOS) and `.so` (Android) sizes
- [ ] Set up CI for automated mobile builds
- [ ] Test linking into minimal iOS/Android apps

**Build Verification Checklist:**

```bash
# iOS
cargo build --target aarch64-apple-ios --release
cargo build --target aarch64-apple-ios-sim --release

# Android (requires NDK)
cargo build --target aarch64-linux-android --release
cargo build --target armv7-linux-androideabi --release
```

### EC-3: Error Semantics

**Problem Statement:**
How does Lexicon Core communicate errors and partial failures? Does the mobile app need special recovery logic?

**Specific Questions:**
- [ ] What error types does `LexiconError` enumerate?
- [ ] How are partial failures communicated (e.g., 50 segments transcribed, then error)?
- [ ] Are errors recoverable or terminal for the session?
- [ ] What state is the session left in after an error?
- [ ] How should the mobile app handle `process_audio` failures mid-stream?
- [ ] Are there error codes for user-actionable issues (permissions, storage)?

**Error Scenarios to Document:**

| Scenario | Expected Behavior | Recovery Action |
|----------|-------------------|-----------------|
| Model file missing | Error on start | Prompt re-download |
| Storage full mid-transcription | Error, partial save? | Show saved segments, prompt cleanup |
| Audio format unsupported | Error on import | Show format list |
| Memory pressure during inference | ? | Retry with smaller model? |
| Cancellation during write | Clean rollback? | Verify no corruption |
| FFI panic | Catch or crash? | Graceful degradation |

**Existing Solutions to Investigate:**
- Rust `thiserror` / `anyhow` patterns
- UniFFI error handling and propagation
- SQLite transaction rollback on error
- Partial result patterns (return results + error)

**Research Actions:**
- [ ] Review Lexicon Core error type definitions
- [ ] Document all error variants and their meanings
- [ ] Test partial failure scenarios (simulate mid-stream errors)
- [ ] Verify session state consistency after errors
- [ ] Determine if panics are caught or propagate to app crash
- [ ] Design mobile error handling strategy based on findings
- [ ] Propose error type additions if needed for mobile UX

**Error Handling Architecture:**

```
Lexicon Core (Rust)          FFI Boundary           Mobile App
      │                          │                      │
   Result<T, E>  ──────────►  UniFFI  ──────────►  Swift/Kotlin
      │                       Error                  Exception
      │                     Conversion                  │
   panic!()  ─────────────►  Catch?  ──────────►   App Crash?
                              or propagate
```

## Related Inquiry Areas

- **Lexicon Local Server relationship:** Is Lexicon Core extracted from Lexicon Local Server, or a separate crate?
- **Version synchronization:** How to keep mobile app and Lexicon Core versions aligned?
- **Testing strategy:** Does Lexicon Core have tests that can run on mobile targets?
- **Documentation:** Is there API documentation beyond code comments?

## Success Criteria

| Criterion | Target | Minimum Viable |
|-----------|--------|----------------|
| API coverage | 100% of expected functions | 80% (defer non-critical) |
| iOS build | aarch64 + simulator | aarch64 only |
| Android build | aarch64 + armv7 | aarch64 only |
| Error documentation | All variants documented | Critical paths documented |
| Library size | <20MB per target | <50MB per target |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| | | |

## Recommendation

**Status:** PENDING RESEARCH

## References

- Lexicon Core repository (internal - access required)
- Lexicon Local Server repository (internal - relationship TBD)
- [UniFFI Manual](https://mozilla.github.io/uniffi-rs/)
- [Rust Cross-Compilation](https://rust-lang.github.io/rustup/cross-compilation.html)
- [Cargo NDK](https://github.com/nickelghost/cargo-ndk) - Android builds
- [cargo-lipo](https://github.com/nickelghost/cargo-lipo) - iOS universal builds

## Next Agent Actions

1. **Critical first step:** Obtain access to Lexicon Core repository
2. If accessible, perform EC-1 API audit immediately
3. Attempt EC-2 build targets to identify blocking issues early
4. EC-3 can proceed in parallel once code access is available
5. If Lexicon Core is not accessible or doesn't exist, escalate as blocking issue
6. Update this document with findings as you progress
