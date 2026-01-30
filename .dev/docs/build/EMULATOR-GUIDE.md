# Running APK on Android Emulator

> **Version**: 1.0.0 | **Updated**: 2026-01-30
>
> Guide for installing and running Lexicon Mobile APK on Android Studio emulator using ADB.

---

## Prerequisites

| Tool | Purpose |
|------|---------|
| Android Studio | Emulator management and AVD creation |
| ADB (Android Debug Bridge) | Command-line tool for APK installation |
| Built APK | From `flutter build apk --release` |

Ensure ADB is in your PATH:

```bash
# Should be set from BUILD-GUIDE.md
export PATH="$PATH:$ANDROID_HOME/platform-tools"

## WSL mount to Android Studio adb
echo 'alias adb="/mnt/n/tools/Android/platform-tools/adb.exe"' >> ~/.bashrc
source ~/.bashrc

# Verify ADB is available
adb version
```

---

## Step 1: Create an Android Virtual Device (AVD)

### Via Android Studio UI

1. Open Android Studio
2. Go to **Tools → Device Manager** (or click the phone icon in the toolbar)
3. Click **Create Device**
4. Select a device profile:
   - **Pixel 6** or **Pixel 7** recommended for modern API testing
   - Choose a profile matching your target audience
5. Select a system image:
   - **API 34 (Android 14)** or higher recommended
   - Download the image if not already available
   - Use **x86_64** images for better emulator performance
6. Configure AVD settings:
   - Give it a descriptive name (e.g., `Pixel_7_API_34`)
   - Adjust RAM/storage if needed (defaults usually sufficient)
7. Click **Finish**

### Via Command Line

```bash
# List available system images
sdkmanager --list | grep "system-images"

# Download a system image (example: API 34 x86_64)
sdkmanager "system-images;android-34;google_apis;x86_64"

# Create AVD
avdmanager create avd \
  --name "Pixel_7_API_34" \
  --package "system-images;android-34;google_apis;x86_64" \
  --device "pixel_7"
```

---

## Step 2: Start the Emulator

### Via Android Studio

1. Open **Tools → Device Manager**
2. Find your AVD in the list
3. Click the **Play** button (▶) to launch

### Via Command Line

```bash
# List available AVDs
emulator -list-avds

# Start emulator (replace with your AVD name)
emulator -avd Pixel_7_API_34

# Start in background
emulator -avd Pixel_7_API_34 &
```

**Useful emulator flags**:

| Flag | Purpose |
|------|---------|
| `-no-snapshot` | Start fresh without loading snapshot |
| `-wipe-data` | Reset emulator to factory state |
| `-gpu swiftshader_indirect` | Software rendering (for VMs/WSL) |
| `-no-audio` | Disable audio (useful for headless) |

---

## Step 3: Verify Device Connection

Wait for the emulator to fully boot, then verify ADB can see it:

```bash
# List connected devices
adb devices

# Expected output:
# List of devices attached
# emulator-5554    device
```

If status shows `offline` or `unauthorized`:
1. Wait for emulator to fully boot
2. Check for authorization prompt on emulator screen
3. Run `adb kill-server && adb start-server`

---

## Step 4: Install the APK

### Basic Installation

```bash
# Install release APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Install debug APK
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Reinstall / Update

```bash
# Replace existing installation (keeps app data)
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Replace and clear app data
adb install -r -d build/app/outputs/flutter-apk/app-release.apk
```

### Install to Specific Device

If multiple devices are connected:

```bash
# List devices to get serial
adb devices

# Install to specific device
adb -s emulator-5554 install build/app/outputs/flutter-apk/app-release.apk
```

---

## Step 5: Launch the App

### Via ADB

```bash
# Launch app by package name
adb shell am start -n com.lexicon.lexicon_mobile/.MainActivity

# Or use monkey to launch (simpler, doesn't require activity name)
adb shell monkey -p com.lexicon.lexicon_mobile 1
```

### Via Emulator

1. Navigate to the app drawer on the emulator
2. Find and tap the Lexicon Mobile app icon

---

## Debugging Commands

### View Logs

```bash
# All logs (verbose)
adb logcat

# Filter by tag
adb logcat -s Flutter

# Filter by app (replace with your package)
adb logcat --pid=$(adb shell pidof com.lexicon.lexicon_mobile)

# Clear log buffer
adb logcat -c
```

### App Management

```bash
# List installed packages
adb shell pm list packages | grep lexicon

# Get app info
adb shell dumpsys package com.lexicon.lexicon_mobile

# Uninstall app
adb uninstall com.lexicon.lexicon_mobile

# Clear app data (without uninstalling)
adb shell pm clear com.lexicon.lexicon_mobile
```

### File Transfer

```bash
# Push file to device
adb push local_file.txt /sdcard/Download/

# Pull file from device
adb pull /sdcard/Download/file.txt ./

# Access app-specific storage (requires debug build or root)
adb shell run-as com.lexicon.lexicon_mobile ls /data/data/com.lexicon.lexicon_mobile/
```

### Screenshots and Recording

```bash
# Take screenshot
adb shell screencap /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ./

# Record screen (Ctrl+C to stop)
adb shell screenrecord /sdcard/recording.mp4
adb pull /sdcard/recording.mp4 ./
```

---

## Quick Reference: Full Workflow

```bash
# 1. Start emulator
emulator -avd Pixel_7_API_34 &

# 2. Wait for boot and verify connection
adb wait-for-device
adb devices

# 3. Build APK (if not already built)
flutter build apk --release

# 4. Install APK
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 5. Launch app
adb shell monkey -p com.lexicon.lexicon_mobile 1

# 6. View logs
adb logcat -s Flutter
```

---

## WSL2 Considerations

When running Android Studio on Windows with WSL2:

### Option A: Use Windows ADB (Recommended)

Run emulator and ADB from Windows PowerShell/CMD, not WSL:

```powershell
# Windows PowerShell
adb devices
adb install path\to\app-release.apk
```

Copy the APK from WSL to Windows first:

```bash
# From WSL, copy to Windows accessible location
cp build/app/outputs/flutter-apk/app-release.apk /mnt/c/Users/<username>/Downloads/
```

### Option B: Connect WSL ADB to Windows Emulator

```bash
# In WSL, connect to Windows host ADB server
export ADB_SERVER_SOCKET=tcp:host.docker.internal:5037

# Or manually specify host IP
adb -H $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}') devices
```

---

## Troubleshooting

### "INSTALL_FAILED_NO_MATCHING_ABIS"

The APK doesn't contain native libraries for the emulator's architecture.

**Solution**: Build for x86_64 architecture:

```bash
# Ensure x86_64 native libraries are included
# See BUILD-GUIDE.md Step 1 for building x86_64 Lexicon Core
flutter build apk --release
```

### "INSTALL_FAILED_UPDATE_INCOMPATIBLE"

App signature changed between builds.

**Solution**: Uninstall the existing app first:

```bash
adb uninstall com.lexicon.lexicon_mobile
adb install build/app/outputs/flutter-apk/app-release.apk
```

### "error: device offline"

Emulator lost connection to ADB.

**Solution**:

```bash
adb kill-server
adb start-server
adb devices
```

### Emulator runs slowly

**Solutions**:
- Enable hardware acceleration (HAXM on Intel, Hypervisor on AMD)
- Use x86_64 system images instead of ARM
- Increase emulator RAM in AVD settings
- Close other resource-intensive applications

### App crashes on launch

Check logcat for crash details:

```bash
adb logcat -s AndroidRuntime:E Flutter:E

# Or get full crash dump
adb logcat | grep -A 20 "FATAL EXCEPTION"
```

---

## See Also

- [BUILD-GUIDE.md](BUILD-GUIDE.md) — Building the APK
- [Android ADB Documentation](https://developer.android.com/tools/adb)
- [Android Emulator Documentation](https://developer.android.com/studio/run/emulator-commandline)
