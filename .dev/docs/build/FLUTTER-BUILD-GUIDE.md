# Lexicon Flutter Bridge Build Guide

> **Version**: 1.0.0 | **Updated**: 2026-01-30
>
> Build instructions for the Lexicon Flutter bridge library (`lexicon-flutter` crate) for Android targets.

[NDK_VERSION]=29.0.14206865;

---

## Overview

This guide covers building the **lexicon-flutter** Rust crate, which provides Flutter bindings via flutter_rust_bridge. This is an alternative to the native FFI approach documented in [NATIVE-BUILD-GUIDE.md](./NATIVE-BUILD-GUIDE.md).

**Key Difference**: This guide builds `lexicon-flutter` (Flutter-specific bindings) rather than `lexicon-ffi` (generic FFI).

**Directory Structure Assumption**:
```
parent-directory/
├── Lexicon-Mobile/          ← You are here (base directory for all commands)
└── Lexicon-Local-Server/    ← Sibling directory containing lexicon-flutter crate
```

---

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Flutter SDK | 3.x+ | Cross-platform UI framework |
| Dart SDK | 3.0+ | Included with Flutter |
| Rust | 1.85+ | lexicon-flutter compilation |
| cargo-ndk | Latest | Android cross-compilation |
| Android NDK | r29+ | Native toolchain |
| Java JDK | 17+ | Required for Android/Gradle builds |

### Install cargo-ndk

```bash
cargo install cargo-ndk
```

### Add Android Rust Targets

```bash
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
```

---

## Environment Configuration

### Environment Variables

```bash
# Add to shell profile (~/.bashrc or ~/.zshrc)

# Android NDK (Linux-native required for WSL)
export ANDROID_NDK_HOME="$HOME/Android/Sdk/ndk/29.0.14206865"
export ANDROID_API_LEVEL="26"

# ONNX Runtime for TTS support
export ONNXRUNTIME_ANDROID_DIR="$HOME/.onnxruntime-android"

# Memory management (adjust based on available RAM)
export CARGO_BUILD_JOBS="4"
```

### WSL2 Notes

When building on WSL2, you **must** use a Linux-native NDK:

```bash
# Download Linux NDK
wget https://dl.google.com/android/repository/android-ndk-r29-linux.zip
unzip android-ndk-r29-linux.zip -d ~/

# Set environment
export ANDROID_NDK_HOME="$HOME/android-ndk-r29"
```

The Windows NDK (mounted via `/mnt/`) will **not** work for compilation.

---

## Build Commands

Build commands are run from the `Lexicon-Local-Server/` directory.

### Build Script Usage

```bash
cd ../Lexicon-Local-Server

# Build for ARM64 (most Android devices)
scripts/android/build-flutter-android.sh arm64

# Build for x86_64 (emulators)
scripts/android/build-flutter-android.sh x86_64

# Build for ARM32 (older devices)
scripts/android/build-flutter-android.sh arm32

# Build all targets
scripts/android/build-flutter-android.sh all

cd ../Lexicon-Mobile
```

### Target Options

| Argument | Rust Target | Android ABI | Use Case |
|----------|-------------|-------------|----------|
| `arm64` | `aarch64-linux-android` | `arm64-v8a` | Modern Android devices |
| `x86_64` | `x86_64-linux-android` | `x86_64` | Android emulators |
| `arm32` | `armv7-linux-androideabi` | `armeabi-v7a` | Older 32-bit devices |
| `all` | All of the above | All | Full release builds |

---

## Output Locations

The build script produces shared libraries in the Rust target directory:

```
Lexicon-Local-Server/
└── target/
    ├── aarch64-linux-android/
    │   └── release/
    │       └── liblexicon_flutter.so    ← ARM64 library
    ├── x86_64-linux-android/
    │   └── release/
    │       └── liblexicon_flutter.so    ← x86_64 library
    └── armv7-linux-androideabi/
        └── release/
            └── liblexicon_flutter.so    ← ARM32 library
```

### Verify Build Output

```bash
ls -lh ../Lexicon-Local-Server/target/*/release/liblexicon_flutter.so
```

Expected output:
```
-rwxr-xr-x 1 user user 12M Jan 30 10:00 ../Lexicon-Local-Server/target/aarch64-linux-android/release/liblexicon_flutter.so
-rwxr-xr-x 1 user user 14M Jan 30 10:05 ../Lexicon-Local-Server/target/x86_64-linux-android/release/liblexicon_flutter.so
```

---

## Copy Libraries to Flutter Project

After building, copy the libraries to the Flutter project's jniLibs directory:

```bash
# Create directories
mkdir -p android/app/src/main/jniLibs/arm64-v8a
mkdir -p android/app/src/main/jniLibs/x86_64
mkdir -p android/app/src/main/jniLibs/armeabi-v7a

# Copy ARM64 library
cp ../Lexicon-Local-Server/target/aarch64-linux-android/release/liblexicon_flutter.so \
   android/app/src/main/jniLibs/arm64-v8a/

# Copy x86_64 library (for emulators)
cp ../Lexicon-Local-Server/target/x86_64-linux-android/release/liblexicon_flutter.so \
   android/app/src/main/jniLibs/x86_64/

# Copy ARM32 library (optional)
cp ../Lexicon-Local-Server/target/armv7-linux-androideabi/release/liblexicon_flutter.so \
   android/app/src/main/jniLibs/armeabi-v7a/
```

### Copy libc++_shared.so

The C++ standard library must also be included:

```bash
NDK_SYSROOT="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib"

cp "$NDK_SYSROOT/aarch64-linux-android/libc++_shared.so" android/app/src/main/jniLibs/arm64-v8a/
cp "$NDK_SYSROOT/x86_64-linux-android/libc++_shared.so" android/app/src/main/jniLibs/x86_64/
cp "$NDK_SYSROOT/arm-linux-androideabi/libc++_shared.so" android/app/src/main/jniLibs/armeabi-v7a/
```

---

## ONNX Runtime Setup (for TTS)

TTS features require ONNX Runtime. Run the setup script before building:

```bash
cd ../Lexicon-Local-Server
scripts/android/setup-onnx-android.sh
cd ../Lexicon-Mobile
```

This downloads ONNX Runtime Android libraries to `~/.onnxruntime-android/`. The build script will automatically detect and use these libraries.

If ONNX Runtime is not found, the build continues without TTS support:
```
Warning: ONNX Runtime not found for arm64-v8a
Run: scripts/android/setup-onnx-android.sh
Building without TTS support...
```

---

## Quick Reference: Full Build Workflow

```bash
# 1. Build lexicon-flutter libraries
cd ../Lexicon-Local-Server
scripts/android/build-flutter-android.sh arm64
scripts/android/build-flutter-android.sh x86_64
cd ../Lexicon-Mobile

# 2. Copy libraries
mkdir -p android/app/src/main/jniLibs/{arm64-v8a,x86_64}
cp ../Lexicon-Local-Server/target/aarch64-linux-android/release/liblexicon_flutter.so android/app/src/main/jniLibs/arm64-v8a/
cp ../Lexicon-Local-Server/target/x86_64-linux-android/release/liblexicon_flutter.so android/app/src/main/jniLibs/x86_64/

# 3. Copy libc++_shared.so
NDK_SYSROOT="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib"
cp "$NDK_SYSROOT/aarch64-linux-android/libc++_shared.so" android/app/src/main/jniLibs/arm64-v8a/
cp "$NDK_SYSROOT/x86_64-linux-android/libc++_shared.so" android/app/src/main/jniLibs/x86_64/

# 4. Get Flutter dependencies
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# 5. Build APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Troubleshooting

### cargo-ndk not found

```bash
cargo install cargo-ndk
```

### Android NDK not found

Ensure `ANDROID_NDK_HOME` is set correctly:

```bash
echo $ANDROID_NDK_HOME
ls $ANDROID_NDK_HOME  # Should list NDK contents
```

For WSL, ensure you're using a Linux NDK, not the Windows one.

### ONNX Runtime not found

Run the setup script:

```bash
cd ../Lexicon-Local-Server
scripts/android/setup-onnx-android.sh
```

Or build without TTS support (the build will continue with a warning).

### Out of memory during build

Reduce parallel jobs:

```bash
export CARGO_BUILD_JOBS=2
```

For WSL2, consider setting memory limits in `%USERPROFILE%\.wslconfig`:

```ini
[wsl2]
memory=8GB
```

After build, release memory with `wsl --shutdown` from PowerShell.

### Library not found at runtime

1. Verify `.so` files are in correct `jniLibs/<abi>/` directories
2. Check library name is `liblexicon_flutter.so` (not `liblexicon_ffi.so`)
3. Ensure `libc++_shared.so` is also present
4. Run `flutter clean && flutter pub get`

---

## Comparison: lexicon-flutter vs lexicon-ffi

| Aspect | lexicon-flutter | lexicon-ffi |
|--------|-----------------|-------------|
| Build script | `build-flutter-android.sh` | `build-android.sh` |
| Crate | `lexicon-flutter` | `lexicon-ffi` |
| Output | `liblexicon_flutter.so` | `liblexicon_ffi.so` |
| Bindings | flutter_rust_bridge | Raw FFI |
| Feature flags | Built-in | `--stt --tts` flags |

---

## See Also

- [NATIVE-BUILD-GUIDE.md](./NATIVE-BUILD-GUIDE.md) — Native FFI build (lexicon-ffi)
- [Lexicon-Local-Server BUILD.md](../../../Lexicon-Local-Server/BUILD.md) — Core library build docs
- [flutter_rust_bridge docs](https://cjycode.com/flutter_rust_bridge/) — FFI binding generator
