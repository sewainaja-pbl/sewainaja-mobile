# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
- Flutter application (`sdk: ^3.11.5`) with Firebase integrated via FlutterFire.
- Current app logic is still close to the default Flutter counter template, with Firebase initialization added.
- Primary implementation files are in `lib/`; platform runners are standard Flutter-generated directories (`android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`).

## Common Commands
Use the project root.

### Setup
- `flutter pub get`

### Run
- `flutter run`
- `flutter run -d android`
- `flutter run -d ios`

### Static analysis / lint
- `flutter analyze`

### Tests
- Run all tests: `flutter test`
- Run a single test file: `flutter test test/widget_test.dart`
- Run a single test case by name: `flutter test --plain-name "Counter increments smoke test"`

### Build
- Android APK: `flutter build apk`
- Android App Bundle: `flutter build appbundle`
- iOS (no codesign): `flutter build ios --no-codesign`
- Web: `flutter build web`

## Architecture Notes

### App bootstrap
- Entry point: `lib/main.dart`.
- `main()` performs:
  1. `WidgetsFlutterBinding.ensureInitialized()`
  2. `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
  3. `runApp(MyApp())`

### Firebase configuration
- FlutterFire-generated options live in `lib/firebase_options.dart`.
- Firebase project mapping is recorded in `firebase.json`.
- Android native Firebase config exists at `android/app/google-services.json`.
- Firebase packages already declared in `pubspec.yaml`: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`.

### UI structure (current state)
- `MyApp` defines `MaterialApp` and theme.
- `MyHomePage` (`StatefulWidget`) holds local counter state and renders the default counter screen.
- Existing test coverage is template-level widget testing in `test/widget_test.dart`.

## Linting / Code Style
- Analyzer config: `analysis_options.yaml`
- Uses `package:flutter_lints/flutter.yaml` defaults (no extra custom lints yet).
