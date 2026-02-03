# Audio Test Files

This directory contains audio files for testing the STT (Speech-to-Text) pipeline.

## Required Format

The transcription engine requires audio in this format:
- **Sample Rate**: 16000 Hz (16kHz)
- **Channels**: 1 (mono)
- **Format**: 16-bit PCM WAV

## Converting Audio Files

### Using FFmpeg (recommended)

Convert MP3 to WAV:
```bash
ffmpeg -i tarantulas.mp3 -ar 16000 -ac 1 -acodec pcm_s16le tarantulas.wav
```

Convert any audio file:
```bash
ffmpeg -i input.mp3 -ar 16000 -ac 1 -acodec pcm_s16le output.wav
```

### Installing FFmpeg

**Windows:**
1. Download from https://ffmpeg.org/download.html
2. Or use: `winget install ffmpeg`

**macOS:**
```bash
brew install ffmpeg
```

**Linux:**
```bash
sudo apt install ffmpeg
```

## Files

- `tarantulas.mp3` - Source audio (needs conversion)
- `tarantulas.wav` - Converted audio for auto-test (16kHz mono)
- `woodchuck.wav` - Original test file
- `woodchuck_16k.wav` - Fallback test file (16kHz mono)
