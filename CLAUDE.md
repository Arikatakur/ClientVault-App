# CLAUDE.md

## Project Instructions for Claude Code

This file defines the development workflow, Git rules, versioning system, commit
style, changelog requirements, release process, and engineering standards for
**ClientVault** — now a **native iOS (SwiftUI) app with a cloud backend**.

Claude must follow these instructions whenever working on this repository.

> **Architecture pivot (2026-06):** ClientVault was rewritten from a local-first
> Flutter app into a native SwiftUI + cloud app, per
> [`docs/rewrite-blueprint.md`](docs/rewrite-blueprint.md) (the single source of
> truth). The Flutter codebase is archived under [`legacy/flutter/`](legacy/flutter/)
> for reference and is no longer built. The native app **continues the version
> line at `0.18.0`** (not `0.1.0`): App Store Connect requires every upload to have
> a higher version/build than the last, and the Flutter app already shipped
> `0.17.0+19`.

---

# 1. Project Context

This is a **native iOS** app.

Target platform:

- iOS (iPhone-first). Android is explicitly **out of scope**.

Primary stack:

- **SwiftUI** + **Swift Concurrency** (async/await)
- **Observation** (`@Observable`) for state
- `NavigationStack` / `TabView` for navigation
- **CryptoKit** (AES-256-GCM) + Argon2id (vetted dependency, vault phase) for the zero-knowledge vault
- **Keychain** for key material and tokens (never `UserDefaults`)
- Backend: **AWS Amplify Gen 2** (Cognito auth, AppSync/API Gateway, DynamoDB, S3, SNS/Pinpoint push) — see [`docs/backend-amplify.md`](docs/backend-amplify.md)
- **XcodeGen** (`project.yml`) generates the Xcode project (authored on Windows; built on macOS/CI)
- GitHub Actions (macOS runners) · Fastlane / TestFlight

ClientVault is intended to become a real production app, not a demo. Claude
should behave like a senior iOS engineer.

---

# 2. Main Rule

Every meaningful update must be treated as a versioned change.

After each completed version, Claude must:

1. Update the app version (see §3–4).
2. Update the changelog.
3. Create clear commits.
4. Push to GitHub (when the user asks / when appropriate).
5. Clearly explain what changed.

Do not leave important work uncommitted. Do not commit broken builds unless
clearly marked work-in-progress and the app still builds.

---

# 3. Versioning System

Semantic versioning: `x.y.z`.

## 3.1 Version meaning

### x — Major

Big/breaking changes: heavy architecture changes, breaking changes to the cloud
data model or crypto/storage format, a major feature set, or a public-launch
milestone (e.g. `0.9.0 → 1.0.0`).

### y — Minor

New feature / screen / module / service, or a significant improvement. Reset `z`
to 0 (`0.2.4 → 0.3.0`).

### z — Patch

Bug fixes, UI details, refactors, copy changes, performance, CI fixes
(`0.1.0 → 0.1.1`).

---

# 4. Version Update Rules (where the version lives)

The **single source of truth** for the version is **`project.yml`** (XcodeGen),
which sets the build settings that flow into `Info.plist`:

```yaml
settings:
  base:
    MARKETING_VERSION: "0.18.0"     # user-facing app version (x.y.z)
    CURRENT_PROJECT_VERSION: "20"   # build number — must increase per TestFlight upload
```

`Info.plist` reads these via `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)`.

Rules:

- The semantic version follows `x.y.z` in `MARKETING_VERSION`.
- `CURRENT_PROJECT_VERSION` (build number) must increase for every TestFlight /
  App Store upload, and must never decrease.
- Also update `CHANGELOG.md` and `README.md` when they reference the version.

---

# 5. Commit Message Style

Conventional commits: `type(scope): short description`.

Examples:

```txt
feat(auth): add Sign in with Apple flow
feat(vault): wrap DEK under password-derived KEK
fix(net): map 429 to rateLimited with Retry-After
chore(deps): add swift-sodium for Argon2id
ci(github): build and test on iOS Simulator
docs(security): document zero-knowledge key hierarchy
```

---

# 6. Allowed Commit Types

`feat`, `fix`, `docs`, `chore`, `refactor`, `style`, `perf`, `test`, `build`, `ci`.

Use the scope to name the area: `auth`, `vault`, `clients`, `projects`,
`payments`, `dashboard`, `settings`, `net`, `crypto`, `storage`, `push`, `ui`,
`design`, `ios`, `backend`.

---

# 7. Branch Naming

`type/short-description`, lowercase, hyphenated. Examples:

```txt
feat/auth-apple-google
feat/vault-crypto
fix/privacy-shield-snapshot
ci/testflight-release
```

---

# 8–9. Changelog

Maintain `CHANGELOG.md` for every version, newest first, using
[Keep a Changelog](https://keepachangelog.com/) categories — only those with
content:

```txt
Added · Changed · Fixed · Removed · Deprecated · Security · Performance · Documentation · Internal
```

Format:

```md
## [0.2.0] - 2026-06-20

### Added
- Sign in with Apple + Google, with backend token validation.

### Security
- Refresh token stored in Keychain; access token kept in memory only.
```

---

# 10. GitHub Push Rules

After a completed version: `git status` → stage logically → conventional
commit(s) → push. Split unrelated changes into separate commits.

---

# 11. When to Commit

Good points: scaffold complete, a screen/module complete, crypto primitive
done, a migration done, a bug fixed, changelog/version bumped, CI fixed. Avoid
committing broken builds, half-wired features that break navigation, debug code,
or secrets.

---

# 12. Development Workflow

1. Read structure. 2. Understand the change. 3. Short plan. 4. Edit. 5. Run
checks. 6. Fix errors. 7. Update docs. 8. Update changelog (if versioned).
9. Conventional commit. 10. Push. 11. Report.

---

# 13. Checks Before Committing

This repo is authored on **Windows**, where Xcode cannot run. Locally, validate
what you can:

```bash
# Validate the project spec generates (requires xcodegen; macOS or CI):
xcodegen generate

# On macOS / CI — build + test on a simulator (no signing needed):
xcodebuild -project ClientVault.xcodeproj -scheme ClientVault \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  CODE_SIGNING_ALLOWED=NO clean test
```

If a check cannot run in the current environment (e.g. `xcodebuild` on Windows),
say so explicitly and rely on **CI** (`.github/workflows/ios-ci.yml`) to compile
and test. Treat the first green CI run as the build-verification gate.

---

# 14. Architecture Rules (feature-first SwiftUI)

```txt
ClientVault/
  App/            ClientVaultApp, RootView, MainTabView, AppEnvironment (DI), SessionStore
  Core/
    Config/       AppConfig (non-secret build config)
    Networking/   APIClient + URLSession impl, Endpoint, APIError
    Crypto/       CryptoService (AES-GCM), KeyDerivation (Argon2id), VaultKeyManager, EncryptedPayload
    Storage/      KeychainStore, TokenStore
    DesignSystem/ Palette, Typography, Spacing, Motion, Haptics
  Features/       Auth/ Dashboard/ Clients/ Projects/ Payments/ Vault/ Settings/
  SharedUI/       Components/ (EmptyState, PrimaryButton, Card, …), Animations/, PrivacyShieldView
  Services/       Push/, Notifications/ (local), Entitlements/
  APIModels/      Codable DTOs (wire shapes)
  Domain/         Entities, VaultConfig, Mapping (DTO ↔ domain)
  Resources/      Info.plist, ClientVault.entitlements, Assets.xcassets
ClientVaultTests/ unit tests (crypto, mapping, design tokens)
```

Rules: keep UI / domain / data separated; no business logic in views; depend on
protocols (see `AppEnvironment`); small focused views; reusable UI in `SharedUI`;
tokens in `DesignSystem`; no giant files; no god objects.

---

# 15. State Management

- Use **Observation** (`@Observable` classes) for view models / stores; inject
  via the SwiftUI `environment`.
- Surface loading/error/empty states explicitly; never hide errors.
- Keep network/crypto/storage out of views.
- Naming: `SessionStore`, `EntitlementStore`, `ClientsViewModel`, etc.

---

# 16. Navigation

- `TabView` for the five main tabs; one `NavigationStack` per tab (state
  preserved independently).
- Native list behaviors: swipe actions, context menus, integrated `.searchable`.
- Sheets use detents + material; disable interactive dismiss for destructive ops
  unless confirmed.
- Tabs: **Dashboard · Projects · Clients · Vault · Settings**.

---

# 17. Data & Sync (cloud-first)

- The backend (AWS Amplify Gen 2) is the source of truth; local cache is optional
  (GRDB/SwiftData if added).
- All rows scoped by `userId`; enforce at the auth-rule / IAM level — no data
  leaks across users.
- Per-entity `createdAt`/`updatedAt` + soft delete (`deletedAt`) for safe sync.
  Vault items: last-write-wins. See [`docs/backend-amplify.md`](docs/backend-amplify.md).

---

# 18. Security Rules (core requirement)

ClientVault stores sensitive user data. Treat security as non-negotiable.

- **Vault secret fields must be encrypted on-device (AES-GCM) before any network
  transmission.** The server stores ciphertext only — never plaintext, never the
  master key. If unsure, stop and implement encryption first.
- Do not log or send to analytics any secret, token, password, or decrypted
  vault field.
- Key material and tokens live in the **Keychain** (`ThisDeviceOnly`), never in
  `UserDefaults`. Access token in memory; refresh token in Keychain.
- Use only vetted crypto (CryptoKit AES-GCM; Argon2id via a vetted library). Do
  not invent cryptography. Use random nonces (CryptoKit default) — never reuse.
- Clipboard auto-clear after copying a secret.
- App-switcher snapshot protection via the privacy shield (cover instantly on
  inactive/background).
- Auto-lock the vault on background/timeout.
- Brute-force protection: local exponential backoff + server-side rate limits.
- TLS only; certificate pinning optional.

Never commit: `.env`, `.p8`, `.p12`, `.mobileprovision`, certificates, API keys,
tokens, passwords, `amplify_outputs.json` / `amplifyconfiguration.json`.

Full model: [`docs/security-model.md`](docs/security-model.md).

---

# 19. iOS / TestFlight Rules

- Bundle ID in `project.yml` (`PRODUCT_BUNDLE_IDENTIFIER`) must match App Store
  Connect.
- Increase `CURRENT_PROJECT_VERSION` for every upload.
- Build/sign on GitHub Actions **macOS runners** (no Mac needed locally).
- Use Fastlane Match for signing; keep the signing repo private.
- Store App Store Connect API key + Apple credentials as **GitHub Secrets**.
- Never commit `.p8` keys, certs, or profiles.

Expected secrets:

```txt
APP_STORE_CONNECT_API_KEY · APP_STORE_CONNECT_KEY_ID · APP_STORE_CONNECT_ISSUER_ID
APPLE_TEAM_ID · MATCH_GIT_URL · MATCH_PASSWORD · MATCH_GIT_BASIC_AUTHORIZATION
```

---

# 20. CI/CD Rules

GitHub Actions. The foundation workflow generates the project and runs tests:

```txt
.github/workflows/ios-ci.yml         # xcodegen generate → xcodebuild test (simulator)
```

Planned: `release-ios.yml` (tag `v*` → archive + TestFlight via Fastlane),
`bootstrap-ios-signing.yml` (Match). iOS release workflow runs only on `v*` tags.

---

# 21. Release Workflow

1. Decide bump (major/minor/patch). 2. Update `MARKETING_VERSION` (and build
   number) in `project.yml`. 3. Update `CHANGELOG.md`. 4. Run checks / rely on
   CI. 5. Commit. 6. Tag `vX.Y.Z`. 7. Push commits + tag.

```bash
git tag v0.2.0
git push
git push origin v0.2.0
```

---

# 22. Delivery Plan (build order, from the blueprint)

1. **Foundation** — project bootstrap, design system, navigation shell, privacy
   shield. ✅ `0.18.0`
2. **Auth** — Sign in with Apple + Google, backend validation, provisioning.
3. **Clients + Projects** — cloud CRUD, search, premium list UX.
4. **Payments** — invoices/partials/overdue, reminders.
5. **Vault** — Argon2id KDF, key hierarchy, ciphertext sync, reveal sheet,
   biometric unlock.
6. **Settings + Plan** — entitlements scaffolding (server validation seam).
7. **Push** — APNs registration + optional cross-device pushes.

Version milestones: [`docs/version-milestones.md`](docs/version-milestones.md).

---

# 23. Pull Request Format

```md
## Summary
## Version
## Changes (Added/Changed/Fixed)
## Testing (xcodebuild test / CI green)
## Screenshots / Videos (if UI changed)
## Notes
```

---

# 24. Documentation

Keep docs in `docs/`:

```txt
docs/rewrite-blueprint.md     # single source of truth (mirrors the Notion spec)
docs/architecture-swiftui.md  # app architecture, DI, state, navigation
docs/security-model.md        # zero-knowledge vault crypto + threat model
docs/backend-amplify.md       # AWS Amplify Gen 2 backend design + endpoints
docs/version-milestones.md    # phase → version plan
```

Document major systems when added (vault crypto, backend schema, push, signing).

---

# 25. Code Quality

Readable, typed, modular, testable, secure. Avoid huge files, duplicated logic,
magic numbers (use `Spacing`/`Radius`/`Motion` tokens), unclear names, dead code,
business logic in views, unnecessary dependencies.

Add tests for crypto primitives, key handling, and DTO ↔ domain mapping.

---

# 26. Final Instruction

Behave like a senior iOS engineer, not a code generator. For every update: think
about maintainability, protect user data, keep versions clean, update the
changelog, commit properly, push when appropriate, and explain clearly. The goal
is a real iPhone app shippable to TestFlight and the App Store.
