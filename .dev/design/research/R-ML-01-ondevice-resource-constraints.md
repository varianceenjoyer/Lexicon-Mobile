---
id: R-ML-01
type: research
status: complete
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: On-Device ML Resource Constraints
priority: high
tags: [whisper, kokoro, tts, stt, memory, thermal, model-size, mobile-ml]
provided-by: lexicon-local-server
---

# R-ML-01: On-Device ML Resource Constraints

## Status: COMPLETE — Provided by Lexicon Local Server

This research is **not required** for Lexicon Mobile. All on-device ML resource management is handled by Lexicon Local Server.

## Findings

Per [Lexicon Local Server Roadmap](~/projects/Lexicon-Local-Server/.dev/design/roadmap.md):

| Work Package | Status | Relevance |
|--------------|--------|-----------|
| **WP-MODEL** | ✅ Complete | Device profiling, tier-appropriate model selection |
| **WP-STT** | ✅ Complete | Real-time STT latency <800ms verified |
| **WP-TTS** | ✅ Complete | Kokoro TTS working with platform fallback |
| **WP-IOS/WP-ANDROID** | 🔄 In Progress | Thermal throttling triggers model downgrade |

### What Local Server Provides

1. **Model Size vs. Storage (EC-1)**: WP-MODEL handles model selection based on device capability
2. **Runtime Memory (EC-2)**: Device profiling selects appropriate model tier for available RAM
3. **Thermal Throttling (EC-3)**: WP-IOS and WP-ANDROID implement thermal monitoring with automatic model downgrade
4. **Model Load Time (EC-4)**: "First launch profiles device and downloads tier-appropriate models" (D1 decision)

### Key Metrics Already Validated

| Metric | Target | Status |
|--------|--------|--------|
| STT segment latency | <800ms | ✅ Verified in Beta |
| Model download | Immediate on first launch | ✅ D1 decision implemented |
| TTS quality | MOS 3.0 | ✅ Shipped (known limitation) |

### Mobile Client Responsibility

The mobile client receives **pre-optimized inference** from Lexicon Core. No ML resource management needed.

- Lexicon Core automatically selects models based on device profile
- Thermal management is handled internally
- Mobile app just calls FFI functions and receives results

## Original Engineering Challenges (Resolved)

- ~~EC-1: Model Size vs. Storage~~ → WP-MODEL device profiling
- ~~EC-2: Runtime Memory~~ → WP-MODEL tier selection
- ~~EC-3: Thermal Throttling~~ → WP-IOS/WP-ANDROID thermal monitoring
- ~~EC-4: Model Load Time~~ → WP-MODEL immediate download (D1)

## Recommendation

**GO** — Proceed with mobile development; ML constraints handled by Local Server.

## References

- Lexicon Local Server: `~/projects/Lexicon-Local-Server/`
- WP-MODEL, WP-IOS, WP-ANDROID work packages
- Decision D1: Immediate model download
