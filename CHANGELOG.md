# Changelog

All notable changes to ClientVault are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project uses
[semantic versioning](https://semver.org/).

## [0.3.0] - 2026-06-06

**Phase 2 — The Vault.** Encrypted, biometric-locked credential storage.

### Added
- **Encrypted vault** using envelope encryption: a random AES-256 data key (DEK) seals each item, and the DEK is wrapped by a key derived from the master password via **Argon2id**. The master password is never stored.
- **Master-password setup** with a strength meter and a clear "no recovery" warning.
- **Lock screen** with master-password and **biometric** (Face ID / Touch ID) unlock. Biometric unlock is opt-in and stashes the DEK in the device keychain/keystore.
- **Encrypted CRUD** for passwords, API keys, accounts, secure notes, and cards. The list shows titles only — secrets are decrypted lazily, one at a time, on reveal.
- **Reveal sheet** with show/hide, copy, and an **automatic clipboard clear after 30 seconds**.
- **Auto-lock** when the app is backgrounded, and a live **Vault items** count on the dashboard.
- Crypto unit tests (DEK wrap/unwrap, wrong-password rejection, unique nonces).

### Changed
- Database schema migrated to **v2** (additive: `vault_items` + `vault_configs`); existing clients and projects are preserved.

### Security
- AES-256-GCM (authenticated) at rest; Argon2id KDF (19 MiB, t=2, p=1); a unique random nonce per encryption; the data key is held in memory only while unlocked.

### Notes
- Android biometric native wiring (FragmentActivity + permission) and vault-screen screenshot protection are deferred; iOS Face ID is configured. Linking vault items to clients/projects in the UI comes later.

## [0.2.0] - 2026-06-06

**Phase 1 — Core CRUD.** Clients and projects, fully linked.

### Added
- **Client detail screen** — contact info, notes, and the client's projects, reached by tapping a client row.
- **Full client form** (add and edit) capturing name, company, email, phone, and notes.
- **Project CRUD**: a live Projects tab plus a create/edit form with a client picker, status (lead / active / paused / done), budget + currency, and an optional due date.
- **Project detail screen** that links back to its client.
- Reusable project status chips and dependency-free money/date formatting helpers.

### Changed
- Dashboard **Active projects** is now a live count from the database.
- Deleting a client cascades to its projects in a single transaction.
- Clients list rows now open the detail screen instead of deleting inline.

### Internal
- New Drift queries (project list / by-client / by-id, partial client and project updates, cascade delete) and Riverpod providers (projects, client-by-id, project-by-id, client-projects).

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
