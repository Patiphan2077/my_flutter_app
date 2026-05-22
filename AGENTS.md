# AGENTS

## Purpose
This file helps AI coding agents understand the repository structure, common workflows, and where to make changes.

## Project overview
- Flutter application named `my_flutter_app`.
- The main app entrypoint is `lib/main.dart`, which launches `WeatherApp` from `lib/weather_app.dart`.
- The app is a single-screen weather app that fetches current weather and a 5-day forecast from the open-meteo API.
- Key dependencies are `http`, `geolocator`, and Flutter SDK packages.
- The project includes generated platform folders for Android, iOS, Linux, macOS, Windows, and web.

## Where to work
- Primary source code lives in `lib/`.
- Prefer modifying Flutter/Dart code in `lib/` for feature, bugfix, and UI work.
- Avoid changing generated platform scaffolding under `android/`, `ios/`, `linux/`, `macos/`, `windows/` unless the fix explicitly requires platform-specific integration.

## Recommended commands
- `flutter pub get` to restore dependencies.
- `flutter analyze` to validate code against `flutter_lints`.
- `flutter test` to run unit/widget tests.
- `flutter run -d <device>` to run the app on a target device.

## Agent guidance
- Keep changes minimal and aligned with the existing Material-style UI and weather app behavior.
- Do not introduce new dependencies without asking the user first.
- Preserve current error handling and asynchronous fetch patterns unless improving reliability.
- Use links to existing docs when possible, rather than duplicating Flutter platform details.

## Notes
- This repo currently does not have `.github/copilot-instructions.md` or `AGENTS.md` prior to this file.
- `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`; code should generally follow Flutter lint conventions.
