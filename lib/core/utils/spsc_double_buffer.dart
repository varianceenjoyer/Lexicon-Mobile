import 'dart:typed_data';

/// Single-Producer Single-Consumer double buffer for audio samples.
///
/// Uses two pre-allocated buffers to enable lock-free audio accumulation
/// while the consumer (Whisper) processes the previous batch.
///
/// Producer writes to the "front" buffer continuously.
/// Consumer swaps buffers and processes the "back" buffer.
/// No data is lost as long as buffer capacity > max processing time.
class SpscDoubleBuffer {
  /// The two pre-allocated buffers.
  final Float64List _bufferA;
  final Float64List _bufferB;

  /// Write positions for each buffer.
  int _writePosA = 0;
  int _writePosB = 0;

  /// Which buffer is currently "front" (being written to).
  /// true = A is front, false = B is front.
  bool _aIsFront = true;

  /// Capacity of each buffer in samples.
  final int capacity;

  /// Create a double buffer with the given capacity per buffer.
  ///
  /// Default capacity of 480000 samples = 30 seconds at 16kHz.
  /// This should exceed the maximum expected processing time.
  SpscDoubleBuffer([this.capacity = 480000])
      : _bufferA = Float64List(capacity),
        _bufferB = Float64List(capacity);

  /// Number of samples in the front (write) buffer.
  int get frontAvailable => _aIsFront ? _writePosA : _writePosB;

  /// Number of samples in the back (read) buffer.
  int get backAvailable => _aIsFront ? _writePosB : _writePosA;

  /// Whether the front buffer is empty.
  bool get frontIsEmpty => frontAvailable == 0;

  /// Whether the back buffer is empty.
  bool get backIsEmpty => backAvailable == 0;

  /// Whether the front buffer is full.
  bool get frontIsFull => frontAvailable >= capacity;

  /// Write samples to the front buffer.
  ///
  /// Returns the number of samples actually written.
  /// If the buffer is full, excess samples are dropped and a warning count is returned.
  int write(List<double> samples) {
    final buffer = _aIsFront ? _bufferA : _bufferB;
    final writePos = _aIsFront ? _writePosA : _writePosB;

    final available = capacity - writePos;
    final toWrite = samples.length < available ? samples.length : available;

    for (var i = 0; i < toWrite; i++) {
      buffer[writePos + i] = samples[i];
    }

    if (_aIsFront) {
      _writePosA += toWrite;
    } else {
      _writePosB += toWrite;
    }

    // Return number of dropped samples (0 if none dropped)
    return samples.length - toWrite;
  }

  /// Swap front and back buffers.
  ///
  /// Call this when ready to process. The previous front becomes the back
  /// (for reading), and the previous back becomes the front (for writing).
  /// The new front buffer is cleared.
  void swap() {
    _aIsFront = !_aIsFront;
    // Clear the new front buffer's write position
    if (_aIsFront) {
      _writePosA = 0;
    } else {
      _writePosB = 0;
    }
  }

  /// Read all samples from the back buffer.
  ///
  /// Returns a view of the back buffer containing the accumulated samples.
  /// The returned list is valid until the next swap().
  Float64List readBack() {
    if (_aIsFront) {
      // B is back
      return Float64List.sublistView(_bufferB, 0, _writePosB);
    } else {
      // A is back
      return Float64List.sublistView(_bufferA, 0, _writePosA);
    }
  }

  /// Clear the back buffer after processing.
  ///
  /// This resets the write position of the back buffer.
  /// Call after processing is complete, before the next swap.
  void clearBack() {
    if (_aIsFront) {
      _writePosB = 0;
    } else {
      _writePosA = 0;
    }
  }

  /// Get total memory usage in bytes.
  int get memoryUsageBytes => capacity * 8 * 2; // 8 bytes per double, 2 buffers

  /// Reset both buffers.
  void reset() {
    _writePosA = 0;
    _writePosB = 0;
    _aIsFront = true;
  }
}
