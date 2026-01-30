# Lexicon Mobile Build Guide

> **Version**: 1.0.0 | **Updated**: 2026-01-29
>
> Complete build instructions for Lexicon Mobile, including Lexicon Core integration from the sibling Lexicon-Local-Server project.

[NDK_VERSION]=29.0.14206865;

---

## Overview

Lexicon Mobile is a Flutter application that depends on **Lexicon Core**, a Rust library provided by the Lexicon-Local-Server project. This guide covers:

1. Setting up the development environment
2. Building Lexicon Core native libraries
3. Generating Flutter Rust Bridge bindings
4. Building the Flutter application

**Directory Structure Assumption**:
```
parent-directory/
├── Lexicon-Mobile/          ← You are here (base directory for all commands)
└── Lexicon-Local-Server/    ← Sibling directory containing Lexicon Core
```

---

## Prerequisites

### All Platforms

| Tool | Version | Purpose |
|------|---------|---------|
| Flutter SDK | 3.x+ | Cross-platform UI framework |
| Dart SDK | 3.0+ | Included with Flutter |
| Rust | 1.85+ | Lexicon Core compilation |
| Git | Latest | Source control |
| Java JDK | 17+ | Required for Android/Gradle builds |

### Install Flutter via Android Studio

1. **Install Android Studio**
   - Download from <https://developer.android.com/studio>
   - Run the installer and follow the setup wizard
   - Select "Standard" installation (includes Android SDK, NDK, and emulator)

2. **Install Flutter Plugin**
   - Open Android Studio
   - Go to **File → Settings** (Windows/Linux) or **Android Studio → Preferences** (macOS)
   - Navigate to **Plugins → Marketplace**
   - Search for "Flutter" and click **Install**
   - Restart Android Studio when prompted

3. **Install Flutter SDK**
   - Go to **File → Settings → Languages & Frameworks → Flutter**
   - Click **Download SDK...** or specify an existing Flutter SDK path
   - Android Studio will download and configure Flutter automatically

4. **Configure Android SDK & NDK**
   - Go to **File → Settings → Languages & Frameworks → Android SDK**
   - Under **SDK Tools** tab, ensure these are installed:
     - Android SDK Build-Tools
     - Android SDK Command-line Tools
     - Android SDK Platform-Tools
     - NDK (Side by side) — **required for Rust cross-compilation**
     - CMake — **required for native builds**

5. **Set Environment Variables**

   ```bash
   # Add to shell profile (~/.bashrc, ~/.zshrc, or PowerShell profile)

   # Flutter (path shown in Android Studio Settings → Flutter)
   export PATH="$PATH:$HOME/tools/flutter/bin"

   # Android SDK (typically ~/Android/Sdk or %LOCALAPPDATA%\Android\Sdk)
   export ANDROID_HOME="$HOME/Android/Sdk"
   export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/[NDK_VERSION]"  # e.g., 29.0.14206865
   export PATH="$PATH:$ANDROID_HOME/platform-tools"
   ```

6. **Verify Installation**

   ```bash
   flutter doctor
   ```

   All checks should pass. Address any issues reported by `flutter doctor`.

### Install Rust

```bash
# Linux/macOS
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup update stable

# Windows (PowerShell)
# Download and run rustup-init.exe from https://rustup.rs
```

---

## Platform-Specific Setup

### macOS (iOS + Android Development)

```bash
# Xcode (for iOS)
xcode-select --install

# Homebrew dependencies
brew install cmake llvm pkg-config

# iOS Rust targets
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios

# Android NDK (via Android Studio or standalone)
# Set environment variable:
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/29.0.14206865"

# Android Rust targets
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android

# cargo-ndk for Android builds
cargo install cargo-ndk
```

### Linux (Android Development)

```bash
# Build essentials and Java
sudo apt update
sudo apt install -y build-essential cmake pkg-config libssl-dev openjdk-17-jdk

# Set JAVA_HOME (add to ~/.bashrc or ~/.zshrc)
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

# Android NDK
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/29.0.14206865"

# Android Rust targets
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android

# cargo-ndk
cargo install cargo-ndk
```

### WSL2 (Windows Subsystem for Linux)

When developing on WSL2, you need a **Linux-native NDK** for Flutter builds.

#### 1. Install Prerequisites

```bash
# Build essentials and Java
sudo apt update
sudo apt install -y build-essential cmake pkg-config libssl-dev openjdk-17-jdk

# Set JAVA_HOME (add to ~/.bashrc or ~/.zshrc)
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
```

#### 2. Download and Install Linux NDK

Flutter's native asset compilation requires a Linux NDK with `linux-x86_64` prebuilt tools.

```bash
# Create NDK directory
mkdir -p ~/Android/Sdk/ndk
cd ~/Android/Sdk/ndk

# Download Linux NDK r29
curl -L -o ndk.zip "https://dl.google.com/android/repository/android-ndk-r29-linux.zip"

# Extract and rename to versioned directory
unzip -q ndk.zip
mv android-ndk-r29 29.0.14206865
rm ndk.zip

cd ~/projects/Lexicon-Mobile
```

#### 3. Configure Environment

```bash
# Point to Windows Android SDK for platform tools (adjust path as needed)
export ANDROID_HOME="/mnt/n/.DEV/tools/Android"

# Point to Linux NDK for compilation
export ANDROID_NDK_HOME="$HOME/Android/Sdk/ndk/29.0.14206865"
```

#### 4. Configure local.properties

Add/update the NDK path in `android/local.properties`:

```properties
sdk.dir=/mnt/n/.DEV/tools/Android/
ndk.dir=/home/<username>/Android/Sdk/ndk/29.0.14206865
```

#### 5. Copy Native Libraries

```bash
# Copy libc++_shared.so from Linux NDK
NDK_SYSROOT="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib"
cp "$NDK_SYSROOT/aarch64-linux-android/libc++_shared.so" android/app/src/main/jniLibs/arm64-v8a/
```

**Important WSL Notes**:

- The Windows NDK has `windows-x86_64` prebuilt tools which **cannot** be used for Flutter builds on WSL
- You **must** download a Linux-native NDK for Flutter's native asset compilation
- The `sdk.dir` can point to Windows Android SDK for platform tools, but `ndk.dir` must point to the Linux NDK
- Rust library compilation also requires the Linux NDK if building from source

### Windows (Android Development)

**Option 1: Use the automated script** (recommended)

```powershell
# From Lexicon-Local-Server directory
..\Lexicon-Local-Server\scripts\build-windows.ps1
```

**Option 2: Manual setup**

1. Install [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
   - Select "Desktop development with C++" workload
   - Ensure Windows 10/11 SDK is selected

2. Install LLVM:
   ```powershell
   winget install LLVM.LLVM
   $env:LIBCLANG_PATH = "C:\Program Files\LLVM\bin"
   ```

3. Install CMake:
   ```powershell
   winget install Kitware.CMake
   ```

4. Install Android NDK via Android Studio SDK Manager
   ```powershell
   $env:ANDROID_NDK_HOME = "C:\Users\<user>\AppData\Local\Android\Sdk\ndk\<version>"
   ```

5. Install cargo-ndk:
   ```powershell
   cargo install cargo-ndk
   ```

---

## Step 1: Build Lexicon Core Libraries

All commands run from `Lexicon-Mobile/` directory.

### Android Build

../Lexicon-Local-Server/scripts/android/setup-onnx-android.sh
source ~/.onnxruntime-android/env.sh
setup_ort_for_android arm64  # or x86_64
bash scripts/android/build-android.sh arm64 --release --tts


Build the Lexicon FFI library for Android:

```bash
# Build for ARM64 (most modern devices)
../Lexicon-Local-Server/scripts/android/build-android.sh arm64 --release --stt --tts

# Build for x86_64 (emulators)
../Lexicon-Local-Server/scripts/android/build-android.sh x86_64 --release --stt --tts
```

**Windows (Git Bash or WSL)**:
```bash
# Ensure ANDROID_NDK_HOME is set
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/29.0.14206865"
../Lexicon-Local-Server/scripts/android/build-android.sh arm64 --release --stt --tts
```

**Output locations**:
```
../Lexicon-Local-Server/target/aarch64-linux-android/release/liblexicon_ffi.so
../Lexicon-Local-Server/target/x86_64-linux-android/release/liblexicon_ffi.so
```

### iOS Build (macOS only)

```bash
# Device (arm64)
cd ../Lexicon-Local-Server
cargo build -p lexicon-ffi --release --target aarch64-apple-ios

# Simulator (arm64 for Apple Silicon Macs)
cargo build -p lexicon-ffi --release --target aarch64-apple-ios-sim

# Simulator (x86_64 for Intel Macs)
cargo build -p lexicon-ffi --release --target x86_64-apple-ios

cd ../Lexicon-Mobile
```

**Output locations**:
```
../Lexicon-Local-Server/target/aarch64-apple-ios/release/liblexicon_ffi.a
../Lexicon-Local-Server/target/aarch64-apple-ios-sim/release/liblexicon_ffi.a
```

---

## Step 2: Copy Native Libraries to Flutter Project

### Android

Create the jniLibs directory structure and copy libraries:

```bash
# Create directories
mkdir -p android/app/src/main/jniLibs/arm64-v8a
mkdir -p android/app/src/main/jniLibs/x86_64
mkdir -p android/app/src/main/jniLibs/armeabi-v7a

# Copy ARM64 library
cp ../Lexicon-Local-Server/target/aarch64-linux-android/release/liblexicon_ffi.so \
   android/app/src/main/jniLibs/arm64-v8a/

# Copy x86_64 library (for emulators)
cp ../Lexicon-Local-Server/target/x86_64-linux-android/release/liblexicon_ffi.so \
   android/app/src/main/jniLibs/x86_64/

# Copy libc++_shared.so from NDK (required)
NDK_SYSROOT="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib"
cp "$NDK_SYSROOT/aarch64-linux-android/libc++_shared.so" android/app/src/main/jniLibs/arm64-v8a/
cp "$NDK_SYSROOT/x86_64-linux-android/libc++_shared.so" android/app/src/main/jniLibs/x86_64/
```

**Windows paths** (adjust NDK path as needed):
```powershell
$NDK_SYSROOT = "$env:ANDROID_NDK_HOME/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib"
```

### iOS

Copy static library and create XCFramework:

```bash
# Create iOS lib directory
mkdir -p ios/Frameworks

# Copy static library
cp ../Lexicon-Local-Server/target/aarch64-apple-ios/release/liblexicon_ffi.a \
   ios/Frameworks/

# Or create XCFramework for multi-arch support
xcodebuild -create-xcframework \
  -library ../Lexicon-Local-Server/target/aarch64-apple-ios/release/liblexicon_ffi.a \
  -library ../Lexicon-Local-Server/target/aarch64-apple-ios-sim/release/liblexicon_ffi.a \
  -output ios/Frameworks/LexiconFFI.xcframework
```

---

## Step 3: Generate Flutter Rust Bridge Bindings

The Dart bindings are generated using `flutter_rust_bridge_codegen` from the Lexicon-Local-Server's `lexicon-flutter` crate.

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Dart SDK | 3.10.8+ | Required by codegen |
| flutter_rust_bridge_codegen | Latest | Generates FFI bindings |

### Install flutter_rust_bridge codegen

```bash
# Install globally via cargo
cargo install flutter_rust_bridge_codegen
```

### Generate Dart bindings

Run from the `crates/lexicon-flutter/` directory in Lexicon-Local-Server:

```bash
cd ../Lexicon-Local-Server/crates/lexicon-flutter
flutter_rust_bridge_codegen generate
```
nano
This reads the configuration from `flutter_rust_bridge.yaml`:

| Setting | Value |
|---------|-------|
| Rust input | `crate::api` (from `src/api.rs`) |
| Rust output | `./src/frb_generated.rs` |
| Dart output | `./dart/lib/src/generated/` |

### Generated Files

**Dart side** (`dart/lib/src/generated/`):

| File | Purpose |
|------|---------|
| `api.dart` | Main API classes (Transcriber, Synthesizer, etc.) |
| `types.dart` | Config/result types |
| `error.dart` | Error enum |
| `frb_generated.dart` / `.io.dart` / `.web.dart` | FFI glue |

**Rust side**:

| File | Purpose |
|------|---------|
| `src/frb_generated.rs` | FFI glue code |

> **Note**: See [flutter_rust_bridge documentation](https://cjycode.com/flutter_rust_bridge/) for advanced configuration options.

---

## Step 4: Build Flutter Application

### Get Dependencies

```bash
flutter pub get
```

### Generate Dart Code (Freezed, Riverpod, etc.)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run in Debug Mode

```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# Specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

### Build Release APK (Android)

```bash
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build Release AAB (Android App Bundle)

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build Release IPA (iOS)

```bash
flutter build ipa --release

# Output: build/ios/ipa/lexicon_mobile.ipa
```

---

## Quick Reference: Full Build Workflow

### Android (from scratch)

```bash
# 1. Build Lexicon Core
../Lexicon-Local-Server/scripts/android/build-android.sh arm64 --release --stt --tts
../Lexicon-Local-Server/scripts/android/build-android.sh x86_64 --release --stt --tts

# 2. Copy libraries
mkdir -p android/app/src/main/jniLibs/{arm64-v8a,x86_64}
cp ../Lexicon-Local-Server/target/aarch64-linux-android/release/liblexicon_ffi.so android/app/src/main/jniLibs/arm64-v8a/
cp ../Lexicon-Local-Server/target/x86_64-linux-android/release/liblexicon_ffi.so android/app/src/main/jniLibs/x86_64/

# 3. Get Flutter dependencies
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run
flutter run -d android
```

### iOS (from scratch, macOS only)

```bash
# 1. Build Lexicon Core
cd ../Lexicon-Local-Server
cargo build -p lexicon-ffi --release --target aarch64-apple-ios
cargo build -p lexicon-ffi --release --target aarch64-apple-ios-sim
cd ../Lexicon-Mobile

# 2. Copy library
mkdir -p ios/Frameworks
cp ../Lexicon-Local-Server/target/aarch64-apple-ios/release/liblexicon_ffi.a ios/Frameworks/

# 3. Get Flutter dependencies
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run
flutter run -d ios
```

---

## ONNX Runtime Setup (for TTS)

TTS features require ONNX Runtime. Run the setup script before building with `--tts`:

```bash
../Lexicon-Local-Server/scripts/android/setup-onnx-android.sh
```

This downloads and extracts ONNX Runtime Android libraries to `~/.onnxruntime-android/`.

---

## Environment Variables Reference

| Variable | Purpose | Example |
|----------|---------|---------|
| `JAVA_HOME` | Java JDK path (required for Gradle) | `/usr/lib/jvm/java-17-openjdk-amd64` |
| `ANDROID_HOME` | Android SDK path | `~/Android/Sdk` or `/mnt/n/.DEV/tools/Android` |
| `ANDROID_NDK_HOME` | Android NDK path | `$ANDROID_HOME/ndk/29.0.14206865` |
| `ANDROID_API_LEVEL` | Target API level | `26` (Android 8.0+) |
| `LIBCLANG_PATH` | LLVM/Clang path (Windows) | `C:\Program Files\LLVM\bin` |
| `ONNXRUNTIME_ANDROID_DIR` | ONNX Runtime Android libs | `~/.onnxruntime-android` |

---

## Troubleshooting

### `cargo ndk` not found

```bash
cargo install cargo-ndk
```

### CMake not finding Android toolchain

Ensure `CMAKE_TOOLCHAIN_FILE` points to the NDK:
```bash
export CMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"
```

### whisper-rs-sys build failure

1. Verify CMake is installed
2. Set `WHISPER_DONT_GENERATE_BINDINGS=1` (uses pre-generated bindings)

### Flutter can't find native library

1. Verify `.so` files are in correct `jniLibs/<abi>/` directories
2. Check library name matches (`liblexicon_ffi.so`)
3. Run `flutter clean && flutter pub get`

### iOS linking errors

1. Verify `.a` file is in `ios/Frameworks/`
2. Add library to Xcode project manually if needed:
   - Open `ios/Runner.xcworkspace`
   - Add `liblexicon_ffi.a` to Runner target > Build Phases > Link Binary With Libraries

### Windows: `link.exe` not found

Run the build script which initializes VS environment:
```powershell
..\Lexicon-Local-Server\scripts\build-windows.ps1
```

Or manually initialize:
```powershell
# Find and run vcvarsall.bat
& "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
```

### JAVA_HOME is not set

Install OpenJDK and set the environment variable:

```bash
# Linux/WSL
sudo apt install -y openjdk-17-jdk
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

# Verify
java -version
```

### Build failed due to Android v1 embedding

If you see `Build failed due to use of deleted Android v1 embedding`, the Android project files are incomplete or outdated. Regenerate them:

```bash
# Regenerate Android project files (preserves existing files like AndroidManifest.xml)
flutter create . --platforms=android --org=com.lexicon

# Then rebuild
flutter build apk --release
```

### Package version resolution failures

If `flutter pub get` fails with version conflicts (e.g., `thermal ^0.1.0 doesn't match any versions`):

1. Check the error message for suggested version
2. Update `pubspec.yaml` with the correct version
3. Run `flutter pub get` again

Example fix:

```yaml
# Before (broken)
thermal: ^0.1.0

# After (working)
thermal: ^1.1.12
```

### WSL: NDK toolchain not found (linux-x86_64)

If building Rust libraries fails with `failed to find tool .../prebuilt/linux-x86_64/bin/clang`:

The Windows NDK only has `windows-x86_64` prebuilt tools. Options:

1. **Pre-build on Windows**: Build the Rust libraries using Windows/PowerShell, then copy `.so` files to WSL
2. **Install Linux NDK in WSL**: Download the Linux NDK separately for WSL
3. **Use pre-built libraries**: If libraries were previously built, they can be reused

---

## See Also

- [Lexicon-Local-Server BUILD.md](../../../Lexicon-Local-Server/BUILD.md) — Core library build docs
- [flutter_rust_bridge docs](https://cjycode.com/flutter_rust_bridge/) — FFI binding generator
- [Architecture](../../design/architecture.md) — System architecture overview
- [Project](../../project.md) — Project specification
