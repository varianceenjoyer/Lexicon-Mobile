---
id: R-DIAR-01
type: research
status: complete
created: 2026-01-29
updated: 2026-01-29
author: design-lead
category: Diarization System
priority: high
tags: [diarization, speaker-id, pyannote, whisper, sherpa-onnx, streaming, real-time]
provided-by: lexicon-local-server
---

# R-DIAR-01: Diarization System Feasibility

## Status: COMPLETE — Provided by Lexicon Local Server

This research is **not required** for Lexicon Mobile. Speaker diarization is implemented in Lexicon Local Server's WP-STT.

## Findings

Per [Lexicon Local Server Roadmap](~/projects/Lexicon-Local-Server/.dev/design/roadmap.md):

| Work Package | Status | Relevance |
|--------------|--------|-----------|
| **WP-STT** | 🔄 Diarization in progress | Speaker diarization assigns IDs when enabled |
| **Decision D3** | Configurable diarization | Per-session enable/disable |

### What Local Server Provides

1. **Algorithm Selection (EC-1)**: Local Server team has selected and implemented the diarization algorithm
2. **Streaming vs. Batch (EC-2)**: Implementation approach determined by Local Server architecture
3. **Multi-Speaker Handling (EC-3)**: `speaker_id` is returned in segment data; mobile just displays it

### Mobile Client Responsibility

The mobile client **consumes** diarization results via the FFI interface:

```swift
// Mobile receives segments with speaker_id already assigned
struct Segment {
    let speakerId: Int?  // nil for non-diarized, Int for diarized
    let text: String
    let startMs: Int64
    let endMs: Int64
}
```

**Chat View implementation:**
- Request transcription with `diarization: true` in TranscriptionConfig
- Receive segments with `speaker_id` populated
- Display using `speaker_id % 2` for left/right alignment (as specified in project.md)

### Beta Exit Criteria

From Local Server roadmap:
> "Diarization correctly identifies 2+ speakers (D3)"

This is a Local Server deliverable, not a mobile research item.

## Original Engineering Challenges (Resolved)

- ~~EC-1: Algorithm Selection~~ → Decided by Local Server (WP-STT)
- ~~EC-2: Streaming vs. Batch~~ → Implemented by Local Server (WP-STT)
- ~~EC-3: Multi-Speaker Handling~~ → API returns speaker_id; UI mapping is trivial

## Recommendation

**GO** — Proceed with Chat View UI development; diarization provided by Local Server.

## References

- Lexicon Local Server: `~/projects/Lexicon-Local-Server/`
- WP-STT work package
- Decision D3: Configurable diarization (per-session enable/disable)
