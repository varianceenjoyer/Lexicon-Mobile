---
id: WP-LATENCY-MOBILE
type: work-plan
status: in-progress
phase: beta
created: 2026-01-31
updated: 2026-01-31
author: design-lead
consumers: [developer]
depends-on: [WP-NOTE]
blocks: []
priority: critical
tags: [latency, performance, audio, streaming, optimization]
---

# WP-LATENCY-MOBILE: Mobile Client Latency Optimization

## Overview

Reduce speech-to-text latency from 10+ seconds to sub-2 seconds. Current measurements show unacceptable delays between speech onset and first transcription result appearing.

**Current State**: ~10+ seconds for a sentence on emulated x86_64 with tiny-q5_1 model.
**Target State**: <2 seconds from speech onset to first text appearing.

## Problem Analysis

### Latency Components (Dart Side)

1. **Audio Buffering Delay**: Currently buffering 100ms (1600 samples) minimum before sending
2. **Provider Rebuild Overhead**: Settings changes trigger provider rebuilds
3. **Async Serialization**: Audio samples converted to bytes on main thread
4. **FFI Boundary Crossing**: Dart → Rust overhead per call
5. **UI Update Delay**: State propagation through Riverpod

### Measurement Points

```
[Mic Input] → [Buffer] → [VAD Check] → [FFI Call] → [Whisper] → [FFI Return] → [State Update] → [UI Render]
    T0          T1          T2            T3           T4           T5             T6             T7
```

## Scope

### In Scope
- Audio pipeline optimization
- FFI call batching/reduction
- Buffer management improvements
- Async processing patterns
- UI update optimization

### Out of Scope
- Whisper model optimization (see WP-LATENCY-STT in Lexicon-Local-Server)
- Hardware acceleration
- Model quantization

## Optimization Strategies

### 1. Reduce Audio Buffer Size (Quick Win)

**Current**: 100ms minimum chunk
**Proposal**: Investigate 50ms chunks or adaptive sizing

```dart
// Current
static const int minSamplesForProcessing = 1600; // 100ms

// Proposed: Adaptive based on activity
int get adaptiveMinSamples {
  if (_recentSpeechDetected) return 800;  // 50ms during active speech
  return 1600; // 100ms during silence detection
}
```

**Risk**: Whisper may produce worse results with very short chunks.
**Mitigation**: A/B test quality vs latency tradeoff.

### 2. Eliminate Provider Rebuilds on Settings Change

**Problem**: `ref.watch(settingsProvider)` causes service recreation on every settings change.

**Solution**: Use `ref.listen` instead of `ref.watch` for settings updates:

```dart
final lexiconCoreProvider = Provider<LexiconCoreService>((ref) {
  final service = LexiconFlutterService();

  // Listen without triggering rebuild
  ref.listen(settingsProvider, (prev, next) {
    service.updateSettings(
      silenceThreshold: next.silenceThreshold,
      chunkSizeMs: next.chunkSizeMs,
    );
  });

  return service;
});
```

### 3. Move Audio Processing Off Main Thread

**Problem**: Sample conversion and FFI calls block UI thread.

**Solution**: Use Dart isolates for audio processing:

```dart
class AudioProcessingIsolate {
  static Future<Uint8List> convertSamples(List<double> samples) async {
    return compute(_samplesToF32Bytes, samples);
  }
}
```

### 4. Pre-allocate Audio Buffers

**Problem**: Creating new lists for every audio chunk causes GC pressure.

**Solution**: Ring buffer with pre-allocated memory:

```dart
class AudioRingBuffer {
  final Float32List _buffer;
  int _writePos = 0;
  int _readPos = 0;

  AudioRingBuffer(int capacity) : _buffer = Float32List(capacity);

  void write(List<double> samples) { /* ... */ }
  Float32List read(int count) { /* ... */ }
}
```

### 5. Batch FFI Calls

**Problem**: Each processAudio call crosses FFI boundary.

**Solution**: Queue audio chunks and process in batches when Whisper is ready:

```dart
// Instead of immediate processing
final segments = await _lexiconCore.processAudio(handle, samples);

// Queue-based processing
_audioQueue.add(samples);
if (_processorReady && _audioQueue.totalSamples >= minBatchSize) {
  final batch = _audioQueue.drain();
  final segments = await _lexiconCore.processAudioBatch(handle, batch);
}
```

### 6. Optimistic UI Updates

**Problem**: UI waits for complete transcription before updating.

**Solution**: Show partial results immediately:

```dart
// Stream-based updates instead of await
_lexiconCore.processAudioStream(handle, samples).listen((partial) {
  state = state.copyWith(
    partialText: partial.text,
    confidence: partial.confidence,
  );
});
```

### 7. Reduce State Update Frequency

**Problem**: Every segment triggers full state rebuild.

**Solution**: Debounce UI updates:

```dart
Timer? _updateDebounce;

void _onSegmentsReceived(List<Segment> segments) {
  _pendingSegments.addAll(segments);
  _updateDebounce?.cancel();
  _updateDebounce = Timer(Duration(milliseconds: 50), () {
    state = state.copyWith(segments: [...state.segments, ..._pendingSegments]);
    _pendingSegments.clear();
  });
}
```

## Acceptance Criteria

- [ ] Speech-to-first-text latency < 2 seconds on emulator
- [ ] Speech-to-first-text latency < 1 second on physical device
- [ ] No UI jank during recording (60fps maintained)
- [ ] Memory usage stable during long recordings
- [x] Latency metrics logged for all transcription sessions

## Implementation Order

1. **Phase 1 - Measurement** (required first) ✅ COMPLETE
   - [x] Add comprehensive latency logging at each pipeline stage
   - Logs VAD time, conversion time, FFI time, and full pipeline time
   - Session summary logged on stop with averages

2. **Phase 2 - Quick Wins** ✅ COMPLETE
   - [x] Fix provider rebuild issue (#2)
   - Changed `ref.watch` to `ref.listen` + `ref.read` pattern
   - Reduce buffer size experiment (#1) - configurable via settings

3. **Phase 3 - Architecture** ✅ COMPLETE
   - Isolate-based processing (#3) - deferred (FFI already async)
   - [x] Pre-allocated buffers (#4)
   - Created `AudioRingBuffer` class with 2-second capacity

4. **Phase 4 - Polish** ✅ PARTIAL
   - FFI batching (#5) - deferred (ring buffer handles accumulation)
   - Optimistic UI (#6) - deferred (requires streaming API from Rust)
   - [x] Update debouncing (#7)
   - 50ms debounce on segment updates to reduce UI rebuilds

## Files to Modify

| File | Changes |
|------|---------|
| `lib/providers/service_providers.dart` | Fix provider rebuild |
| `lib/services/lexicon_flutter_service.dart` | Buffer management, batching |
| `lib/features/note/providers/note_provider.dart` | Optimistic updates |
| `lib/services/audio_capture_service.dart` | Ring buffer |

## Metrics to Track

| Metric | Current | Target |
|--------|---------|--------|
| Speech onset to first text | 10+ sec | < 2 sec |
| FFI call duration | ? | < 50ms |
| Audio buffer delay | 100ms | 50-100ms adaptive |
| UI update latency | ? | < 16ms |
| Memory per minute recording | ? | < 10MB |

## Research References

- R-WHISPER-STREAMING in Lexicon-Local-Server
- Flutter isolate best practices
- Dart FFI performance guidelines

## Notes

- Physical device testing critical - emulator adds QEMU overhead
- Consider WebSocket streaming as alternative to FFI for complex scenarios
- Profile with Flutter DevTools before/after each optimization
