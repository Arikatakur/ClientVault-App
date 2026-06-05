# ClientVault

> Personal command center for freelance/dev work — **clients, projects, payments, and an
> encrypted credential vault** — with GitHub integration, a dark "secure fintech" UI, and a
> Windows → iPhone shipping pipeline via GitHub Actions.

**Status:** `v0.1.0` — Phase 0 (Project Foundation). Local-first, single-user, offline.

---

## Highlights
- 🔐 Local-first **encrypted vault** (AES-256-GCM + Argon2id) — *security model designed; crypto lands in a later phase.*
- 🧭 Five-tab app: **Dashboard · Projects · Clients · Vault · Settings**
- 💾 On-device **SQLite** via Drift; reactive UI via **Riverpod**
- 🎨 **Material 3** dark-first design system
- 📱 **iOS + Android** from one codebase

## Tech stack
| Layer | Choice |
|------|--------|
| Framework | Flutter (Dart) |
| Navigation | go_router |
| State | Riverpod |
| Database | Drift (SQLite) + drift_flutter |
| Secure storage | flutter_secure_storage (Keychain / Keystore) |
| Biometrics | local_auth |
| Crypto | cryptography (AES-GCM, Argon2id) |
| GitHub | flutter_appauth (OAuth + PKCE) + dio |
| Charts / motion | fl_chart · flutter_animate · lottie |

## Getting started

### Prerequisites
- **Flutter SDK** (stable; developed on 3.44.1 / Dart 3.12.1). Verify with `flutter doctor`.
- **Android runs:** Android Studio (SDK + emulator).
- **iOS builds:** run in CI — no Mac required locally (see below).

### Run
```bash
flutter pub get
dart run build_runner build      # generate Drift code (*.g.dart)
flutter run                      # Android emulator, or `flutter run -d edge` for a web preview
```

> The on-device database is native (iOS / Android / desktop). The **web preview** renders the
> full UI; the Clients tab shows an "on-device" notice instead of live data.

### Verify
```bash
flutter analyze
flutter test
```

## Project structure
```
lib/
  app/                 # root MaterialApp.router
  core/
    router/            # go_router config (5-tab StatefulShellRoute)
    theme/             # design tokens + Material 3 dark theme
    utils/             # id generation, etc.
  data/
    local/             # Drift tables + AppDatabase (+ generated *.g.dart)
    providers/         # Riverpod providers (database, clients stream)
  features/
    dashboard/ projects/ clients/ vault/ settings/   # one folder per tab
    shell/             # bottom-nav scaffold
  shared/widgets/      # reusable UI (empty states, ...)
```

## Building for iPhone (Windows → iOS)
iOS is built and signed on **GitHub Actions macOS runners** and shipped to **TestFlight** — no
Mac needed locally. A tag-triggered (`v*`) release workflow is planned for Phase 0.5. Android
can be built locally on Windows (`flutter build appbundle`) or in CI.

## Versioning & workflow
Semantic versioning (`x.y.z`) tracked in `pubspec.yaml` (`version: x.y.z+build`). Every
versioned change updates `CHANGELOG.md` and uses **Conventional Commits** (`feat:`, `fix:`,
`chore:`, …). See `CLAUDE.md` for the full workflow and `clientvault-plan-flutter.md` for the
product plan and RTD.

## Roadmap
| Version | Phase | Scope |
|---------|-------|-------|
| `0.1.0` | Foundation | scaffold · theme · nav · DB ✅ |
| `0.2.0` | Core CRUD | clients + projects + live dashboard |
| `0.3.0` | Vault | master password · biometrics · encrypted items |
| `0.4.0` | Payments | records · roll-ups · overdue flags |
| `0.5.0` | GitHub | OAuth · repo browser · link to project |
| `0.6.0`+ | Polish | animations · backup · TestFlight → `1.0.0` MVP |

## License
Private project — all rights reserved.
