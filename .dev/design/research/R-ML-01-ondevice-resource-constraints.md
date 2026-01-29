---
id: R-ML-01
type: research
status: in-progress
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: On-Device ML Resource Constraints
priority: high
tags: [whisper, kokoro, tts, stt, memory, thermal, model-size, mobile-ml]
---

# R-ML-01: On-Device ML Resource Constraints

## Summary

Research plan for validating on-device ML feasibility for Lexicon Mobile. Focus areas: model storage footprint, runtime memory consumption, thermal behavior during sustained inference, and model load times against cold start requirements.

## Context

Lexicon Mobile embeds ML models for STT (Whisper) and TTS (Kokoro) to enable fully offline operation. Target devices include low-end hardware (iPhone SE 2 with 3GB RAM, Pixel 4a with 6GB RAM). Performance requirements specify:
- App launch to ready: <2s
- STT segment latency: <800ms
- TTS first audio: <300ms

These constraints must be validated against actual model resource requirements.

## Engineering Challenges

### EC-1: Model Size vs. Storage

**Problem Statement:**
What are the actual model file sizes for Whisper (tiny/base/small) and Kokoro TTS? What's the minimum viable footprint for acceptable quality?

**Specific Questions:**
- [ ] What are the file sizes for Whisper tiny, base, small, and medium models?
- [ ] What is the Kokoro TTS model size?
- [ ] Can models be quantized (INT8, INT4) to reduce size without unacceptable quality loss?
- [ ] What's the total storage footprint (models + app + database buffer)?
- [ ] Does this exceed App Store (200MB cellular) or Play Store (150MB APK) thresholds?

**Existing Solutions to Investigate:**
- whisper.cpp quantized model variants (Q4, Q5, Q8)
- ONNX Runtime quantization for mobile
- Apple Core ML model compression
- Android NNAPI optimized formats

**Research Actions:**
- [ ] Catalog Whisper model sizes across all variants and quantization levels
- [ ] Identify Kokoro TTS model size and quantization options
- [ ] Benchmark transcription quality: tiny vs base vs small (WER comparison)
- [ ] Benchmark TTS quality across quantization levels (MOS or ABX testing)
- [ ] Calculate minimum viable bundle size for each quality tier
- [ ] Document model download/update strategy (bundled vs on-demand)

**Reference Data (to be validated):**

| Model | FP16 Size | Q8 Size | Q4 Size |
|-------|-----------|---------|---------|
| Whisper tiny | ~75MB | ~40MB | ~25MB |
| Whisper base | ~150MB | ~80MB | ~50MB |
| Whisper small | ~500MB | ~250MB | ~150MB |
| Kokoro TTS | TBD | TBD | TBD |

### EC-2: Runtime Memory

**Problem Statement:**
What's peak RAM usage during STT and TTS inference? Can low-end devices (3GB RAM) run inference with acceptable headroom?

**Specific Questions:**
- [ ] What's peak RAM during Whisper inference for each model size?
- [ ] What's peak RAM during Kokoro TTS synthesis?
- [ ] Can STT and TTS run concurrently, or must they be serialized?
- [ ] How much RAM does iOS/Android reserve for system (typical: 1-1.5GB)?
- [ ] What's the app baseline RAM (UI, audio buffers, SQLite)?
- [ ] Is there risk of OOM kills on low-end devices during inference?

**Existing Solutions to Investigate:**
- whisper.cpp memory-mapped model loading
- ONNX Runtime memory arena configuration
- iOS memory pressure handling (`didReceiveMemoryWarning`)
- Android `onTrimMemory()` callbacks

**Research Actions:**
- [ ] Profile Whisper inference RAM on iOS simulator and Android emulator
- [ ] Profile on actual low-end devices (iPhone SE 2, Pixel 4a)
- [ ] Measure baseline app RAM without inference
- [ ] Calculate available headroom after OS and app baseline
- [ ] Test concurrent STT + TTS if architecturally required
- [ ] Document memory optimization strategies if headroom is tight

**Target Devices Memory Budget:**

| Device | Total RAM | Est. OS Reserved | Est. Available |
|--------|-----------|------------------|----------------|
| iPhone SE 2 | 3GB | ~1.2GB | ~1.8GB |
| Pixel 4a | 6GB | ~1.5GB | ~4.5GB |
| iPhone 12 | 4GB | ~1.3GB | ~2.7GB |
| Pixel 7 | 8GB | ~1.5GB | ~6.5GB |

### EC-3: Thermal Throttling

**Problem Statement:**
During sustained recording (10+ minutes), do continuous Whisper inferences cause thermal throttling that degrades latency past the 800ms target?

**Specific Questions:**
- [ ] What's the inference frequency during continuous recording (every N seconds)?
- [ ] Does CPU/GPU temperature rise significantly over 10+ minute sessions?
- [ ] At what point does thermal throttling engage on target devices?
- [ ] How much does inference latency degrade under thermal throttling?
- [ ] Can workload be distributed to avoid thermal hotspots (CPU vs GPU vs ANE)?

**Existing Solutions to Investigate:**
- Apple Neural Engine (ANE) for sustained workloads
- Android NNAPI delegate selection (GPU, NNAPI, CPU)
- Inference batching to allow cooling periods
- Dynamic model switching (smaller model when hot)

**Research Actions:**
- [ ] Run 15-minute continuous transcription on low-end devices
- [ ] Monitor CPU/GPU temperature during session
- [ ] Log inference latency over time (detect degradation)
- [ ] Compare CPU-only vs GPU-accelerated vs ANE/NNAPI
- [ ] Test thermal behavior with different chunk sizes/intervals
- [ ] Document mitigation strategies if throttling is significant

**Thermal Test Protocol:**
1. Device at room temperature, fully charged
2. Start continuous recording with STT
3. Log: timestamp, inference latency, CPU temp (if accessible)
4. Continue for 15 minutes minimum
5. Plot latency vs time, identify throttling onset

### EC-4: Model Load Time

**Problem Statement:**
Can models load in <2s on cold start (per performance requirements), or is lazy/background loading required?

**Specific Questions:**
- [ ] What's the cold-start model load time for Whisper on target devices?
- [ ] What's the cold-start model load time for Kokoro TTS?
- [ ] Does memory-mapped loading reduce perceived load time?
- [ ] Can models be loaded in background while showing splash screen?
- [ ] Is lazy loading viable (load on first use, show "Loading..." UI)?
- [ ] Does model caching survive app backgrounding?

**Existing Solutions to Investigate:**
- Memory-mapped file loading (`mmap`)
- Background thread model initialization
- Model warmup (single inference to prime caches)
- iOS app prewarming (`BGAppRefreshTask`)

**Research Actions:**
- [ ] Measure cold start model load time on all target devices
- [ ] Measure warm start (model cached in memory) load time
- [ ] Test memory-mapped vs full-load approaches
- [ ] Implement background loading PoC with loading UI
- [ ] Determine if lazy loading is acceptable UX
- [ ] Document recommended loading strategy

**Load Time Targets:**

| Scenario | Target | Fallback |
|----------|--------|----------|
| Cold start to recording ready | <2s | Show loading indicator |
| Model switch (tiny→base) | <3s | Background load |
| TTS ready after recording | <500ms | Preload during recording |

## Related Inquiry Areas

- **Model selection UX:** Should users choose quality tier, or auto-select based on device capability?
- **Incremental model download:** Can base app ship with tiny model, download larger on WiFi?
- **Hardware acceleration:** Which devices support ANE/NNAPI for Whisper/Kokoro?
- **Battery impact:** What's power consumption during sustained inference?

## Success Criteria

| Criterion | Target | Minimum Viable |
|-----------|--------|----------------|
| Total model size | <150MB | <300MB |
| Peak inference RAM | <1GB | <1.5GB |
| Sustained latency (10 min) | <800ms | <1200ms |
| Cold start to ready | <2s | <4s with loading UI |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| | | |

## Recommendation

**Status:** PENDING RESEARCH

## References

- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) - C++ Whisper implementation
- [Whisper Model Card](https://github.com/openai/whisper/blob/main/model-card.md) - Official model specs
- [ONNX Runtime Mobile](https://onnxruntime.ai/docs/tutorials/mobile/) - Mobile optimization guide
- [Core ML Performance](https://developer.apple.com/documentation/coreml/optimizing_your_core_ml_usage) - Apple ML optimization
- Kokoro TTS repository (to be identified)

## Next Agent Actions

1. Start with EC-1 (Model Size) - foundational for all other constraints
2. Catalog actual model file sizes from whisper.cpp and Kokoro repos
3. Research quantization options and quality tradeoffs
4. If sizes are acceptable, proceed to EC-2 (Runtime Memory) profiling
5. Update this document with findings as you progress
