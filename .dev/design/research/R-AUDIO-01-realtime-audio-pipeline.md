---
id: R-AUDIO-01
type: research
status: in-progress
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: Real-Time Audio Pipeline
priority: medium
tags: [audio, resampling, buffers, avfoundation, media3, background-audio, interruptions]
---

# R-AUDIO-01: Real-Time Audio Pipeline Feasibility

## Summary

Research plan for validating real-time audio capture and processing pipeline for Lexicon Mobile. Focus areas: resampling latency from native sample rates to 16kHz, buffer sizing for reliable STT without perceptible lag, and graceful handling of audio interruptions on both platforms.

## Context

Lexicon Mobile captures audio via platform APIs (AVFoundation on iOS, Media3/AAudio on Android), resamples to 16kHz mono for Whisper, and streams chunks to Lexicon Core. Performance requirements:
- Recording start latency: <100ms (mic tap to capture begin)
- STT segment latency: <800ms (speech end to text display)

The audio pipeline must be robust against system interruptions (phone calls, Siri, other apps) while maintaining these latency targets.

## Engineering Challenges

### EC-1: Resampling Latency

**Problem Statement:**
What's the latency cost of 44.1/48kHz → 16kHz resampling on the platform audio layer? Does it fit within the 100ms recording start target?

**Audio Flow:**
```
Microphone → Platform API → Native Sample Rate → Resample → 16kHz Mono → FFI → Whisper
              (44.1/48kHz)                        (??? ms)
```

**Specific Questions:**
- [ ] What sample rates do iOS/Android microphones typically provide?
- [ ] What's the latency of platform-provided resamplers (vDSP, Android Resampler)?
- [ ] Is real-time resampling feasible, or should we request 16kHz directly?
- [ ] Can iOS AudioUnit or Android AAudio provide 16kHz natively?
- [ ] What's the quality tradeoff of different resampling algorithms?
- [ ] Does resampling add to the 100ms startup budget, or is it per-chunk?

**Platform Resampling Options:**

| Platform | API | Native Resampling | Custom Option |
|----------|-----|-------------------|---------------|
| iOS | AVAudioEngine | AVAudioConverter | vDSP, Accelerate |
| iOS | AudioUnit | AudioConverter | libsamplerate |
| Android | AAudio | None built-in | Oboe, libsamplerate |
| Android | AudioRecord | None built-in | Android Resampler |

**Existing Solutions to Investigate:**
- iOS AVAudioConverter with hardware acceleration
- Oboe library for Android (Google's audio library)
- libsamplerate (high-quality, cross-platform)
- speex_resampler (lightweight, used in WebRTC)

**Research Actions:**
- [ ] Test if iOS/Android can capture at 16kHz directly (avoid resampling)
- [ ] Measure AVAudioConverter latency for 48kHz → 16kHz
- [ ] Measure Oboe/AAudio resampling latency on Android
- [ ] Compare CPU usage of different resampling approaches
- [ ] Determine if resampling can run on audio thread without glitches
- [ ] Document recommended approach per platform

**Latency Budget:**
```
Recording Start (100ms total):
├── Audio session setup: ~20-50ms
├── Buffer allocation: ~5-10ms
├── First sample capture: ~10-20ms
└── Resampling init: ??? ms (must be <20ms)
```

### EC-2: Buffer Management

**Problem Statement:**
How large should audio buffers be to avoid underruns during STT processing spikes without adding perceptible latency?

**Buffer Architecture:**
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Capture    │───▶│   Resample  │───▶│   Chunk     │───▶│   FFI to    │
│  Buffer     │    │   Buffer    │    │   Buffer    │    │   Whisper   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
   ~10-20ms           ~10-20ms          ~500-1000ms         Variable
```

**Specific Questions:**
- [ ] What's the optimal capture buffer size (samples per callback)?
- [ ] How much latency does buffering add to the pipeline?
- [ ] What chunk size does Whisper expect/prefer (500ms? 1s? 2s?)?
- [ ] How do we handle STT processing spikes (inference takes longer than chunk)?
- [ ] Should we use a ring buffer or queue for chunk accumulation?
- [ ] What happens if chunks back up (memory growth, dropping)?

**Buffer Sizing Considerations:**

| Buffer | Too Small | Too Large | Sweet Spot |
|--------|-----------|-----------|------------|
| Capture | Glitches, dropouts | Higher latency | 10-20ms (256-512 samples @ 48kHz) |
| Chunk | Frequent FFI calls | Delayed transcription | 500ms-1s of audio |
| Queue | Overflow on spike | Memory growth | 2-3 chunks max |

**Existing Solutions to Investigate:**
- iOS AVAudioEngine tap buffer sizing
- Android AAudio performance mode (LowLatency vs None)
- Lock-free ring buffer implementations
- Whisper streaming chunk recommendations

**Research Actions:**
- [ ] Determine Whisper's preferred input chunk size
- [ ] Test capture buffer sizes on low-end devices
- [ ] Implement ring buffer for chunk accumulation
- [ ] Simulate STT processing spikes (artificial delay)
- [ ] Measure end-to-end latency with various buffer configs
- [ ] Document overflow/backpressure handling strategy

**Backpressure Strategy Options:**

| Strategy | Behavior | Tradeoff |
|----------|----------|----------|
| Drop oldest | Discard old audio when queue full | May lose speech |
| Drop newest | Discard incoming when queue full | Delays catch-up |
| Block capture | Pause capture until queue drains | May cause glitches |
| Grow queue | Allow unlimited queue growth | Memory risk |
| Adaptive chunk | Send larger chunks when behind | Variable latency |

### EC-3: Background Audio and Interruptions

**Problem Statement:**
How do iOS audio session interruptions and Android audio focus changes affect active recordings? Is graceful pause/resume possible?

**Interruption Scenarios:**

| Event | iOS | Android | Expected Behavior |
|-------|-----|---------|-------------------|
| Incoming call | AVAudioSession interruption | Audio focus loss | Pause recording |
| Siri activation | Interruption | N/A | Pause recording |
| Other app plays audio | Depends on category | Focus loss (duck/pause) | Continue or pause? |
| Alarm/timer | Interruption | Focus loss | Pause recording |
| Notification sound | Usually continues | Usually continues | Continue |
| Headphone disconnect | Route change | Audio device change | Continue (switch to speaker) |
| App backgrounded | Depends on capability | Depends on service | Continue or stop? |

**Specific Questions:**
- [ ] What iOS audio session category should we use (playAndRecord, record)?
- [ ] How do we handle `AVAudioSession.interruptionNotification`?
- [ ] Can we resume recording seamlessly after interruption ends?
- [ ] What Android audio focus mode (gain, gainTransient) is appropriate?
- [ ] How do we handle `OnAudioFocusChangeListener` callbacks?
- [ ] Should the app request background audio capability?
- [ ] What happens to in-progress transcription during interruption?

**iOS Audio Session Configuration:**

```swift
// Recommended configuration (to be validated)
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playAndRecord,
                        mode: .measurement,  // or .default?
                        options: [.allowBluetooth, .defaultToSpeaker])
try session.setActive(true)
```

**Android Audio Focus Request:**

```kotlin
// Recommended configuration (to be validated)
val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
    .setAudioAttributes(audioAttributes)
    .setOnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AUDIOFOCUS_LOSS -> pauseRecording()
            AUDIOFOCUS_LOSS_TRANSIENT -> pauseRecording()
            AUDIOFOCUS_GAIN -> resumeRecording()
        }
    }
    .build()
```

**Research Actions:**
- [ ] Test iOS audio session categories and their interruption behavior
- [ ] Implement interruption handling with pause/resume
- [ ] Test Android audio focus scenarios
- [ ] Verify recording can resume without data loss
- [ ] Test background recording on both platforms
- [ ] Document recommended configuration and edge cases
- [ ] Design UI feedback for interruption states

**State Machine for Interruptions:**

```
[Recording] ──(interruption begin)──▶ [Interrupted]
     │                                      │
     │                               (interruption end)
     │                                      │
     │                                      ▼
     │                              [Resuming] ──(resume complete)──▶ [Recording]
     │                                      │
     │                               (user cancels)
     │                                      │
     ▼                                      ▼
[Stopped] ◀────────────────────────────[Stopped]
```

## Related Inquiry Areas

- **Bluetooth audio:** Do Bluetooth headsets/earbuds affect sample rate or latency?
- **Audio routing:** How to handle speaker/headphone/Bluetooth switching mid-recording?
- **Echo cancellation:** Is AEC needed for Note View, or only relevant for calls?
- **Noise suppression:** Should platform-level noise suppression be enabled or disabled (Whisper handles noise)?

## Success Criteria

| Criterion | Target | Minimum Viable |
|-----------|--------|----------------|
| Recording start latency | <100ms | <200ms |
| Resampling latency | <20ms per chunk | <50ms per chunk |
| Buffer underruns | 0 in normal use | <1 per minute |
| Interruption recovery | Seamless resume | Manual resume OK |
| Background recording | Supported | Not required for MVP |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| | | |

## Recommendation

**Status:** PENDING RESEARCH

## References

- [AVAudioEngine Documentation](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [AVAudioSession Programming Guide](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/)
- [Android AAudio](https://developer.android.com/ndk/guides/audio/aaudio/aaudio)
- [Oboe Library](https://github.com/google/oboe) - Google's audio library
- [Managing Audio Focus](https://developer.android.com/guide/topics/media-apps/audio-focus)
- [libsamplerate](http://www.mega-nerd.com/SRC/) - High-quality resampling

## Next Agent Actions

1. Start with EC-1 (Resampling) - test if 16kHz capture is natively supported
2. Build minimal audio capture PoC on iOS and Android
3. Measure actual latencies for resampling approaches
4. EC-2 (Buffers) can proceed once basic capture is working
5. EC-3 (Interruptions) requires testing on physical devices
6. Update this document with findings as you progress
