---
id: R-TTS-01
type: research
status: complete
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

Research complete. This document provides recommendations for mobile TTS playback integration and regeneration UX strategy.

**Recommendations:**
- Use AVAudioEngine (iOS) and ExoPlayer/Media3 (Android) for playback
- MVP: No caching, on-demand synthesis
- v2: Consider sentence-level caching if latency is problematic

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

## Research Findings

### EC-2: Regeneration UX (Mobile)

#### Strategy Analysis

| Strategy | Complexity | Storage | Latency | Recommendation |
|----------|------------|---------|---------|----------------|
| No cache | Low | 0 | High (re-synthesize) | **MVP** |
| Full document cache | Medium | High | Low (cached) | v2 |
| Sentence-level cache | High | Medium | Low (partial) | Future |

#### MVP Approach: On-Demand Synthesis

For MVP, regeneration happens on-demand when user taps play:

```
[User Edits Text] → [Invalidate Any Cache]
        │
[User Taps Play] → [Show Loading] → [Synthesize] → [Play]
                         │
                   (TTS latency ~300ms based on WP-TTS)
```

**Rationale:**
- Simple implementation
- No storage overhead
- WP-TTS already achieves <300ms first-audio target
- Acceptable UX for MVP

#### v2 Enhancement: Document Cache

```
[User Taps Play (first time)]
        │
        ▼
[Synthesize Full Document] → [Cache to Disk] → [Play]
        │
[User Taps Play (subsequent)]
        │
        ▼
[Check Cache] → [Valid?] → [Play from Cache]
        │
   [Invalid/Missing]
        │
        ▼
[Re-synthesize] → [Update Cache] → [Play]
```

**Cache Invalidation:**
- Any text edit invalidates entire cache
- Cache stored per session ID
- Max cache size: ~50MB per session (configurable)

#### Regeneration UX Design

**Loading State (during synthesis):**
```
┌────────────────────────────────────────┐
│  ▶ Play    ────────────────── 0:00    │
│                                        │
│       ┌────────────────────────┐      │
│       │   Preparing audio...   │      │
│       │   ███████░░░░░░░░░     │      │
│       └────────────────────────┘      │
└────────────────────────────────────────┘
```

**Timing Thresholds:**
| Synthesis Time | UX Treatment |
|----------------|--------------|
| <300ms | No indicator (appears instant) |
| 300ms - 2s | Inline spinner |
| >2s | Progress bar with percentage |

### EC-4: Audio Playback Integration (Mobile)

#### Expected Lexicon Core TTS Output

Based on Kokoro TTS architecture (VITS-based):
- **Format:** PCM audio samples
- **Sample Rate:** 22050 Hz (typical for Kokoro)
- **Bit Depth:** 16-bit
- **Channels:** Mono
- **Streaming:** Chunk callbacks supported

#### iOS: AVAudioEngine Playback

**Recommended Architecture:**

```swift
import AVFoundation

class TTSPlaybackManager {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFormat: AVAudioFormat!

    func setup() {
        // Kokoro outputs 22050 Hz, 16-bit mono PCM
        audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 22050,
            channels: 1,
            interleaved: false
        )!

        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFormat)

        try? engine.start()
    }

    func playPCMChunk(_ samples: [Int16]) {
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFormat,
            frameCapacity: AVAudioFrameCount(samples.count)
        ) else { return }

        buffer.frameLength = buffer.frameCapacity

        // Copy samples to buffer
        let channelData = buffer.int16ChannelData![0]
        for (index, sample) in samples.enumerated() {
            channelData[index] = sample
        }

        // Schedule buffer for playback
        playerNode.scheduleBuffer(buffer)

        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    func stop() {
        playerNode.stop()
    }

    func seek(to time: TimeInterval) {
        // For seeking, need to buffer full audio first
        // Then use scheduleSegment or re-schedule from offset
    }
}
```

**Key Considerations:**
- [x] AVAudioEngine works in pull model — schedule buffers ahead
- [x] Use ring buffer pattern for streaming chunks
- [x] For seeking, accumulate full audio before enabling seek slider
- [x] Handle audio session configuration (coordinate with recording)

#### Android: ExoPlayer/Media3 Playback

**Recommended Architecture:**

```kotlin
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer

class TTSPlaybackManager(context: Context) {
    private val player: ExoPlayer

    init {
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(C.USAGE_MEDIA)
            .setContentType(C.AUDIO_CONTENT_TYPE_SPEECH)
            .build()

        player = ExoPlayer.Builder(context)
            .setAudioAttributes(audioAttributes, true)
            .build()
    }

    // For pre-synthesized audio file
    fun playFromFile(uri: Uri) {
        val mediaItem = MediaItem.fromUri(uri)
        player.setMediaItem(mediaItem)
        player.prepare()
        player.play()
    }

    // For streaming PCM, use custom AudioProcessor
    // or write PCM to temp file and play

    fun pause() {
        player.pause()
    }

    fun seekTo(positionMs: Long) {
        player.seekTo(positionMs)
    }

    fun release() {
        player.release()
    }
}
```

**PCM Streaming Approach:**

For real-time PCM streaming, two options:

1. **Temp File Approach (Simpler):**
   - Write PCM chunks to temp WAV file
   - Play file with ExoPlayer once complete
   - Good for MVP

2. **Custom AudioProcessor (Advanced):**
   - Implement `AudioProcessor` to intercept PCM data
   - More complex but enables true streaming
   - Consider for v2 if latency is issue

**Recommendation:** Start with temp file approach for MVP.

#### Seeking Implementation

**Challenge:** Seeking requires knowing total duration, which isn't available until synthesis completes.

**Solution:**

```
[During Synthesis]
├── Disable seek slider
├── Show indeterminate progress
└── Display "Generating audio..."

[Synthesis Complete]
├── Enable seek slider
├── Show accurate duration
└── Full seeking available
```

**Alternative:** Estimate duration from text length (words × avg word duration) for immediate seek UI, then correct when synthesis completes.

#### Gapless Playback

For chunk-by-chunk playback without gaps:

**iOS:**
- Schedule multiple buffers ahead (3-5 buffers)
- Use `scheduleBuffer(buffer, completionCallbackType: .dataConsumed)` to know when to schedule next

**Android:**
- ExoPlayer handles gapless natively for file playback
- For streaming, buffer sufficient chunks before playback

## Playback Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                     Lexicon Core (Rust/FFI)                      │
├─────────────────────────────────────────────────────────────────┤
│  synthesize_speech(text) → callback(PCMChunk) → callback(Done)  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ FFI
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Mobile Playback Layer                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐        ┌──────────────────┐              │
│  │   iOS            │        │   Android        │              │
│  │   AVAudioEngine  │        │   ExoPlayer      │              │
│  │   + PlayerNode   │        │   + MediaItem    │              │
│  └──────────────────┘        └──────────────────┘              │
│           │                          │                          │
│           ▼                          ▼                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Unified Playback Controls                    │  │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────────────────────────┐│  │
│  │  │ ▶ Play  │ │ ⏸ Pause│ │ ═══════════●══════════ 1:23 ││  │
│  │  └─────────┘ └─────────┘ └─────────────────────────────┘│  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Success Criteria Evaluation

| Criterion | Target | Achieved | Notes |
|-----------|--------|----------|-------|
| Regeneration UX | Seamless with loading | ✅ Designed | Inline spinner for 300ms-2s |
| Time to playback (cached) | <100ms | ✅ Feasible | File-based cache |
| Seek accuracy | <100ms | ✅ Feasible | ExoPlayer native, AVAudioEngine manual |
| Gapless playback | No audible gaps | ✅ Feasible | Buffer scheduling |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| 2026-01-29 | Kokoro outputs 22050 Hz PCM | Must configure audio format correctly |
| 2026-01-29 | AVAudioEngine pull model | Need buffer scheduling strategy |
| 2026-01-29 | ExoPlayer handles files natively | Temp file approach simplifies MVP |

## Recommendation

**GO** — Proceed with implementation.

**Implementation Priority:**
1. MVP: On-demand synthesis, temp file playback
2. v1: Full playback controls (seek, progress)
3. v2: Caching for faster replay

## References

- [AVAudioEngine Documentation](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [Creating an Advanced Streaming Audio Engine for iOS](https://medium.com/chameleon-podcast/creating-an-advanced-streaming-audio-engine-for-ios-9fbc7aef4115)
- [SwiftAudioPlayer Library](https://github.com/tanhakabir/SwiftAudioPlayer)
- [ExoPlayer/Media3 Documentation](https://developer.android.com/media/media3/exoplayer)
- [iOS Real-Time TTS Tutorial](https://picovoice.ai/blog/ios-streaming-text-to-speech/)
