---
id: R-DIAR-01
type: research
status: in-progress
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: Diarization System
priority: high
tags: [diarization, speaker-id, pyannote, whisper, sherpa-onnx, streaming, real-time]
---

# R-DIAR-01: Diarization System Feasibility

## Summary

Research plan for validating speaker diarization feasibility for Lexicon Mobile's Chat View. Focus areas: algorithm selection for on-device mobile use, streaming vs batch processing for real-time bubble display, and multi-speaker handling when UI collapses to two-sided display.

## Context

Chat View (CV-02 through CV-07) requires diarized transcription with:
- Live bubble display as segments arrive (CV-04)
- Speaker alignment based on `speaker_id % 2` (CV-03)
- Visual distinction between speakers (CV-05)

The project notes diarization is "configurable" (Decision D3) but doesn't specify which algorithm. Mobile constraints (resource limits, real-time latency) significantly narrow viable options.

## Engineering Challenges

### EC-1: Algorithm Selection

**Problem Statement:**
Which diarization algorithms (pyannote, whisper-clustering, sherpa-onnx) are viable for real-time mobile use? What are their on-device resource requirements?

**Specific Questions:**
- [ ] Which diarization algorithms have mobile-compatible implementations?
- [ ] What are the model sizes for each viable algorithm?
- [ ] What's the inference latency per audio chunk?
- [ ] Do any require GPU/NPU, or can they run CPU-only?
- [ ] What's the speaker identification accuracy (DER) for each?
- [ ] Are there licensing restrictions for mobile app distribution?

**Candidate Algorithms:**

| Algorithm | Mobile-Ready? | Model Size | Notes |
|-----------|---------------|------------|-------|
| pyannote/speaker-diarization | Unknown | ~100MB+ | State-of-art, PyTorch-based |
| Whisper + clustering | Partial | Uses existing Whisper | Post-hoc clustering on timestamps |
| sherpa-onnx speaker-id | Yes | ~20-50MB | ONNX format, mobile-optimized |
| NeMo MSDD | Unknown | Large | NVIDIA, may have mobile export |
| Resemblyzer | Partial | ~20MB | Embedding model only |

**Existing Solutions to Investigate:**
- sherpa-onnx speaker diarization examples
- whisper.cpp with speaker embedding extraction
- pyannote ONNX export feasibility
- WebRTC VAD + speaker embedding pipelines

**Research Actions:**
- [ ] Catalog all diarization algorithms with ONNX/mobile support
- [ ] Evaluate sherpa-onnx speaker diarization capabilities
- [ ] Test pyannote ONNX export (if available)
- [ ] Benchmark Whisper-based clustering approach
- [ ] Compare DER (Diarization Error Rate) across candidates
- [ ] Document resource requirements for top candidates
- [ ] Verify licensing for commercial mobile distribution

### EC-2: Streaming vs. Batch Processing

**Problem Statement:**
Can diarization run incrementally on streaming audio, or only on complete recordings? This directly affects Chat View's "live bubbles" requirement.

**Specific Questions:**
- [ ] Which algorithms support online/streaming diarization?
- [ ] For batch-only algorithms, what's the minimum chunk size for usable results?
- [ ] Can speaker embeddings be computed incrementally and clustered periodically?
- [ ] What's the latency from speech-end to speaker-labeled segment?
- [ ] Do speaker IDs remain stable as more audio arrives (ID consistency)?

**Streaming Approaches:**

| Approach | Latency | ID Stability | Complexity |
|----------|---------|--------------|------------|
| True online diarization | Low | High | High (few algorithms) |
| Chunked batch (e.g., 30s windows) | Medium | Medium | Medium |
| Embedding + incremental clustering | Low-Medium | Medium | Medium |
| Full batch, re-diarize on stop | High | High | Low |

**Existing Solutions to Investigate:**
- pyannote streaming pipeline (if available)
- Online speaker change detection
- Incremental clustering algorithms (online k-means, DBSCAN variants)
- Speaker embedding caching for consistency

**Research Actions:**
- [ ] Identify which algorithms have streaming/online modes
- [ ] Test chunked batch approach with 10s, 30s, 60s windows
- [ ] Evaluate speaker ID consistency across chunks
- [ ] Prototype incremental embedding + clustering pipeline
- [ ] Measure end-to-end latency for each approach
- [ ] Document tradeoffs for product decision

**Latency Budget for Live Bubbles:**

```
Speech ends → VAD detects silence → Whisper transcribes → Diarization assigns speaker → UI displays
   |              ~200ms              |      ~500ms       |         ???ms            |   ~50ms
   |______________________________________________ Target: <1000ms total ______________|
```

Diarization budget: ~250ms maximum for live feel

### EC-3: Multi-Speaker Handling

**Problem Statement:**
The UI maps `speaker_id % 2` for left/right alignment. How do diarization algorithms handle 3+ speakers, and what UX implications arise?

**Specific Questions:**
- [ ] How many speakers can each algorithm reliably distinguish?
- [ ] Is the speaker count known in advance, or auto-detected?
- [ ] How are speaker IDs assigned (deterministic, or arbitrary per session)?
- [ ] When 3+ speakers exist, does `% 2` mapping cause confusing UI?
- [ ] Should the app detect >2 speakers and warn the user?
- [ ] Can speakers be merged/split in post-processing?

**UI Implications of `speaker_id % 2`:**

| Actual Speakers | Mapped Display | User Experience |
|-----------------|----------------|-----------------|
| 2 | A=left, B=right | Clear conversation |
| 3 | A=left, B=right, C=left | C mixed with A (confusing) |
| 4 | A=left, B=right, C=left, D=right | Pairs mixed (very confusing) |

**Existing Solutions to Investigate:**
- Speaker count estimation algorithms
- Forced 2-speaker mode in diarization
- Color-coding beyond position (unique colors per speaker)
- Expandable speaker legend UI

**Research Actions:**
- [ ] Test diarization accuracy with 2, 3, 4, 5 speakers
- [ ] Evaluate speaker count auto-detection reliability
- [ ] Prototype forced 2-speaker clustering mode
- [ ] Design UX for >2 speaker scenarios (warning, colors, legend)
- [ ] Document algorithm behavior with speaker count mismatch
- [ ] Recommend default configuration and edge case handling

**Proposed UX for Multi-Speaker:**

```
┌────────────────────────────────────────┐
│ ⚠ Multiple speakers detected (3+)     │
│ Speakers are grouped into two sides.  │
│ [View speaker details] [Dismiss]      │
└────────────────────────────────────────┘
```

## Related Inquiry Areas

- **Speaker labeling:** Project confirmed users can assign names to speaker_id values. How does this integrate with diarization output?
- **Cross-session speaker recognition:** Can the same speaker be recognized across different recordings? (Out of scope for MVP?)
- **Voice activity detection:** Which VAD integrates with chosen diarization approach?
- **Diarization + translation:** If `translate_to_english: true`, does diarization still work?

## Success Criteria

| Criterion | Target | Minimum Viable |
|-----------|--------|----------------|
| Diarization latency | <250ms | <500ms |
| Speaker ID stability | >95% consistent | >85% consistent |
| 2-speaker DER | <15% | <25% |
| 3+ speaker detection | Warn user | Silent fallback |
| Model size | <50MB additional | <100MB additional |

## Findings Log

| Date | Finding | Impact |
|------|---------|--------|
| | | |

## Recommendation

**Status:** PENDING RESEARCH

## References

- [pyannote-audio](https://github.com/pyannote/pyannote-audio) - State-of-art diarization
- [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) - Mobile-optimized speech toolkit
- [Whisper word timestamps](https://github.com/openai/whisper/discussions/104) - Timestamp extraction
- [Speaker Diarization Overview](https://arxiv.org/abs/2101.09624) - Survey paper
- [Resemblyzer](https://github.com/resemble-ai/Resemblyzer) - Speaker embedding library

## Next Agent Actions

1. Start with EC-1 (Algorithm Selection) - determines feasibility of entire feature
2. Focus on sherpa-onnx first as most likely mobile-ready candidate
3. Evaluate if Whisper timestamps + embedding clustering is viable fallback
4. If streaming is required, prioritize EC-2 research in parallel
5. Update this document with findings as you progress
