---
id: R-TTS-01
type: research
status: in-progress
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: TTS Pipeline
priority: medium
tags: [tts, kokoro, speech-synthesis, latency, audio-playback, voice]
---

# R-TTS-01: TTS Pipeline Feasibility

## Summary

Research plan for validating Text-to-Speech pipeline feasibility for Lexicon Mobile's Note View. Focus areas: synthesis latency to meet <300ms first-audio target, regeneration UX when users edit transcribed text, and voice options availability and customization.

## Context

Note View (NV-04 through NV-08) provides TTS playback of transcribed text:
- TTS generation triggered on recording stop/pause
- First audio playback within 300ms of play tap
- Text edits require TTS regeneration
- Playback controls: play/pause, seek, progress display

The project specifies Kokoro TTS via Lexicon Core. This research validates whether Kokoro can meet these requirements on mobile devices.

## Engineering Challenges

### EC-1: Synthesis Latency

**Problem Statement:**
Can Kokoro TTS generate first audio chunk in <300ms (per requirements) for typical note lengths on mobile devices?

**TTS Pipeline:**
```
[Play Tap] → [Text to Kokoro] → [First Chunk Generated] → [Audio Output]
    0ms          ~50ms               ??? ms                  ~50ms
                                 Target: <200ms
```

**Specific Questions:**
- [ ] What's Kokoro's time-to-first-audio for short text (1-10 words)?
- [ ] What's the latency for medium text (50-100 words)?
- [ ] What's the latency for long text (500+ words)?
- [ ] Does Kokoro support streaming synthesis (chunk-by-chunk)?
- [ ] Can synthesis start while previous chunks are playing?
- [ ] What's the performance on low-end devices (iPhone SE 2, Pixel 4a)?

**Latency Expectations (to be validated):**

| Text Length | Target TTFA | Acceptable | Notes |
|-------------|-------------|------------|-------|
| 1-10 words | <100ms | <200ms | Common for quick notes |
| 50-100 words | <200ms | <400ms | Typical note |
| 500+ words | <300ms | <600ms | Long note, streaming critical |

**Existing Solutions to Investigate:**
- Kokoro streaming synthesis API
- Chunked synthesis (sentence-by-sentence)
- Audio buffer pre-filling during synthesis
- Background synthesis while recording

**Research Actions:**
- [ ] Benchmark Kokoro TTFA on various text lengths
- [ ] Test on low-end target devices
- [ ] Evaluate streaming vs batch synthesis
- [ ] Measure CPU/memory usage during synthesis
- [ ] Determine if synthesis can run concurrently with playback
- [ ] Document latency characteristics for UI design

### EC-2: Regeneration UX

**Problem Statement:**
When users edit transcribed text, TTS must regenerate. For long documents, is this fast enough to not frustrate users, or is caching/diffing needed?

**Edit Scenarios:**

| Scenario | Frequency | Complexity |
|----------|-----------|------------|
| Fix typo (1-2 words) | High | Should be instant |
| Rewrite sentence | Medium | Regenerate sentence only? |
| Add paragraph | Low | Append synthesis? |
| Major rewrite | Low | Full regeneration acceptable |

**Specific Questions:**
- [ ] Can Kokoro regenerate individual sentences without full re-synthesis?
- [ ] Is sentence-level caching feasible (hash text → audio)?
- [ ] How much storage would cached TTS consume?
- [ ] Should regeneration happen on-demand (play tap) or immediately on edit?
- [ ] Can we diff old/new text and only regenerate changed portions?
- [ ] What's the UX if regeneration takes 2+ seconds?

**Caching Strategies:**

| Strategy | Pros | Cons |
|----------|------|------|
| No cache | Simple, no storage | Slow on repeat plays |
| Full document cache | Fast replay | Invalidated on any edit |
| Sentence-level cache | Partial regeneration | Complex invalidation |
| Paragraph-level cache | Balance of above | Medium complexity |

**Research Actions:**
- [ ] Test Kokoro's ability to synthesize partial text
- [ ] Prototype sentence-level caching system
- [ ] Measure cache storage requirements
- [ ] Design cache invalidation strategy
- [ ] Evaluate on-edit vs on-play regeneration UX
- [ ] User test acceptable regeneration delays

**Proposed Regeneration Flow:**

```
[User Edits Text]
       │
       ▼
[Detect Changed Sentences]
       │
       ▼
[Invalidate Cache for Changed]
       │
       ▼
[On Next Play: Regenerate Changed + Use Cached]
       │
       ▼
[Seamless Playback]
```

### EC-3: Voice Options

**Problem Statement:**
Are multiple TTS voices available in Kokoro, or is it single-voice? Does voice selection affect model size or synthesis quality?

**Specific Questions:**
- [ ] How many voices does Kokoro provide?
- [ ] Are voices bundled in one model or separate model files?
- [ ] What's the size impact of additional voices?
- [ ] Can voices be downloaded on-demand?
- [ ] Are there male/female voice options?
- [ ] Are there different language voices (for non-English TTS)?
- [ ] Can voice characteristics be adjusted (speed, pitch)?

**Voice Configuration Options:**

| Option | User Control | Implementation |
|--------|--------------|----------------|
| Voice selection | Dropdown in settings | Load different model/config |
| Speech rate | Slider (0.5x - 2.0x) | Synthesis parameter |
| Pitch | Slider (optional) | Synthesis parameter |
| Volume | System control | Platform audio |

**Existing Solutions to Investigate:**
- Kokoro voice model variants
- VITS/ONNX voice model architecture
- On-demand voice downloading patterns
- Platform TTS fallback (AVSpeechSynthesizer, Android TTS)

**Research Actions:**
- [ ] Inventory available Kokoro voices
- [ ] Measure model size per voice
- [ ] Test voice switching performance
- [ ] Evaluate speech rate/pitch adjustment APIs
- [ ] Consider platform TTS as fallback option
- [ ] Document voice options for product decision

### EC-4: Audio Playback Integration

**Problem Statement:**
How do we integrate synthesized audio with platform playback APIs for seeking, progress display, and background playback?

**Playback Requirements (from NV-06):**
- Play/pause control
- Seek via progress slider
- Time display (current / total)
- Gapless chunk playback

**Specific Questions:**
- [ ] What audio format does Kokoro output (PCM, WAV, etc.)?
- [ ] How do we concatenate streamed chunks for seamless playback?
- [ ] Can we seek within synthesized audio (requires full synthesis first)?
- [ ] How do we calculate total duration before synthesis completes?
- [ ] Should we buffer full audio before allowing playback?
- [ ] How do we handle playback during active synthesis?

**Playback Architecture Options:**

| Approach | Seeking | Progress | Complexity |
|----------|---------|----------|------------|
| Full synthesis → Play | Full | Accurate | Simple, slow start |
| Stream + buffer | After buffer | Estimated → Actual | Medium |
| Chunk-by-chunk live | Limited | Progressive | Complex |

**Research Actions:**
- [ ] Document Kokoro output format and streaming API
- [ ] Prototype audio player with streamed chunks
- [ ] Implement seeking within synthesized audio
- [ ] Design progress indicator for streaming playback
- [ ] Test gapless playback of consecutive chunks
- [ ] Evaluate iOS AVAudioPlayer vs AVAudioEngine for playback

## Related Inquiry Areas

- **Concurrent STT + TTS:** Can both run simultaneously, or resource conflict?
- **Background TTS:** Should TTS continue if app is backgrounded?
- **Accessibility:** How does TTS interact with VoiceOver/TalkBack?
- **Language support:** What languages does Kokoro support?

## Success Criteria

| Criterion | Target | Minimum Viable |
|-----------|--------|----------------|
| Time to first audio | <300ms | <500ms |
| Regeneration (1 sentence) | <500ms | <1s |
| Voice options | 2+ voices | 1 voice |
| Seek accuracy | <100ms | <500ms |
| Gapless playback | No audible gaps | Minimal gaps |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| | | |

## Recommendation

**Status:** PENDING RESEARCH

## References

- [Kokoro TTS](https://github.com/hexgrad/kokoro) - Target TTS engine
- [VITS Paper](https://arxiv.org/abs/2106.06103) - Underlying architecture
- [AVAudioEngine Playback](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [ExoPlayer](https://developer.android.com/guide/topics/media/exoplayer) - Android playback
- Platform TTS: AVSpeechSynthesizer (iOS), android.speech.tts (Android)

## Next Agent Actions

1. Start with EC-1 (Synthesis Latency) - critical for UX validation
2. Benchmark Kokoro TTFA on representative text samples
3. Test on low-end devices to establish performance floor
4. EC-2 (Regeneration) depends on EC-1 findings
5. EC-3 (Voices) can proceed in parallel
6. Update this document with findings as you progress
