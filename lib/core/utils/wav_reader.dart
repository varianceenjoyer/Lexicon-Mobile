import 'dart:typed_data';

/// Simple WAV file reader that extracts PCM samples.
///
/// Supports 16-bit PCM WAV files at any sample rate.
/// Returns normalized Float64 samples in range [-1.0, 1.0].
class WavReader {
  /// Parse a WAV file and return normalized audio samples.
  ///
  /// Returns a record with:
  /// - samples: List<double> normalized to [-1.0, 1.0]
  /// - sampleRate: int (e.g., 16000)
  /// - channels: int (1 for mono, 2 for stereo)
  static ({List<double> samples, int sampleRate, int channels}) parse(
      Uint8List bytes) {
    // WAV file structure:
    // Bytes 0-3: "RIFF"
    // Bytes 4-7: file size - 8
    // Bytes 8-11: "WAVE"
    // Bytes 12+: chunks (fmt, data, etc.)

    if (bytes.length < 44) {
      throw FormatException('WAV file too short: ${bytes.length} bytes');
    }

    // Verify RIFF header
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    if (riff != 'RIFF') {
      throw FormatException('Not a RIFF file: $riff');
    }

    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (wave != 'WAVE') {
      throw FormatException('Not a WAVE file: $wave');
    }

    // Find fmt chunk
    int offset = 12;
    int? sampleRate;
    int? channels;
    int? bitsPerSample;

    while (offset < bytes.length - 8) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = _readUint32LE(bytes, offset + 4);

      if (chunkId == 'fmt ') {
        // fmt chunk: audio format info
        final audioFormat = _readUint16LE(bytes, offset + 8);
        if (audioFormat != 1) {
          throw FormatException(
              'Unsupported audio format: $audioFormat (only PCM supported)');
        }
        channels = _readUint16LE(bytes, offset + 10);
        sampleRate = _readUint32LE(bytes, offset + 12);
        // bytes 16-19: byte rate
        // bytes 20-21: block align
        bitsPerSample = _readUint16LE(bytes, offset + 22);
      } else if (chunkId == 'data') {
        // data chunk: actual audio samples
        if (sampleRate == null || channels == null || bitsPerSample == null) {
          throw FormatException('data chunk before fmt chunk');
        }

        final dataOffset = offset + 8;
        final dataLength = chunkSize;

        final samples = _parseSamples(
          bytes.sublist(dataOffset, dataOffset + dataLength),
          bitsPerSample,
          channels,
        );

        return (
          samples: samples,
          sampleRate: sampleRate,
          channels: channels,
        );
      }

      offset += 8 + chunkSize;
      // Align to even byte boundary
      if (chunkSize.isOdd) offset++;
    }

    throw FormatException('No data chunk found in WAV file');
  }

  static int _readUint16LE(Uint8List bytes, int offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  static int _readUint32LE(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  static List<double> _parseSamples(
    Uint8List data,
    int bitsPerSample,
    int channels,
  ) {
    final samples = <double>[];

    if (bitsPerSample == 16) {
      // 16-bit signed PCM
      for (var i = 0; i < data.length - 1; i += 2) {
        var val = data[i] | (data[i + 1] << 8);
        // Sign extend
        if (val >= 0x8000) val -= 0x10000;
        samples.add(val / 32768.0);
      }
    } else if (bitsPerSample == 8) {
      // 8-bit unsigned PCM
      for (var i = 0; i < data.length; i++) {
        samples.add((data[i] - 128) / 128.0);
      }
    } else if (bitsPerSample == 24) {
      // 24-bit signed PCM
      for (var i = 0; i < data.length - 2; i += 3) {
        var val = data[i] | (data[i + 1] << 8) | (data[i + 2] << 16);
        if (val >= 0x800000) val -= 0x1000000;
        samples.add(val / 8388608.0);
      }
    } else if (bitsPerSample == 32) {
      // 32-bit signed PCM
      for (var i = 0; i < data.length - 3; i += 4) {
        var val = data[i] |
            (data[i + 1] << 8) |
            (data[i + 2] << 16) |
            (data[i + 3] << 24);
        // Already signed 32-bit
        samples.add(val / 2147483648.0);
      }
    } else {
      throw FormatException('Unsupported bits per sample: $bitsPerSample');
    }

    // Convert stereo to mono by averaging channels
    if (channels == 2) {
      final mono = <double>[];
      for (var i = 0; i < samples.length - 1; i += 2) {
        mono.add((samples[i] + samples[i + 1]) / 2.0);
      }
      return mono;
    }

    return samples;
  }

  /// Resample audio to a target sample rate using linear interpolation.
  static List<double> resample(
    List<double> samples,
    int fromRate,
    int toRate,
  ) {
    if (fromRate == toRate) return samples;

    final ratio = toRate / fromRate;
    final newLength = (samples.length * ratio).round();
    final resampled = <double>[];

    for (var i = 0; i < newLength; i++) {
      final srcIdx = i / ratio;
      final idx0 = srcIdx.floor();
      final idx1 = (idx0 + 1).clamp(0, samples.length - 1);
      final frac = srcIdx - idx0;
      final val = samples[idx0] * (1 - frac) + samples[idx1] * frac;
      resampled.add(val);
    }

    return resampled;
  }
}
