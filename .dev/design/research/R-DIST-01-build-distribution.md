---
id: R-DIST-01
type: research
status: in-progress
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: Build & Distribution — App Store Compliance
priority: medium
tags: [app-store, play-store, binary-size, distribution, compliance]
scope: mobile-specific
---

# R-DIST-01: Build & Distribution — App Store Compliance

## Summary

Research plan for app store distribution compliance for Lexicon Mobile. Focus is on **binary size constraints**, **store policy compliance**, and **model delivery strategy** as it affects the mobile app package.

## Context: What Local Server Handles

Per [Lexicon Local Server Roadmap](~/projects/Lexicon-Local-Server/.dev/design/roadmap.md):

| Work Package | Status | What It Handles |
|--------------|--------|-----------------|
| **WP-MODEL** | ✅ Complete | Model management, device profiling, download |
| **WP-BUILD** | ✅ Complete | Build pipeline, distribution |
| **Decision D1** | ✅ Complete | Immediate model download on first launch |

**Local Server provides:**
- Model selection based on device capability
- Model download infrastructure
- Model integrity verification (WP-HASH-VERIFY)

**Mobile's responsibility:** App store packaging, compliance, and first-launch UX for model download.

## Mobile-Specific Engineering Challenges

### EC-1: Binary Size and Store Thresholds

**Problem Statement:**
What's the mobile app binary size without bundled models, and how does this affect app store distribution?

**Size Budget (Mobile App Only):**

| Component | Estimated Size | Notes |
|-----------|---------------|-------|
| iOS app (UI, logic) | 10-15 MB | SwiftUI + frameworks |
| Android app (UI, logic) | 8-12 MB | Compose + Kotlin |
| Lexicon Core library | 5-15 MB | FFI library, no models |
| **Total (no models)** | **~25-40 MB** | Well under thresholds |

**Store Thresholds:**

| Platform | Limit | Our Size | Status |
|----------|-------|----------|--------|
| iOS App Store | 200 MB cellular | ~25-40 MB | ✅ OK |
| Play Store | 150 MB base APK | ~25-40 MB | ✅ OK |

**Key Insight:** Since models are downloaded via Lexicon Core (D1 decision), the app binary itself is small. Models are **not bundled** in the app package.

**Specific Questions:**
- [ ] What's the actual compiled size of Lexicon Core library per platform?
- [ ] Does iOS App Thinning further reduce download size?
- [ ] Does Android App Bundle help with architecture-specific builds?

**Research Actions:**
- [ ] Build release binary and measure actual sizes
- [ ] Verify model download happens outside app bundle
- [ ] Document final app store package sizes

### EC-2: First-Launch Model Download UX

**Problem Statement:**
Since models download on first launch (D1), what UX does the mobile app need to provide?

**User Flow:**

```
App Launch → Check Models → Download Required? → Show Progress → Ready
                                    │
                              (if no models)
                                    │
                                    ▼
                          ┌────────────────────────┐
                          │  Downloading Speech    │
                          │  Recognition Model...  │
                          │                        │
                          │  ████████░░░░ 65%      │
                          │                        │
                          │  [Cancel]              │
                          └────────────────────────┘
```

**Specific Questions:**
- [ ] How does Lexicon Core signal model download progress?
- [ ] What UI should display during download? (modal, inline, splash screen)
- [ ] How do we handle download failures? (retry, offline mode)
- [ ] Can users skip download and use app with limited functionality?

**Research Actions:**
- [ ] Review Lexicon Core FFI for download progress callbacks
- [ ] Design download progress UI for iOS and Android
- [ ] Implement error handling for download failures
- [ ] Test offline/airplane mode scenarios

### EC-3: App Store Compliance

**Problem Statement:**
What App Store and Play Store policies affect Lexicon Mobile?

**Apple App Store Considerations:**

| Requirement | Applies? | Action |
|-------------|----------|--------|
| App Privacy Details | Yes | Disclose on-device processing, microphone usage |
| Data collection | Minimal | Audio processed locally, no cloud upload |
| Open source licenses | Yes | Include attributions for Whisper, Kokoro, UniFFI |
| Export compliance | Check | ML models may need ECCN review |

**Google Play Store Considerations:**

| Requirement | Applies? | Action |
|-------------|----------|--------|
| Data Safety form | Yes | Disclose on-device processing |
| Permissions | Yes | Microphone, storage (for file import) |
| Target API level | Yes | Must meet current requirements (API 34 as of 2026) |
| App Bundle | Recommended | Use AAB for smaller downloads |

**License Compliance:**

| Component | License | Commercial OK? | Attribution Required? |
|-----------|---------|----------------|----------------------|
| Whisper | MIT | Yes | Yes |
| whisper.cpp | MIT | Yes | Yes |
| Kokoro | Apache 2.0 | Yes | Yes |
| UniFFI | MPL 2.0 | Yes | Yes |

**Research Actions:**
- [ ] Prepare App Privacy details for App Store
- [ ] Prepare Data Safety form for Play Store
- [ ] Compile attribution notices
- [ ] Check export compliance (ECCN) for ML models
- [ ] Review target API level requirements

### EC-4: Update Strategy

**Problem Statement:**
How do app updates and model updates interact?

**Update Scenarios:**

| Scenario | App Update? | Model Update? | User Action |
|----------|-------------|---------------|-------------|
| Bug fix | Yes | No | Standard app update |
| New feature | Yes | No | Standard app update |
| Model improvement | No | Yes | Automatic via Lexicon Core |
| Breaking API change | Yes | Maybe | Coordinated release |

**Key Insight:** Lexicon Core handles model updates independently. The mobile app just needs to:
1. Update from app stores as normal
2. Allow Lexicon Core to manage model downloads

**Research Actions:**
- [ ] Confirm model update mechanism in Lexicon Core
- [ ] Design update notification UX if new models available
- [ ] Test app update with unchanged models

## Success Criteria

| Criterion | Target |
|-----------|--------|
| iOS download size | <50 MB (app only) |
| Android download size | <50 MB (app only) |
| First-launch to usable | <60s including model download |
| Store compliance | All requirements met |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| | | |

## Recommendation

**Status:** PENDING RESEARCH — App store packaging only

## References

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Play Store Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)

## Next Agent Actions

1. Build release binaries and measure actual sizes
2. Review Lexicon Core FFI for download progress API
3. Design first-launch download UX
4. Prepare store compliance documentation
5. Update this document with findings
