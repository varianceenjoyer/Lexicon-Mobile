import 'dart:typed_data';

/// Pre-allocated ring buffer for audio samples.
///
/// Uses Float64List for storing normalized audio samples (-1.0 to 1.0).
/// Reduces GC pressure by avoiding frequent list allocations during recording.
class AudioRingBuffer {
  /// The underlying pre-allocated buffer.
  final Float64List _buffer;

  /// Current write position in the buffer.
  int _writePos = 0;

  /// Current number of samples available for reading.
  int _available = 0;

  /// Capacity of the buffer in samples.
  final int capacity;

  /// Create a ring buffer with the given capacity in samples.
  ///
  /// For 16kHz audio, 16000 samples = 1 second of audio.
  /// Default capacity of 32000 samples = 2 seconds of audio.
  AudioRingBuffer([this.capacity = 32000]) : _buffer = Float64List(capacity);

  /// Number of samples available for reading.
  int get available => _available;

  /// Whether the buffer is empty.
  bool get isEmpty => _available == 0;

  /// Whether the buffer is full.
  bool get isFull => _available == capacity;

  /// Write samples to the buffer.
  ///
  /// If the buffer would overflow, older samples are overwritten.
  /// Returns the number of samples actually written.
  int write(List<double> samples) {
    final toWrite = samples.length;

    for (var i = 0; i < toWrite; i++) {
      _buffer[_writePos] = samples[i];
      _writePos = (_writePos + 1) % capacity;
    }

    // Update available count, capped at capacity
    _available = (_available + toWrite).clamp(0, capacity);

    return toWrite;
  }

  /// Read up to [count] samples from the buffer.
  ///
  /// Returns a new Float64List containing the samples.
  /// The returned list may be shorter than [count] if fewer samples are available.
  Float64List read(int count) {
    final toRead = count.clamp(0, _available);
    if (toRead == 0) return Float64List(0);

    final result = Float64List(toRead);

    // Calculate read start position
    final readStart = (_writePos - _available + capacity) % capacity;

    for (var i = 0; i < toRead; i++) {
      result[i] = _buffer[(readStart + i) % capacity];
    }

    _available -= toRead;
    return result;
  }

  /// Read all available samples and clear the buffer.
  ///
  /// Returns a Float64List containing all available samples.
  Float64List drain() {
    return read(_available);
  }

  /// Peek at samples without removing them from the buffer.
  ///
  /// Returns up to [count] samples without modifying the buffer state.
  Float64List peek(int count) {
    final toPeek = count.clamp(0, _available);
    if (toPeek == 0) return Float64List(0);

    final result = Float64List(toPeek);
    final readStart = (_writePos - _available + capacity) % capacity;

    for (var i = 0; i < toPeek; i++) {
      result[i] = _buffer[(readStart + i) % capacity];
    }

    return result;
  }

  /// Clear all samples from the buffer.
  void clear() {
    _available = 0;
    // Note: We don't zero out the buffer for performance, just reset counters
  }

  /// Calculate RMS (root mean square) of the available samples.
  ///
  /// Useful for voice activity detection without reading/copying samples.
  double calculateRms() {
    if (_available == 0) return 0.0;

    var sumSquares = 0.0;
    final readStart = (_writePos - _available + capacity) % capacity;

    for (var i = 0; i < _available; i++) {
      final sample = _buffer[(readStart + i) % capacity];
      sumSquares += sample * sample;
    }

    return _sqrt(sumSquares / _available);
  }

  /// Calculate RMS of the last [sampleCount] samples.
  ///
  /// Useful for checking activity of recent audio only.
  double calculateRecentRms(int sampleCount) {
    final count = sampleCount.clamp(0, _available);
    if (count == 0) return 0.0;

    var sumSquares = 0.0;
    // Start from the most recent samples
    final startPos = (_writePos - count + capacity) % capacity;

    for (var i = 0; i < count; i++) {
      final sample = _buffer[(startPos + i) % capacity];
      sumSquares += sample * sample;
    }

    return _sqrt(sumSquares / count);
  }

  /// Simple square root implementation to avoid importing dart:math.
  double _sqrt(double x) {
    if (x <= 0) return 0.0;
    var guess = x / 2;
    for (var i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
