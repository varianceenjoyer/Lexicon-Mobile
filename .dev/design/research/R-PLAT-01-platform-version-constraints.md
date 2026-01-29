---
id: R-PLAT-01
type: research
status: complete
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

Research complete. Minimum platform versions determined based on framework feature requirements and market share analysis.

**Recommendations:**
- **iOS:** Minimum iOS 14.0 (excludes <5% of devices)
- **Android:** Minimum API 26 with Compose 1.5+ (reaches 94.8% of devices)

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

## Research Findings

### EC-1: SwiftUI Version Requirements

#### iOS Version Market Share (2026)

Based on [TelemetryDeck](https://telemetrydeck.com/survey/apple/iOS/majorSystemVersions/) and [Statcounter](https://gs.statcounter.com/ios-version-market-share/) data:

| iOS Version | Market Share | Cumulative |
|-------------|--------------|------------|
| iOS 18+ | ~70% | 70% |
| iOS 17 | ~13% | 83% |
| iOS 16 | ~10% | 93% |
| iOS 15 | ~4% | 97% |
| iOS 14 | ~2% | 99% |
| iOS 13 | <1% | ~100% |

**Analysis:** iOS 14+ covers approximately **95%+** of active devices.

#### SwiftUI Feature Requirements

| Feature | iOS 13 | iOS 14 | Required for Lexicon? |
|---------|--------|--------|----------------------|
| @StateObject | ✗ | ✓ | **Yes** - ViewModel lifecycle |
| LazyVStack | ✗ | ✓ | **Yes** - Chat bubbles (performance) |
| ScrollViewReader | ✗ | ✓ | **Yes** - Auto-scroll to latest message |
| onChange(of:) | ✗ | ✓ | **Yes** - State change reactions |
| ProgressView | ✗ | ✓ | **Yes** - Loading indicators |
| @FocusState | ✗ | ✓ (iOS 15) | Nice-to-have |
| searchable() | ✗ | ✗ (iOS 15) | Workaround available |

**iOS 13 Workaround Cost Analysis:**

| Feature | Workaround | Effort | Risk |
|---------|------------|--------|------|
| @StateObject | Manual onAppear init | Medium | Memory leaks |
| LazyVStack | UITableView wrapper | High | Performance issues |
| ScrollViewReader | UIScrollView wrapper | High | Integration bugs |
| onChange(of:) | Combine + onReceive | Medium | Complexity |

**Conclusion:** iOS 13 support requires significant UIKit wrappers for <1% market share. Not justified.

#### Recommendation: iOS 14.0 Minimum

**Rationale:**
- All critical SwiftUI features available
- ~95% device coverage
- No UIKit wrapper complexity
- Future iOS 15 features accessible via `@available` checks

### EC-3: Jetpack Compose Version Requirements

#### Android API Distribution (October 2025)

Based on [apilevels.com](https://apilevels.com/) data:

| API Level | Android Version | Cumulative Usage |
|-----------|-----------------|------------------|
| API 34+ | Android 14+ | 49.4% |
| API 33+ | Android 13+ | 64.4% |
| API 30+ | Android 11+ | 84.4% |
| API 28+ | Android 9+ | 91.8% |
| API 26+ | Android 8+ | **94.8%** |

**Analysis:** API 26 minimum reaches **94.8%** of Android devices.

#### Compose Feature Requirements

| Feature | Compose 1.0 | Compose 1.5+ | Required? |
|---------|-------------|--------------|-----------|
| LazyColumn | ✓ | ✓ | Yes |
| Material 3 | ✗ | ✓ | Recommended |
| Pull-to-refresh | ✗ | ✓ | Yes (File list) |
| WindowInsets | ✗ | ✓ | Yes (Edge-to-edge) |

**Compose BOM Recommendation:** `2024.01.00` or later (Compose 1.6.x)

#### Recommendation: API 26 + Compose 1.5+

**Rationale:**
- API 26 reaches 94.8% of Android devices
- Compose 1.5+ provides Material 3 and modern features
- Compose works on API 21+, so no Compose-specific limitation
- Aligns with project.md specification

### EC-4: Platform API Dependencies

#### Audio APIs

| Platform | API | Minimum Version | Status |
|----------|-----|-----------------|--------|
| iOS | AVAudioEngine | iOS 8+ | ✅ Available on iOS 14 |
| iOS | AVAudioSession | iOS 3+ | ✅ Available on iOS 14 |
| Android | AAudio | API 26 | ✅ Available on API 26 |
| Android | AudioRecord | API 1 | ✅ Available on API 26 |

#### File Access APIs

| Platform | API | Minimum Version | Notes |
|----------|-----|-----------------|-------|
| iOS | UIDocumentPickerViewController | iOS 8+ | ✅ Available |
| Android | Storage Access Framework | API 19 | ✅ Available |
| Android | Scoped Storage | API 30 | Handle via `requestLegacyExternalStorage` on API 29, required on API 30+ |

**Scoped Storage Note:** For API 26-29, can use legacy storage. For API 30+, must use MediaStore or SAF. Implementation should use SAF for file import to be future-proof.

## Final Recommendations

| Platform | Minimum Version | Market Coverage | Rationale |
|----------|-----------------|-----------------|-----------|
| **iOS** | 14.0 | ~95% | SwiftUI features (LazyVStack, @StateObject) |
| **Android** | API 26 | 94.8% | Per project.md, good coverage |
| **Compose** | 1.5+ (BOM 2024.01.00) | N/A | Material 3, modern features |

### Info.plist / build.gradle Configuration

**iOS (Info.plist / Xcode):**
```
Minimum Deployment Target: iOS 14.0
```

**Android (build.gradle.kts):**
```kotlin
android {
    defaultConfig {
        minSdk = 26
        targetSdk = 34  // Current Play Store requirement
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2024.01.00")
    implementation(composeBom)
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
}
```

## Success Criteria Evaluation

| Criterion | Target | Achieved |
|-----------|--------|----------|
| iOS minimum version | Justified with feature analysis | ✅ iOS 14 |
| Compose version | Selected with rationale | ✅ Compose 1.5+ |
| Market coverage | >90% | ✅ ~95% both platforms |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| 2026-01-29 | iOS 13 <1% market share | Not worth workaround effort |
| 2026-01-29 | API 26 = 94.8% Android coverage | Good reach for minimum |
| 2026-01-29 | Scoped Storage required API 30+ | Use SAF for file import |

## Recommendation

**GO** — Proceed with iOS 14.0 minimum and API 26 minimum.

## References

- [TelemetryDeck iOS Version Stats](https://telemetrydeck.com/survey/apple/iOS/majorSystemVersions/)
- [Statcounter iOS Market Share](https://gs.statcounter.com/ios-version-market-share/)
- [apilevels.com - Android Distribution](https://apilevels.com/)
- [Jetpack Compose BOM](https://developer.android.com/jetpack/compose/bom)
- [SwiftUI Availability](https://developer.apple.com/documentation/swiftui)
