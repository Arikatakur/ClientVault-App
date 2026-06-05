# Changelog

All notable changes to ClientVault are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project uses
[semantic versioning](https://semver.org/).

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
