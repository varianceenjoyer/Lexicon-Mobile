---
id: R-PLAT-01
type: research
status: in-progress
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: Platform Version Constraints — UI Framework Decisions
priority: medium
tags: [ios, android, swiftui, jetpack-compose, api-level, compatibility]
scope: mobile-specific
---

# R-PLAT-01: Platform Version Constraints — UI Framework Decisions

## Summary

Research plan for determining minimum platform versions for Lexicon Mobile UI development. Focus is on **SwiftUI feature availability** and **Jetpack Compose requirements** — pure mobile UI decisions.

## Context: What Local Server Handles

Per [Lexicon Local Server Roadmap](~/projects/Lexicon-Local-Server/.dev/design/roadmap.md):

| Work Package | Status | What It Handles |
|--------------|--------|-----------------|
| **WP-ANDROID** | 🔄 Partial | STT+TTS working, architecture targets |
| **WP-IOS** | ⬜ Ready | iOS build targets |

**NOT mobile UI's concern:**
- ~~EC-2 (armv7 builds)~~ → WP-ANDROID handles Rust cross-compilation
- Build target selection is a Local Server decision

**Mobile UI's responsibility:** Choosing minimum OS versions that support required UI framework features.

## Mobile-Specific Engineering Challenges

### EC-1: SwiftUI Version Requirements

**Problem Statement:**
SwiftUI has significant feature gaps between iOS 13, 14, and 15. Which minimum version provides the features Lexicon Mobile needs?

**SwiftUI Feature Availability:**

| Feature | iOS 13 | iOS 14 | iOS 15 | Used In Lexicon? |
|---------|--------|--------|--------|------------------|
| Basic Views | ✓ | ✓ | ✓ | Yes |
| @State, @Binding | ✓ | ✓ | ✓ | Yes |
| @ObservedObject | ✓ | ✓ | ✓ | Yes |
| **@StateObject** | ✗ | ✓ | ✓ | **Yes - ViewModel lifecycle** |
| **LazyVStack** | ✗ | ✓ | ✓ | **Yes - Chat bubbles** |
| **ScrollViewReader** | ✗ | ✓ | ✓ | **Yes - Auto-scroll chat** |
| **onChange(of:)** | ✗ | ✓ | ✓ | **Yes - State reactions** |
| ProgressView | ✗ | ✓ | ✓ | Yes - Loading states |
| @FocusState | ✗ | ✗ | ✓ | Nice-to-have |
| searchable() | ✗ | ✗ | ✓ | File search (can workaround) |
| swipeActions() | ✗ | ✗ | ✓ | Delete gesture (can workaround) |

**Analysis:**
- iOS 13 requires UIKit wrappers for `LazyVStack` and `ScrollViewReader` — significant effort
- iOS 14 provides all critical features
- iOS 15 adds conveniences but not blockers

**Specific Questions:**
- [ ] What's iOS 13 market share in 2026? (Likely <2%)
- [ ] Is the development cost of iOS 13 workarounds justified?
- [ ] Does iOS 14 provide everything needed for Chat View?
- [ ] Are there iOS 14 SwiftUI bugs that affect our use cases?

**Research Actions:**
- [ ] Research current iOS version market share data
- [ ] Prototype Chat View with LazyVStack + ScrollViewReader (iOS 14)
- [ ] Prototype Note View with @StateObject lifecycle
- [ ] Verify all required features work on iOS 14 simulator
- [ ] Make minimum version recommendation with rationale

**Preliminary Recommendation:** iOS 14+ (pending validation)

### EC-3: Jetpack Compose Version Requirements

**Problem Statement:**
Which Jetpack Compose version provides the features needed for Lexicon Mobile Android?

**Compose Feature Availability:**

| Feature | Compose 1.0 | Compose 1.2+ | Compose 1.5+ | Used In Lexicon? |
|---------|-------------|--------------|--------------|------------------|
| Basic layouts | ✓ | ✓ | ✓ | Yes |
| LazyColumn/LazyRow | ✓ | ✓ | ✓ | Yes - Chat bubbles |
| Material 3 | ✗ | Partial | ✓ | Recommended |
| Pull-to-refresh | ✗ | ✓ | ✓ | File list |
| WindowInsets | ✗ | ✓ | ✓ | Edge-to-edge |

**Android API vs Compose:**

| Compose Version | Min Android API |
|-----------------|-----------------|
| 1.0.x - 1.6.x | API 21 |

Compose itself supports API 21+, so the API level decision is independent of Compose version.

**Specific Questions:**
- [ ] Which Compose version should we target? (1.5+ for Material 3)
- [ ] Does API 26 have Compose-specific quirks?
- [ ] What's the Compose library size impact on APK?

**Research Actions:**
- [ ] Test Compose UI on API 26 emulator
- [ ] Verify Material 3 theming works on API 26
- [ ] Measure Compose library contribution to APK size
- [ ] Document any API 26 specific issues

**Preliminary Recommendation:** Compose 1.5+ with API 26 minimum

### EC-4: Platform API Dependencies

**Problem Statement:**
Do audio capture and file access APIs work correctly on minimum supported versions?

**API Availability:**

| API | iOS 14 | iOS 15+ | API 26 | API 28+ |
|-----|--------|---------|--------|---------|
| AVAudioEngine | ✓ | ✓ | N/A | N/A |
| AVAudioSession | ✓ | ✓ | N/A | N/A |
| AAudio | N/A | N/A | ✓ | ✓ (improved) |
| Storage Access Framework | N/A | N/A | ✓ | ✓ |
| Scoped Storage | N/A | N/A | Optional | Required (API 30) |

**Research Actions:**
- [ ] Test audio capture on iOS 14 simulator/device
- [ ] Test audio capture on API 26 emulator/device
- [ ] Verify file picker/import on all target versions
- [ ] Document any platform-specific code paths needed

## Decision Framework

| Factor | Weight | Consideration |
|--------|--------|---------------|
| User reach | High | % of potential users excluded |
| Development cost | High | Workaround complexity |
| Feature parity | Medium | Can we deliver same UX? |

**Proposed Minimum Versions:**

| Platform | Recommended | Rationale |
|----------|-------------|-----------|
| iOS | 14.0 | SwiftUI features (LazyVStack, @StateObject) |
| Android | API 26 | Per project.md, Compose compatible |

## Success Criteria

| Criterion | Target |
|-----------|--------|
| iOS minimum version | Justified with feature analysis |
| Compose version | Selected with rationale |
| Prototype validation | UI works on minimum versions |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| | | |

## Recommendation

**Status:** PENDING RESEARCH — UI framework decisions only

## References

- [SwiftUI Availability](https://developer.apple.com/documentation/swiftui)
- [iOS Version Stats](https://developer.apple.com/support/app-store/)
- [Jetpack Compose Releases](https://developer.android.com/jetpack/androidx/releases/compose)
- [Android Version Distribution](https://apilevels.com/)

## Next Agent Actions

1. Research current iOS version market share
2. Prototype Chat View with iOS 14 SwiftUI features
3. Test Compose UI on API 26 Android
4. Make final minimum version recommendations
5. Update this document with findings
