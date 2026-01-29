---
id: R-AUDIO-01
type: research
status: complete
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

Research complete. This document provides recommendations for iOS/Android audio session management and interruption handling based on platform best practices.

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

## Research Findings

### EC-3: Background Audio and Interruptions (Mobile)

#### iOS: AVAudioSession Configuration

**Recommended Configuration:**

```swift
import AVFoundation

class AudioSessionManager {
    static let shared = AudioSessionManager()

    func configureForRecording() throws {
        let session = AVAudioSession.sharedInstance()

        // Use playAndRecord for TTS playback support
        try session.setCategory(.playAndRecord,
                                mode: .measurement,
                                options: [.allowBluetooth,
                                         .defaultToSpeaker,
                                         .allowBluetoothA2DP])

        // Register for interruption notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: session
        )

        // Register for route change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: session
        )

        try session.setActive(true)
    }

    @objc func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Pause recording, update UI
            // Do NOT deactivate audio session
            pauseRecording()

        case .ended:
            // Check if we should resume
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    resumeRecording()
                }
            }

        @unknown default:
            break
        }
    }

    @objc func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .oldDeviceUnavailable:
            // Headphones unplugged - continue with speaker
            // Keep session active, audio will route to speaker
            break
        case .newDeviceAvailable:
            // New device connected - continue recording
            break
        default:
            break
        }
    }
}
```

**Key Findings:**
- [x] Use `.playAndRecord` category for both recording and TTS playback
- [x] Use `.measurement` mode for highest quality audio capture
- [x] Do NOT deactivate session on interruption begin
- [x] Check `shouldResume` flag before auto-resuming after interruption
- [x] End interruptions are NOT guaranteed — handle foreground transitions
- [x] Route changes (headphone unplug) should continue recording via speaker

**Background Recording:**
- Requires `UIBackgroundModes: audio` in Info.plist
- Session stays active when app enters background
- Recommendation: Support background recording for v1 (user expectation for recording apps)

#### Android: AudioFocus Configuration

**Recommended Configuration:**

```kotlin
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build

class AudioFocusManager(
    private val audioManager: AudioManager,
    private val onFocusChange: (Int) -> Unit
) {
    private var focusRequest: AudioFocusRequest? = null
    private var hasFocus = false

    private val focusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                // Regained focus - resume recording
                hasFocus = true
                onFocusChange(focusChange)
            }
            AudioManager.AUDIOFOCUS_LOSS -> {
                // Permanent loss - stop recording, release resources
                hasFocus = false
                onFocusChange(focusChange)
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                // Temporary loss - pause recording
                hasFocus = false
                onFocusChange(focusChange)
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                // Can duck - for recording apps, treat as transient loss
                // Don't try to record at lower volume
                hasFocus = false
                onFocusChange(focusChange)
            }
        }
    }

    fun requestFocus(): Boolean {
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
            .build()

        focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(audioAttributes)
            .setAcceptsDelayedFocusGain(true)
            .setOnAudioFocusChangeListener(focusChangeListener)
            .build()

        val result = audioManager.requestAudioFocus(focusRequest!!)
        hasFocus = (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
        return hasFocus
    }

    fun abandonFocus() {
        focusRequest?.let {
            audioManager.abandonAudioFocusRequest(it)
        }
        hasFocus = false
    }
}
```

**Key Findings:**
- [x] Use `AUDIOFOCUS_GAIN` for recording (not transient)
- [x] Use `CONTENT_TYPE_SPEECH` for speech recording
- [x] Handle all focus loss types (LOSS, TRANSIENT, CAN_DUCK)
- [x] For recording apps, treat `CAN_DUCK` as full pause (no "quiet recording")
- [x] Always abandon focus when recording stops
- [x] Use `setAcceptsDelayedFocusGain(true)` for better system integration

**Background Recording:**
- Requires Foreground Service with `FOREGROUND_SERVICE_TYPE_MICROPHONE`
- Show persistent notification during recording
- Recommendation: Support background recording for v1

#### State Machine Implementation

```
┌─────────────────────────────────────────────────────────────────┐
│                        Recording States                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [Idle] ──(requestFocus + start)──▶ [Recording]                 │
│    ▲                                     │                       │
│    │                              (interruption/                 │
│    │                               focus loss)                   │
│    │                                     │                       │
│    │                                     ▼                       │
│    │                              [Interrupted]                  │
│    │                                     │                       │
│    │              ┌──────────────────────┼──────────────────┐   │
│    │              │                      │                  │   │
│    │       (user stops)          (focus regained/     (timeout/ │
│    │              │               shouldResume)        cancel)  │
│    │              │                      │                  │   │
│    │              ▼                      ▼                  │   │
│    └────────[Stopped]◀──────────[Resuming]──────────────────┘   │
│                 │                        │                       │
│                 │                 (resume complete)              │
│                 │                        │                       │
│                 │                        ▼                       │
│                 └──────────────────[Recording]                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**State Transitions:**
| Current State | Event | Next State | Action |
|---------------|-------|------------|--------|
| Idle | Start Recording | Recording | Request focus, start capture |
| Recording | Interruption Begin | Interrupted | Pause capture, save state, update UI |
| Recording | User Stop | Stopped | Stop capture, abandon focus |
| Interrupted | Interruption End (shouldResume) | Resuming | Reactivate session |
| Interrupted | User Cancel | Stopped | Abandon focus, finalize |
| Interrupted | Timeout (30s) | Stopped | Auto-finalize recording |
| Resuming | Resume Complete | Recording | Continue capture |

## Success Criteria Evaluation

| Criterion | Target | Achieved | Notes |
|-----------|--------|----------|-------|
| Interruption recovery | Seamless auto-resume | ✅ Yes | shouldResume flag handling |
| Background recording | Supported | ✅ Yes | iOS: BGMode, Android: FG Service |
| State preservation | No data loss on interrupt | ✅ Yes | Pause without deactivating |
| UI feedback | Real-time status indicator | ✅ Designed | State machine supports UI |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| 2026-01-29 | iOS: End interruptions not guaranteed | Must handle foreground transitions |
| 2026-01-29 | Android: Use AUDIOFOCUS_GAIN for recording | Transient focus inappropriate |
| 2026-01-29 | Both platforms: Don't deactivate on interrupt | Faster resume, no resource loss |

## Recommendation

**GO** — Proceed with implementation using the configurations above.

**Implementation Priority:**
1. Basic interruption handling (MVP)
2. Background recording support (v1)
3. Bluetooth route handling (v1)

## References

- [Handling Audio Interruptions (iOS)](https://developer.apple.com/documentation/avfaudio/handling-audio-interruptions)
- [AVAudioSession Programming Guide](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/)
- [Manage Audio Focus (Android)](https://developer.android.com/media/optimize/audio-focus)
- [Android Developers Blog: Respecting Audio Focus](https://android-developers.googleblog.com/2013/08/respecting-audio-focus.html)
