# indulge

Indulge is a privacy-first Flutter app for tracking sexual events, partners, and related health and behavior data. It helps you record activities (solo or with partners), keep lightweight contact information with images, and explore your habits with analysis tools — all designed to keep data local to your device.

## Current features

- Tracking sexual events with partners or alone
- Customizable activity categories and activities
- Light / Dark theme support (respects system appearance)
- Search to find specific events quickly
- Analysis page with:
  - Overview and activity breakdowns
  - Partner breakdowns and period comparisons
  - Time-window selection and trend charts to visualize habits
- Contacts list with images and key details to track who you interact with
- Data import/export (backup and restore of user data)

## Planned features

- Ability to record and attach locations to events
- New analysis views and statistics based on locations
- Tracking of STI/STD testing and results
- Contact notification suggestions based on testing outcomes
- DoxyPEP dose tracking and PrEP missed dose tracking
- On-device AI summary of stats (model download required; no network calls for inference)
- Calendar view to accompany the existing timeline
- Database encryption (encrypt stored data at rest)
- PIN to unlock the app (local PIN-based unlock)

## Basic usage

Prerequisites
- Flutter SDK (see https://docs.flutter.dev/get-started/install)
- A device or emulator

Run locally
1. Install dependencies: `flutter pub get`
2. Run on connected device/emulator: `flutter run`

Build
- Android: `flutter build apk`

Note: This project uses semantic versioning for the app. See `pubspec.yaml` for the current version.

## Privacy & Data

Indulge is intended to store data locally on the device. Planned features that use AI will run on-device; models must be downloaded beforehand and no inference should require network access.

## Contributing

Contributions, issues, and feature requests are welcome. Please keep sensitive sample data out of commits.

---
