# Changelog

All notable changes to ClientVault are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project uses
[semantic versioning](https://semver.org/).

## [0.1.2] - 2026-06-06

**Phase 0.5 fix — first TestFlight build.** Proving the pipeline end to end.

### Fixed
- iOS release now builds with the **iOS 26 SDK** (latest-stable Xcode on the `macos-15` runner). App Store Connect rejected the previous Xcode 16 / iOS 18.5 SDK upload. The signing (`fastlane match`) and App Store Connect API upload path had already validated end to end — only the SDK toolchain needed bumping.

## [0.1.1] - 2026-06-05

**Phase 0.5 — Windows → iPhone pipeline.** CI/CD to ship iOS to TestFlight without a Mac.

### Added
- GitHub Actions **CI** (`ci.yml`): `pub get`, Drift codegen, `flutter analyze`, `flutter test`, and a debug Android build on every push/PR.
- GitHub Actions **iOS release** (`release-ios.yml`): tag-triggered (`v*`) build + sign + upload to **TestFlight** on macOS runners.
- One-time **signing bootstrap** workflow + **fastlane** config (`match`, `Fastfile`, `Appfile`, `Matchfile`, `Gemfile`).
- `NSFaceIDUsageDescription` usage string for biometric unlock (used from v0.3.0).
- `docs/release-setup.md`: App ID, App Store Connect API key, certs repo, and the GitHub secrets checklist.

### Changed
- Bundle identifier finalized to **`org.clientvault.app`** (from the initial `com.arikatakur.clientvault` placeholder), matching the owned `clientvault.org` domain.
- iOS app display name set to **ClientVault**.

## [0.1.0] - 2026-06-05

**Phase 0 — Project Foundation.** A running, analyzable app skeleton.

### Added
- Flutter scaffold targeting **iOS and Android** (bundle id `com.arikatakur.clientvault`).
- Material 3 **dark-first design system**: color, spacing, radius, and typography tokens.
- **Five-tab navigation shell** (Dashboard · Projects · Clients · Vault · Settings) built on
  go_router `StatefulShellRoute` with per-tab state preservation.
- **Drift (SQLite) database** with `Clients` and `Projects` tables at schema version 1.
- **Riverpod** state layer exposing the database and a reactive clients stream.
- **Clients screen** with create / list / delete wired end-to-end to the database.
- Placeholder screens: Dashboard (with a live client count), Projects, Vault, and Settings.
- Widget smoke test and a clean `flutter analyze` baseline.

### Internal
- Full MVP dependency stack installed (secure storage, local auth, cryptography, dio,
  GitHub OAuth, charts, animations) ahead of their feature phases.
- `build_runner` code-generation pipeline configured for Drift.
