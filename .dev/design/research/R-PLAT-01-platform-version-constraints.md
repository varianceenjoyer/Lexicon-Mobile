---
id: R-PLAT-01
type: research
status: in-progress
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: Platform Version Constraints
priority: medium
tags: [ios, android, swiftui, jetpack-compose, api-level, arm32, compatibility]
---

# R-PLAT-01: Platform Version Constraints Feasibility

## Summary

Research plan for validating minimum platform version targets for Lexicon Mobile. Focus areas: SwiftUI limitations on iOS 13 vs iOS 14+, and Android API 26 implications for 32-bit ARM device support and Rust cross-compilation.

## Context

Project targets:
- iOS 13+ with SwiftUI
- Android API 26+ with Jetpack Compose

These minimum versions were chosen for broad device coverage, but may conflict with:
- Modern SwiftUI APIs required for the UI design
- 32-bit ARM Rust compilation for ML inference
- Platform audio APIs needed for real-time capture

This research determines if minimum versions should be raised or if workarounds exist.

## Engineering Challenges

### EC-1: SwiftUI on iOS 13

**Problem Statement:**
SwiftUI was introduced in iOS 13 with significant limitations. Are iOS 14+ features required for Lexicon Mobile, or can iOS 13 be realistically supported?

**SwiftUI Feature Availability:**

| Feature | iOS 13 | iOS 14 | iOS 15 | iOS 16 | Used In Lexicon? |
|---------|--------|--------|--------|--------|------------------|
| Basic Views (VStack, HStack, etc.) | ✓ | ✓ | ✓ | ✓ | Yes |
| @State, @Binding | ✓ | ✓ | ✓ | ✓ | Yes |
| @ObservedObject | ✓ | ✓ | ✓ | ✓ | Yes |
| @StateObject | ✗ | ✓ | ✓ | ✓ | Likely needed |
| @EnvironmentObject | ✓ | ✓ | ✓ | ✓ | Yes |
| LazyVStack/LazyHStack | ✗ | ✓ | ✓ | ✓ | Chat bubbles |
| ScrollViewReader | ✗ | ✓ | ✓ | ✓ | Auto-scroll chat |
| onChange(of:) | ✗ | ✓ | ✓ | ✓ | State reactions |
| @AppStorage | ✗ | ✓ | ✓ | ✓ | Settings |
| ProgressView | ✗ | ✓ | ✓ | ✓ | Loading states |
| Label | ✗ | ✓ | ✓ | ✓ | Accessibility |
| @FocusState | ✗ | ✗ | ✓ | ✓ | Text editing |
| searchable() | ✗ | ✗ | ✓ | ✓ | File search |
| swipeActions() | ✗ | ✗ | ✓ | ✓ | Delete gesture |
| AsyncImage | ✗ | ✗ | ✓ | ✓ | Not needed |
| NavigationStack | ✗ | ✗ | ✗ | ✓ | Navigation |

**Specific Questions:**
- [ ] Which iOS 14+ features are essential vs nice-to-have?
- [ ] Can `@StateObject` be replaced with `@ObservedObject` + manual lifecycle?
- [ ] Can `LazyVStack` be polyfilled or replaced for iOS 13?
- [ ] What's the iOS 13 device population in 2026?
- [ ] Does dropping iOS 13 significantly reduce potential users?
- [ ] Are there iOS 13 SwiftUI bugs that would cause problems?

**iOS 13 Workarounds:**

| Missing Feature | Workaround | Complexity |
|-----------------|------------|------------|
| @StateObject | onAppear init + @ObservedObject | Medium |
| LazyVStack | UIKit UITableView wrapper | High |
| ScrollViewReader | UIKit UIScrollView wrapper | High |
| onChange(of:) | Combine publisher + onReceive | Medium |
| ProgressView | Custom view | Low |
| searchable() | Custom search bar | Medium |
| swipeActions() | Custom gesture | Medium |

**Research Actions:**
- [ ] Audit all SwiftUI features needed for Lexicon Mobile UI
- [ ] Identify which features have no iOS 13 workaround
- [ ] Estimate development cost of iOS 13 workarounds
- [ ] Research iOS 13 market share (App Store analytics, third-party data)
- [ ] Build prototype UI targeting iOS 13 to validate feasibility
- [ ] Recommend minimum iOS version with rationale

**iOS Version Market Share (to be validated):**

| Version | Approx. Share (2026) | Devices |
|---------|---------------------|---------|
| iOS 17+ | ~70% | iPhone XS and newer |
| iOS 16 | ~15% | iPhone 8 and newer |
| iOS 15 | ~10% | iPhone 6s and newer |
| iOS 14 | ~4% | iPhone 6s and newer |
| iOS 13 | ~1% | iPhone 6s and newer |

### EC-2: Android API 26 and 32-bit ARM

**Problem Statement:**
Android API 26 (Android 8.0) includes devices with 32-bit ARM processors. Is Rust cross-compilation for `armv7` tested with Whisper/Kokoro ML libraries?

**Android Architecture Distribution:**

| Architecture | API 26+ Devices | Notes |
|--------------|-----------------|-------|
| arm64-v8a (aarch64) | ~95% | Modern devices, 64-bit |
| armeabi-v7a (armv7) | ~5% | Older/budget devices, 32-bit |
| x86_64 | <1% | Emulators, Chromebooks |
| x86 | <1% | Old emulators |

**Specific Questions:**
- [ ] Does whisper.cpp compile for armv7-linux-androideabi?
- [ ] Does Kokoro TTS compile for armv7?
- [ ] What's the performance penalty on 32-bit vs 64-bit?
- [ ] Are there memory limitations on 32-bit (4GB address space)?
- [ ] What percentage of API 26 devices are 32-bit only?
- [ ] Would dropping armv7 significantly reduce reach?

**32-bit ARM Concerns:**

| Concern | Impact | Mitigation |
|---------|--------|------------|
| 4GB address space | May limit model size | Use smaller models |
| No 64-bit SIMD (NEON) | Slower inference | Accept or drop support |
| Older CPUs | Slower overall | Accept or drop support |
| Rust target support | May have issues | Test thoroughly |
| NDK toolchain | Deprecated path | Use modern NDK |

**Research Actions:**
- [ ] Attempt armv7 Rust build with whisper.cpp bindings
- [ ] Test armv7 build on actual 32-bit Android device
- [ ] Measure inference performance: armv7 vs aarch64
- [ ] Research API 26 32-bit-only device population
- [ ] Evaluate effort to support vs benefit of 32-bit
- [ ] Recommend architecture support matrix

### EC-3: Jetpack Compose Version Requirements

**Problem Statement:**
Jetpack Compose has evolved significantly. Which Compose version is needed for Lexicon Mobile features, and what Android API does it require?

**Compose Feature Availability:**

| Feature | Compose 1.0 | Compose 1.2+ | Compose 1.5+ | Used In Lexicon? |
|---------|-------------|--------------|--------------|------------------|
| Basic layouts | ✓ | ✓ | ✓ | Yes |
| LazyColumn/LazyRow | ✓ | ✓ | ✓ | Chat bubbles |
| Material 3 | ✗ | Partial | ✓ | Recommended |
| Pull-to-refresh | ✗ | ✓ | ✓ | File list |
| WindowInsets | ✗ | ✓ | ✓ | Edge-to-edge |
| Paging 3 integration | ✗ | ✓ | ✓ | Large file lists |

**Android API vs Compose:**

| Compose Version | Min Android API | Notes |
|-----------------|-----------------|-------|
| 1.0.x | API 21 | Initial release |
| 1.2.x | API 21 | Stable improvements |
| 1.5.x | API 21 | Material 3 stable |
| 1.6.x | API 21 | Latest stable |

**Specific Questions:**
- [ ] Which Compose version provides all needed features?
- [ ] Are there API 26 specific behaviors that affect Compose?
- [ ] Does Compose Material 3 work well on API 26 devices?
- [ ] What's the Compose library size impact on APK?

**Research Actions:**
- [ ] Audit Compose features needed for Lexicon Mobile UI
- [ ] Test Compose UI on API 26 emulator/device
- [ ] Verify Material 3 theming on older Android versions
- [ ] Measure Compose library contribution to APK size
- [ ] Document any API 26 specific quirks or workarounds

### EC-4: Platform API Dependencies

**Problem Statement:**
Do audio capture and file access APIs work correctly on minimum supported versions?

**API Availability:**

| API | iOS 13 | iOS 14+ | API 26 | API 28+ |
|-----|--------|---------|--------|---------|
| AVAudioEngine | ✓ | ✓ | N/A | N/A |
| AVAudioSession | ✓ | ✓ | N/A | N/A |
| AAudio | N/A | N/A | ✓ | ✓ (improved) |
| MediaRecorder | N/A | N/A | ✓ | ✓ |
| Files app integration | ✓ | ✓ | N/A | N/A |
| Storage Access Framework | N/A | N/A | ✓ | ✓ |
| Scoped Storage | N/A | N/A | Optional | Required (API 30) |

**Specific Questions:**
- [ ] Are there AAudio bugs on API 26-27 that affect recording?
- [ ] Does Scoped Storage impact file import on API 30+?
- [ ] Are there iOS 13 AVAudioEngine issues to be aware of?

**Research Actions:**
- [ ] Test audio capture on minimum version devices/emulators
- [ ] Verify file picker/import on all target versions
- [ ] Document platform-specific code paths if needed
- [ ] Identify must-have vs nice-to-have platform features

## Decision Framework

**Minimum Version Recommendation Criteria:**

| Factor | Weight | Consideration |
|--------|--------|---------------|
| User reach | High | % of potential users excluded |
| Development cost | High | Workaround complexity |
| Maintenance burden | Medium | Ongoing version-specific code |
| Feature parity | Medium | Can we deliver same UX? |
| Performance | Medium | Acceptable on older devices? |

**Proposed Decision Matrix:**

| Platform | Option A (Broader) | Option B (Moderate) | Option C (Modern) |
|----------|-------------------|---------------------|-------------------|
| iOS | iOS 13 | iOS 14 | iOS 15 |
| Android | API 26 + armv7 | API 26 arm64 only | API 28 arm64 |
| Trade-off | Max reach, high dev cost | Good reach, moderate cost | Lower reach, low cost |

## Success Criteria

| Criterion | Target |
|-----------|--------|
| iOS minimum version | Justified with market data |
| Android minimum API | Justified with market data |
| armv7 decision | Clear go/no-go with rationale |
| Workaround inventory | Complete for chosen minimum |
| Prototype validation | UI works on minimum versions |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| | | |

## Recommendation

**Status:** PENDING RESEARCH

## References

- [SwiftUI Availability](https://developer.apple.com/documentation/swiftui)
- [iOS Version Stats](https://developer.apple.com/support/app-store/) - Apple official
- [Android Version Distribution](https://apilevels.com/) - Community tracker
- [Jetpack Compose Releases](https://developer.android.com/jetpack/androidx/releases/compose)
- [Android NDK ABIs](https://developer.android.com/ndk/guides/abis)
- [Rust Android Targets](https://doc.rust-lang.org/rustc/platform-support.html)

## Next Agent Actions

1. Start with EC-1 (SwiftUI iOS 13) - has most direct impact on UI development
2. Research current iOS version market share data
3. Prototype key UI screens targeting iOS 13 to find blockers
4. EC-2 (armv7) can proceed in parallel with build testing
5. Make version recommendations based on cost/benefit analysis
6. Update this document with findings as you progress
