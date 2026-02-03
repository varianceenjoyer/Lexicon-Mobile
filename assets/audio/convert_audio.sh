#!/bin/bash
# Convert audio files to 16kHz mono WAV format for STT processing
# Requires ffmpeg to be installed

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Convert tarantulas.mp3 to 16kHz mono WAV
if [ -f "$SCRIPT_DIR/tarantulas.mp3" ]; then
    echo "Converting tarantulas.mp3..."
    ffmpeg -y -i "$SCRIPT_DIR/tarantulas.mp3" \
        -ar 16000 -ac 1 -acodec pcm_s16le \
        "$SCRIPT_DIR/tarantulas.wav"
    echo "Created: tarantulas.wav"
fi

# Convert woodchuck.wav if needed
if [ -f "$SCRIPT_DIR/woodchuck.wav" ]; then
    echo "Converting woodchuck.wav..."
    ffmpeg -y -i "$SCRIPT_DIR/woodchuck.wav" \
        -ar 16000 -ac 1 -acodec pcm_s16le \
        "$SCRIPT_DIR/woodchuck_16k.wav"
    echo "Created: woodchuck_16k.wav"
fi

echo "Done!"
