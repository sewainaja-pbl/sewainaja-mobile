# Repository Guidelines

## Project Structure & Module Organization
This repository is a Flutter application. Primary code lives in `lib/` (`main.dart` entry point and `firebase_options.dart` for Firebase config). Tests are in `test/` (currently `widget_test.dart`). Platform folders are `android/`, `ios/`, `web/`, `windows/`, `macos/`, and `linux/`. Project configuration is in `pubspec.yaml`, `analysis_options.yaml`, and `firebase.json`.

When adding features, keep UI and logic grouped by feature under `lib/` (for example: `lib/features/auth/...`) and mirror that structure in `test/`.

## Build, Test, and Development Commands
- `flutter pub get`: install/update dependencies.
- `flutter run`: run locally on the connected device/emulator.
- `flutter analyze`: run static analysis using `flutter_lints`.
- `flutter test`: run unit/widget tests.
- `flutter build apk --release`: produce Android release build.
- `flutter build web`: produce web build output.

Run `flutter analyze` and `flutter test` before opening a PR.

## Coding Style & Naming Conventions
Use Dart/Flutter defaults enforced by `flutter_lints` (`analysis_options.yaml`).
- Indentation: 2 spaces, no tabs.
- File names: `snake_case.dart`.
- Types/classes/widgets: `PascalCase`.
- Variables/functions: `camelCase`.
- Prefer small, composable widgets over large monolithic build methods.

## Testing Guidelines
Use `flutter_test` for widget and unit tests. Place tests in `test/` and name files `*_test.dart` (example: `login_form_test.dart`). Keep test names behavior-focused (e.g., `shows error when password is empty`). Add/update tests with every feature or bug fix.

## Commit & Pull Request Guidelines
Follow concise, imperative commit messages. Prefer Conventional Commit style:
- `feat: add phone auth flow`
- `fix: handle null user document`
- `chore: update firebase dependencies`

PRs should include:
- clear summary of changes and scope,
- linked issue/task ID,
- screenshots or screen recordings for UI changes,
- note of test/analyze results and any known limitations.

## Agent-Specific Notes
If automation tooling requires superpowers, run:
`~/.codex/superpowers/.codex/superpowers-codex bootstrap`
from repo root before advanced agent tasks.
