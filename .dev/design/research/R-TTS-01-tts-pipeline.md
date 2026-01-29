---
id: R-TTS-01
type: research
status: in-progress
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: TTS Pipeline — Mobile Integration
priority: medium
tags: [tts, audio-playback, regeneration-ux, avfoundation, exoplayer]
scope: mobile-specific
---

# R-TTS-01: TTS Pipeline — Mobile Integration

## Summary

Research plan for mobile-specific TTS integration concerns. The TTS engine (Kokoro) is provided by Lexicon Local Server; this research focuses on **mobile playback integration** and **regeneration UX**.

## Context: What Local Server Provides

Per [Lexicon Local Server Roadmap](~/projects/Lexicon-Local-Server/.dev/design/roadmap.md):

| Work Package | Status | What It Provides |
|--------------|--------|------------------|
| **WP-TTS** | ✅ Complete | Kokoro TTS synthesis engine |
| **Decision D4** | ✅ Complete | Platform fallback for non-English |
| **TTS Quality** | ✅ Complete | MOS 3.0 validated |

**NOT mobile's concern:**
- ~~EC-1: Synthesis Latency~~ → WP-TTS handles synthesis performance
- ~~EC-3: Voice Options~~ → WP-TTS provides voice configuration via FFI

## Mobile-Specific Engineering Challenges

### EC-2: Regeneration UX (Mobile)

**Problem Statement:**
When users edit transcribed text in Note View, the mobile app must manage TTS regeneration. This is a UX/caching decision for the mobile client.

**Specific Questions:**
- [ ] Should regeneration happen on-demand (play tap) or immediately on edit?
- [ ] Is sentence-level caching worth the complexity for mobile?
- [ ] How much local storage should be allocated for TTS cache?
- [ ] What's the UX if regeneration takes 2+ seconds? (loading indicator, partial playback)
- [ ] Should edits invalidate the entire cache or use diff-based invalidation?

**Caching Strategies (Mobile Decision):**

| Strategy | Pros | Cons | Recommended? |
|----------|------|------|--------------|
| No cache | Simple | Re-synthesize on every play | MVP |
| Full document cache | Fast replay | Invalidated on any edit | Consider for v2 |
| Sentence-level cache | Partial regeneration | Complex implementation | Future |

**Research Actions:**
- [ ] Prototype on-demand regeneration flow
- [ ] Measure typical TTS latency via FFI for UX design
- [ ] Design loading/progress UI for regeneration
- [ ] Decide cache strategy based on typical usage patterns
- [ ] User test acceptable regeneration delays

### EC-4: Audio Playback Integration (Mobile)

**Problem Statement:**
How do we integrate TTS audio output from Lexicon Core with iOS/Android platform playback APIs?

**Playback Requirements (from project.md NV-06):**
- Play/pause control
- Seek via progress slider
- Time display (current / total)
- Gapless chunk playback

**Platform APIs:**

| Platform | Playback API | Streaming Support | Seeking |
|----------|--------------|-------------------|---------|
| iOS | AVAudioEngine | Yes | Manual implementation |
| iOS | AVAudioPlayer | Limited | Built-in |
| Android | ExoPlayer/Media3 | Yes | Built-in |
| Android | MediaPlayer | Limited | Built-in |

**Specific Questions:**
- [ ] What audio format does Lexicon Core TTS return (PCM samples, WAV)?
- [ ] Does Lexicon Core support streaming TTS (chunk callbacks)?
- [ ] How do we buffer streamed audio for seeking support?
- [ ] How do we estimate total duration before synthesis completes?
- [ ] Should we wait for full synthesis before enabling playback?

**Research Actions:**
- [ ] Document Lexicon Core TTS output format from FFI interface
- [ ] Prototype iOS audio player with TTS output
- [ ] Prototype Android audio player with TTS output
- [ ] Implement seeking within synthesized audio
- [ ] Test gapless playback of streamed chunks
- [ ] Design progress indicator for streaming playback

**Playback Architecture:**

```
Lexicon Core (TTS)        Mobile App
      │                      │
  [AudioStream]  ───FFI───▶  [Platform Buffer]
      │                      │
  (PCM chunks)              [AVAudioEngine / ExoPlayer]
                             │
                            [Playback Controls]
                             ├── Play/Pause
                             ├── Seek
                             └── Progress Display
```

## Success Criteria

| Criterion | Target | Minimum Viable |
|-----------|--------|----------------|
| Regeneration UX | Seamless with loading indicator | Blocking modal OK |
| Time to playback (cached) | <100ms | <300ms |
| Seek accuracy | <100ms | <500ms |
| Gapless playback | No audible gaps | Minimal gaps acceptable |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| | | |

## Recommendation

**Status:** PENDING RESEARCH — Mobile-specific integration only

## References

- Lexicon Core FFI interface (from Local Server)
- [AVAudioEngine](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [ExoPlayer/Media3](https://developer.android.com/guide/topics/media/exoplayer)

## Next Agent Actions

1. Review Lexicon Core FFI interface for TTS output format
2. Prototype basic iOS playback with AVAudioEngine
3. Prototype basic Android playback with ExoPlayer
4. Design regeneration UX based on measured latencies
5. Update this document with findings
