---
id: R-AUDIO-01
type: research
status: in-progress
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: Real-Time Audio Pipeline — Mobile Platform Integration
priority: medium
tags: [audio, avfoundation, media3, background-audio, interruptions, audio-focus]
scope: mobile-specific
---

# R-AUDIO-01: Real-Time Audio Pipeline — Mobile Platform Integration

## Summary

Research plan for mobile-specific audio capture and interruption handling. Audio routing and resampling scaffolding is provided by Lexicon Local Server; this research focuses on **iOS/Android platform integration** and **interruption handling**.

## Context: What Local Server Provides

Per [Lexicon Local Server Roadmap](~/projects/Lexicon-Local-Server/.dev/design/roadmap.md):

| Work Package | Status | What It Provides |
|--------------|--------|------------------|
| **WP-AUDIO** | 🟡 Scaffolding complete | Mobile audio routes, resampling to 16kHz |
| **WP-BLE** | 🟡 Awaiting hardware test | Bluetooth HFP 1.6 at 16kHz |

**Handled by Local Server:**
- ~~EC-1: Resampling Latency~~ → WP-AUDIO handles 16kHz conversion
- ~~EC-2: Buffer Management~~ → WP-AUDIO defines chunk sizes for Whisper

**Mobile's responsibility:** Platform-specific audio session management and interruption handling.

## Mobile-Specific Engineering Challenge

### EC-3: Background Audio and Interruptions (Mobile)

**Problem Statement:**
How do iOS audio session interruptions and Android audio focus changes affect active recordings? This is entirely platform-specific behavior that the mobile app must handle.

**Interruption Scenarios:**

| Event | iOS Behavior | Android Behavior | Mobile App Response |
|-------|--------------|------------------|---------------------|
| Incoming call | AVAudioSession interruption | Audio focus loss | Pause recording, save state |
| Siri activation | Interruption | N/A | Pause recording |
| Other app plays audio | Depends on category | Focus loss (duck/pause) | Policy decision needed |
| Alarm/timer | Interruption | Focus loss | Pause recording |
| Notification sound | Usually continues | Usually continues | Continue |
| Headphone disconnect | Route change | Audio device change | Continue (switch to speaker) |
| App backgrounded | Depends on capability | Depends on foreground service | Policy decision needed |

**Specific Questions:**
- [ ] What iOS audio session category should we use? (`playAndRecord` vs `record`)
- [ ] How do we handle `AVAudioSession.interruptionNotification`?
- [ ] Can we resume recording seamlessly after interruption ends?
- [ ] What Android audio focus mode is appropriate? (`AUDIOFOCUS_GAIN` vs `GAIN_TRANSIENT`)
- [ ] How do we handle `OnAudioFocusChangeListener` callbacks?
- [ ] Should the app request background audio capability?
- [ ] What happens to in-progress transcription during interruption?

**iOS Audio Session Configuration:**

```swift
// Configuration options to research
let session = AVAudioSession.sharedInstance()

// Option A: Play and Record (for TTS playback support)
try session.setCategory(.playAndRecord,
                        mode: .measurement,
                        options: [.allowBluetooth, .defaultToSpeaker])

// Option B: Record only
try session.setCategory(.record,
                        mode: .measurement,
                        options: [.allowBluetooth])
```

**Android Audio Focus Configuration:**

```kotlin
// Configuration options to research
val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
    .setAudioAttributes(audioAttributes)
    .setOnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AUDIOFOCUS_LOSS -> pauseRecording()
            AUDIOFOCUS_LOSS_TRANSIENT -> pauseRecording()
            AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> continueRecording() // ?
            AUDIOFOCUS_GAIN -> resumeRecording()
        }
    }
    .build()
```

**Research Actions:**
- [ ] Test iOS audio session categories and their interruption behavior
- [ ] Implement `AVAudioSession.interruptionNotification` handler
- [ ] Test Android audio focus scenarios on real device
- [ ] Implement `OnAudioFocusChangeListener` with proper state management
- [ ] Verify recording can resume without data loss after interruption
- [ ] Test background recording capability on both platforms
- [ ] Document recommended configuration for each platform
- [ ] Design UI feedback for interruption states (banner, icon)

**State Machine for Interruptions:**

```
[Idle] ──(start recording)──▶ [Recording]
                                  │
                           (interruption begin)
                                  │
                                  ▼
                            [Interrupted]
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
             (interruption end)           (user cancels)
                    │                           │
                    ▼                           ▼
              [Resuming]                    [Stopped]
                    │
             (resume complete)
                    │
                    ▼
              [Recording]
```

**Platform Capability Requirements:**

| Capability | iOS | Android |
|------------|-----|---------|
| Background audio | `UIBackgroundModes: audio` | Foreground Service |
| Bluetooth recording | `allowBluetooth` option | Permission + profile |
| Interruption handling | NotificationCenter observer | AudioFocusChangeListener |
| Route change handling | `routeChangeNotification` | AudioDeviceCallback |

## Success Criteria

| Criterion | Target | Minimum Viable |
|-----------|--------|----------------|
| Interruption recovery | Seamless auto-resume | Manual resume with prompt |
| Background recording | Supported | Not required for MVP |
| State preservation | No data loss on interrupt | Partial save OK |
| UI feedback | Real-time status indicator | Toast notification |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| | | |

## Recommendation

**Status:** PENDING RESEARCH — Mobile platform integration only

## References

- [AVAudioSession Programming Guide](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/)
- [Managing Audio Focus (Android)](https://developer.android.com/guide/topics/media-apps/audio-focus)
- [Handling Audio Interruptions (iOS)](https://developer.apple.com/documentation/avfaudio/handling_audio_interruptions)
- [Foreground Services (Android)](https://developer.android.com/guide/components/foreground-services)

## Next Agent Actions

1. Set up minimal iOS audio capture with interruption handling
2. Set up minimal Android audio capture with focus handling
3. Test interruption scenarios on physical devices
4. Document recommended configurations
5. Update this document with findings
