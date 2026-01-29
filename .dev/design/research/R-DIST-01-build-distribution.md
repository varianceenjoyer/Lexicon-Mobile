---
id: R-DIST-01
type: research
status: in-progress
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: Build & Distribution
priority: medium
tags: [app-store, play-store, binary-size, ml-models, review, distribution]
---

# R-DIST-01: Build & Distribution Feasibility

## Summary

Research plan for validating app store distribution feasibility for Lexicon Mobile. Focus areas: binary size impact from embedded ML models, App Store and Play Store size thresholds, and compliance considerations for on-device ML model distribution.

## Context

Lexicon Mobile embeds ML models (Whisper STT, Kokoro TTS) directly in the app binary. This significantly inflates app size compared to typical mobile apps. Distribution constraints include:
- App Store: 200MB limit for cellular downloads (without user confirmation)
- Play Store: 150MB baseline APK limit (AAB allows larger with splits)
- User perception: Large apps may deter downloads

Additionally, Apple has specific requirements around on-device ML that may affect App Store review.

## Engineering Challenges

### EC-1: Binary Size

**Problem Statement:**
Embedded ML models inflate app size. What's the projected APK/IPA size, and does it exceed store thresholds?

**Size Budget Analysis:**

| Component | Estimated Size | Notes |
|-----------|---------------|-------|
| Base app (UI, logic) | 10-20 MB | Swift/Kotlin + frameworks |
| Whisper model (tiny) | 25-40 MB | Quantized Q4/Q5 |
| Whisper model (base) | 50-80 MB | Quantized Q4/Q5 |
| Whisper model (small) | 150-250 MB | Quantized Q4/Q5 |
| Kokoro TTS model | 50-100 MB | Estimated, needs validation |
| Diarization model | 20-50 MB | If separate from Whisper |
| SQLite + libs | 2-5 MB | Database engine |
| Rust FFI library | 5-15 MB | Compiled Lexicon Core |
| **Total (tiny)** | **~120-230 MB** | At threshold |
| **Total (base)** | **~150-280 MB** | Exceeds threshold |
| **Total (small)** | **~250-450 MB** | Significantly exceeds |

**Specific Questions:**
- [ ] What are exact model sizes after quantization?
- [ ] Can models be compressed further in the bundle?
- [ ] Does iOS App Thinning help (architecture-specific slices)?
- [ ] Can Android App Bundle (AAB) with splits reduce download size?
- [ ] What's acceptable download size for target users?
- [ ] Should models be downloaded post-install instead of bundled?

**Store Thresholds:**

| Platform | Limit | Type | Consequence |
|----------|-------|------|-------------|
| iOS App Store | 200 MB | Cellular download | Warning shown |
| iOS App Store | 4 GB | Maximum | Hard limit |
| Play Store | 150 MB | Base APK | Must use AAB |
| Play Store | 200 MB | AAB download | Per config |
| Play Store | 2 GB | Maximum | Hard limit |

**Research Actions:**
- [ ] Build release binary and measure actual sizes
- [ ] Test iOS App Thinning effect on download size
- [ ] Test Android AAB with asset packs
- [ ] Compare bundled vs on-demand model download
- [ ] Survey competitor apps with on-device ML for size benchmarks
- [ ] Document size optimization strategies

### EC-2: On-Demand Model Download

**Problem Statement:**
If bundled models exceed size thresholds, can models be downloaded post-install? What's the UX impact?

**Download Strategies:**

| Strategy | First Launch UX | Size Impact | Complexity |
|----------|-----------------|-------------|------------|
| Bundle all | Immediate use | Largest | Low |
| Bundle tiny, download larger | Quick start, upgrade later | Medium | Medium |
| Download all on first launch | Wait before first use | Smallest install | Medium |
| Stream models (chunks) | Progressive capability | Smallest | High |

**Specific Questions:**
- [ ] What's acceptable wait time on first launch?
- [ ] Can we use iOS On-Demand Resources (ODR)?
- [ ] Can we use Android Play Asset Delivery?
- [ ] How do we handle download failures?
- [ ] Can users choose model quality tier?
- [ ] What happens if model download is interrupted?

**Platform Download APIs:**

| Platform | API | Max Size | Background? |
|----------|-----|----------|-------------|
| iOS | On-Demand Resources | 20 GB total | Yes |
| iOS | Background URLSession | Unlimited | Yes |
| Android | Play Asset Delivery | 2 GB per pack | Yes |
| Android | Download Manager | Unlimited | Yes |

**Research Actions:**
- [ ] Prototype iOS On-Demand Resources for models
- [ ] Prototype Android Play Asset Delivery
- [ ] Design first-launch model download UX
- [ ] Implement download progress UI
- [ ] Handle offline/airplane mode scenarios
- [ ] Test download resume after interruption

**First-Launch UX Flow (if download required):**

```
┌────────────────────────────────────────┐
│         Welcome to Lexicon             │
│                                        │
│  To get started, we need to download   │
│  the speech recognition model.         │
│                                        │
│  📦 Whisper Base (75 MB)               │
│  ☁️ Requires WiFi recommended          │
│                                        │
│  [Download Now]  [Use Smaller Model]   │
│                                        │
│  ────────────────────────────── 45%    │
└────────────────────────────────────────┘
```

### EC-3: App Store ML Review Considerations

**Problem Statement:**
Does Apple require disclosure of on-device ML models? Are there compliance considerations for embedded Whisper/Kokoro models?

**Apple Review Considerations:**

| Requirement | Applies? | Action Needed |
|-------------|----------|---------------|
| App Privacy Details | Yes | Disclose data usage |
| ML model disclosure | Maybe | Research required |
| Open source licenses | Yes | Include attributions |
| Export compliance | Maybe | Encryption check |
| Content guidelines | No | Not generating content |

**Specific Questions:**
- [ ] Does Apple require ML model disclosure in App Privacy?
- [ ] Are there restrictions on bundled ML model sizes?
- [ ] Do Whisper/Kokoro licenses allow commercial distribution?
- [ ] Is ECCN classification needed for ML models?
- [ ] Are there accessibility requirements for STT/TTS apps?
- [ ] What metadata is needed for App Store listing?

**License Compliance:**

| Component | License | Commercial OK? | Attribution? |
|-----------|---------|----------------|--------------|
| Whisper | MIT | Yes | Yes |
| whisper.cpp | MIT | Yes | Yes |
| Kokoro | Apache 2.0? | TBD | TBD |
| UniFFI | MPL 2.0 | Yes | Yes |

**Research Actions:**
- [ ] Review Apple's ML/AI app guidelines
- [ ] Verify all model licenses permit commercial use
- [ ] Compile attribution notices for open source
- [ ] Check export compliance (ECCN) requirements
- [ ] Review similar apps' App Store listings for precedent
- [ ] Prepare App Privacy details for STT/TTS functionality

### EC-4: Play Store Considerations

**Problem Statement:**
What Play Store policies affect Lexicon Mobile distribution, particularly around app size and ML functionality?

**Play Store Policies:**

| Policy Area | Relevance | Action |
|-------------|-----------|--------|
| App Bundle requirement | High | Must use AAB for >150MB |
| Asset Delivery | High | For on-demand models |
| Permissions | Medium | Microphone, storage |
| Data Safety | High | Disclose on-device processing |
| Target API level | Medium | Must meet current requirements |

**Specific Questions:**
- [ ] What's the current target API level requirement?
- [ ] Can we use Play Feature Delivery for optional models?
- [ ] What Data Safety disclosures are needed?
- [ ] Are there specific policies for voice/transcription apps?
- [ ] How do we handle 32-bit vs 64-bit APK splits?

**Research Actions:**
- [ ] Review Play Store policies for voice/transcription apps
- [ ] Set up AAB with asset packs for models
- [ ] Prepare Data Safety form responses
- [ ] Test APK splits for architecture-specific builds
- [ ] Verify target API level compliance
- [ ] Research Play Store listing best practices

### EC-5: Update and Model Versioning

**Problem Statement:**
How do we handle app updates when models are bundled? How do we version and update models independently?

**Update Scenarios:**

| Scenario | Strategy | User Impact |
|----------|----------|-------------|
| App update, same models | Normal update | Small download |
| App update, new models | Full download or delta | Large download |
| Model-only update | On-demand refresh | Background download |
| Rollback model | Keep previous version | Storage overhead |

**Specific Questions:**
- [ ] Can models be updated independently of app binary?
- [ ] How do we version models for compatibility?
- [ ] What's the delta update size for model changes?
- [ ] Should users be able to manage model storage?
- [ ] How do we handle model corruption or missing files?

**Research Actions:**
- [ ] Design model versioning scheme
- [ ] Prototype model update mechanism
- [ ] Test delta updates with bundled models
- [ ] Implement model integrity verification
- [ ] Design storage management UI (if needed)
- [ ] Document model update strategy

## Related Inquiry Areas

- **Beta distribution:** TestFlight (iOS) and internal testing (Android) size limits?
- **Enterprise distribution:** Different size constraints for enterprise deployment?
- **Regional considerations:** Different download behaviors in markets with limited bandwidth?
- **Competitor analysis:** How do similar apps (Otter, Whisper apps) handle size?

## Success Criteria

| Criterion | Target | Minimum Viable |
|-----------|--------|----------------|
| iOS download size | <200 MB | <300 MB with warning |
| Android download size | <150 MB base | <200 MB with AAB |
| First-launch to usable | <30s (with download) | <60s |
| Model update size | <50 MB delta | Full re-download OK |
| License compliance | All verified | Critical ones verified |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| | | |

## Recommendation

**Status:** PENDING RESEARCH

## References

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [iOS App Thinning](https://developer.apple.com/documentation/xcode/reducing-your-app-s-size)
- [iOS On-Demand Resources](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/On_Demand_Resources_Guide/)
- [Play Asset Delivery](https://developer.android.com/guide/playcore/asset-delivery)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)
- [Play Store Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Whisper License](https://github.com/openai/whisper/blob/main/LICENSE)

## Next Agent Actions

1. Start with EC-1 (Binary Size) - build release binary and measure
2. Determine if size exceeds thresholds and EC-2 is needed
3. EC-3/EC-4 (Store compliance) can proceed in parallel
4. Compile license information early to avoid surprises
5. Design model download UX if on-demand approach is chosen
6. Update this document with findings as you progress
