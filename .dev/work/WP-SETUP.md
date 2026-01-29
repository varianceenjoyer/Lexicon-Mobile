---
id: WP-SETUP
type: work-plan
status: ready
phase: mvp
created: 2026-01-29
updated: 2026-01-29
author: design-lead
consumers: [developer]
depends-on: []
blocks: [WP-AUDIO, WP-STATE, WP-NAV]
priority: critical
tags: [flutter, setup, configuration]
---

# WP-SETUP: Flutter Project Setup and Configuration

## Overview

Initialize the Flutter project with proper structure, dependencies, and platform configurations for iOS and Android. This is the foundational work package that all other packages depend on.

## Scope

### Included
- Flutter project creation with proper package structure
- Core dependency installation (Riverpod, go_router, etc.)
- iOS platform configuration (Info.plist, entitlements)
- Android platform configuration (AndroidManifest.xml, permissions)
- Project directory structure following Flutter best practices
- Basic theme setup (Material 3)
- Development environment verification

### Excluded
- Audio plugin configuration (see WP-AUDIO)
- State management implementation (see WP-STATE)
- View implementations (see WP-NOTE, WP-CHAT, WP-FILES)

## Interface Contract

### Project Structure

```
lexicon_mobile/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # MaterialApp configuration
│   ├── core/
│   │   ├── theme/
│   │   │   └── app_theme.dart       # Material 3 theme
│   │   ├── router/
│   │   │   └── app_router.dart      # GoRouter configuration
│   │   └── constants/
│   │       └── app_constants.dart   # App-wide constants
│   ├── features/
│   │   ├── note/                    # Note View feature
│   │   ├── chat/                    # Chat View feature
│   │   └── files/                   # File Manager feature
│   ├── services/                    # Service layer
│   └── shared/
│       └── widgets/                 # Shared widgets
├── ios/
│   └── Runner/
│       └── Info.plist               # iOS configuration
├── android/
│   └── app/
│       └── src/main/
│           └── AndroidManifest.xml  # Android configuration
├── test/                            # Unit tests
├── integration_test/                # Integration tests
└── pubspec.yaml                     # Dependencies
```

### pubspec.yaml Dependencies

```yaml
name: lexicon_mobile
description: Cross-platform speech transcription client
version: 0.1.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

  # Navigation
  go_router: ^13.0.0

  # UI
  cupertino_icons: ^1.0.6

  # Utilities
  equatable: ^2.0.5
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  riverpod_generator: ^2.3.0
```

### iOS Configuration (Info.plist additions)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Lexicon uses the microphone to transcribe your speech into text.</string>

<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

### Android Configuration (AndroidManifest.xml additions)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## Acceptance Criteria

- [ ] Flutter project builds successfully for iOS simulator
- [ ] Flutter project builds successfully for Android emulator
- [ ] All dependencies resolve without conflicts
- [ ] `flutter doctor` shows no critical issues
- [ ] Directory structure matches specification
- [ ] Material 3 theme applies correctly
- [ ] Hot reload functions properly
- [ ] Unit test framework runs successfully with example test

## Dependencies

### Requires
- Flutter SDK 3.x installed
- Xcode (for iOS builds)
- Android Studio (for Android builds)
- CocoaPods (iOS dependencies)

### Blocks
- WP-AUDIO (needs project structure)
- WP-STATE (needs project structure)
- WP-NAV (needs project structure)

## Files to Create

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point with ProviderScope |
| `lib/app.dart` | MaterialApp with theme and router |
| `lib/core/theme/app_theme.dart` | Material 3 theme definition |
| `lib/core/router/app_router.dart` | GoRouter stub configuration |
| `lib/core/constants/app_constants.dart` | App-wide constants |
| `ios/Runner/Info.plist` | iOS permissions and background modes |
| `android/app/src/main/AndroidManifest.xml` | Android permissions |
| `test/app_test.dart` | Basic widget test |

## Verification Commands

```bash
# Create project
flutter create --org com.lexicon lexicon_mobile

# Verify dependencies
flutter pub get

# Run analyzer
flutter analyze

# Run tests
flutter test

# Build iOS (simulator)
flutter build ios --simulator

# Build Android (debug)
flutter build apk --debug

# Verify doctor
flutter doctor
```

## Research References

- [R-FLUTTER-01](../design/research/R-FLUTTER-01-cross-platform-viability.md) — Flutter viability analysis
- [R-PLAT-01](../design/research/R-PLAT-01-platform-version-constraints.md) — Platform version constraints

## Notes

- Use Flutter 3.x stable channel
- iOS minimum deployment target: iOS 12.0 (Flutter default)
- Android minSdkVersion: 21 (Flutter default)
- Effective ML performance requires iOS 14+ / API 26+

---

*Work package created: 2026-01-29*
