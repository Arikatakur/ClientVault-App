# ClientVault

> A native iPhone command center for freelance/dev work — **clients, projects,
> payments, and a zero-knowledge encrypted vault** — built with **SwiftUI** on a
> **cloud backend**, with an Apple-quality dark UI.

**Status:** `v0.23.0` — Phase 6 (Settings + Entitlements): StoreKit 2 paywall ·
interval auto-lock · biometric toggle wired to vault state.

> **This is a rewrite.** ClientVault began as a local-first Flutter app (through
> `v0.17.0`). It has been rebuilt as a native SwiftUI + cloud app following
> [`docs/rewrite-blueprint.md`](docs/rewrite-blueprint.md). The Flutter codebase
> has been removed from the working tree and is preserved in git history. The
> native app **continues the version line at `0.18.0`** (not `0.1.0`) so
> TestFlight/App Store build and version numbers keep climbing past the shipped
> `0.17.0`.

---

## Highlights
- 🔐 **Zero-knowledge vault** — vault secrets are AES-256-GCM encrypted *on device*; the server only ever stores ciphertext.
- 🧭 Five-tab native app: **Dashboard · Projects · Clients · Vault · Settings**.
- ☁️ **Cloud-first**, multi-device, account-based (Sign in with Apple / Google).
- 🛡️ **Privacy shield** covers the UI the instant the app backgrounds (no sensitive app-switcher snapshots).
- 🎨 Dark "secure fintech" design system: tokens for color, type, spacing, motion, and haptics.

## Tech stack
| Layer | Choice |
|------|--------|
| UI | SwiftUI + Swift Concurrency |
| State | Observation (`@Observable`) injected via the environment |
| Navigation | `TabView` + `NavigationStack` (one per tab) |
| Crypto | CryptoKit AES-256-GCM · Argon2id (vetted dep, vault phase) |
| Secure storage | Keychain (`ThisDeviceOnly`) |
| Networking | `URLSession` + `Codable`, structured `APIError` |
| Backend | AWS Amplify Gen 2 (Cognito · AppSync/API GW · DynamoDB · S3 · SNS) |
| Project gen | XcodeGen (`project.yml`) |
| CI | GitHub Actions (macOS) · Fastlane / TestFlight |

## Getting started

This repo is **authored on Windows**; the iOS app builds on **macOS / CI** (Xcode
can't run on Windows). The Xcode project is generated from `project.yml`.

### On a Mac
```bash
brew install xcodegen
xcodegen generate          # creates ClientVault.xcodeproj
open ClientVault.xcodeproj # ⌘R to run, ⌘U to test
```

### Build & test from the command line
```bash
xcodebuild -project ClientVault.xcodeproj -scheme ClientVault \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  CODE_SIGNING_ALLOWED=NO clean test
```

CI runs exactly this on every push — see `.github/workflows/ios-ci.yml`.

## Project structure
```
project.yml                # XcodeGen spec (the Xcode project is generated, not committed)
ClientVault/
  App/                     # entry, root router, tab shell, DI container, session
  Core/
    Config/ Networking/ Crypto/ Storage/ DesignSystem/
  Features/                # Auth · Dashboard · Clients · Projects · Payments · Vault · Settings
  SharedUI/                # reusable components, animations, privacy shield
  Services/                # Push · local Notifications · Entitlements
  APIModels/               # Codable DTOs
  Domain/                  # entities + DTO↔domain mapping
  Resources/               # Info.plist, entitlements, Assets.xcassets
ClientVaultTests/          # crypto, mapping, design-token tests
docs/                      # blueprint, architecture, security model, backend, milestones
```

## Security model (short version)
Vault secrets are encrypted on-device before upload. A password-derived **Master
Key** (Argon2id) unwraps a random per-user **Data Encryption Key**; that DEK
AES-GCM-encrypts each item. The server stores only the wrapped DEK, KDF params,
and ciphertext. Full details and threat model: [`docs/security-model.md`](docs/security-model.md).

## Building for iPhone (Windows → iOS)
iOS is built and signed on **GitHub Actions macOS runners** and shipped to
**TestFlight** — no Mac needed locally. A tag-triggered (`v*`) release workflow
is planned for the TestFlight phase.

## Versioning & workflow
Semantic versioning (`x.y.z`) lives in `project.yml` (`MARKETING_VERSION` +
`CURRENT_PROJECT_VERSION`). Every versioned change updates `CHANGELOG.md` and uses
**Conventional Commits**. See [`CLAUDE.md`](CLAUDE.md) for the full workflow.

## Roadmap
| Version | Phase | Scope |
|---------|-------|-------|
| `0.18.0` | Foundation | design system · nav shell · privacy shield · seams ✅ |
| `0.19.0` | Auth | Sign in with Apple/Google + backend validation |
| `0.20.0` | Clients + Projects | cloud CRUD · search · premium list UX |
| `0.21.0` | Payments | invoices · partials · overdue · reminders |
| `0.22.0` | Vault | Argon2id · key hierarchy · ciphertext sync · reveal · biometrics |
| `0.23.0` | Settings + Plan | entitlements (server-validation seam) |
| `0.24.0`+ | Push → TestFlight | APNs · cross-device · signing → `1.0.0` MVP |

## License
Private project — all rights reserved.
