# Changelog

All notable changes to ClientVault are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project uses
[semantic versioning](https://semver.org/).

> **Architecture reset (2026-06).** ClientVault was rebuilt from a local-first
> Flutter app into a **native iOS (SwiftUI) app on a cloud backend**, following
> [`docs/rewrite-blueprint.md`](docs/rewrite-blueprint.md). The native app
> **continues the version line at `0.18.0`** — not `0.1.0` — because App Store
> Connect requires each TestFlight/App Store upload to have a higher version and
> build number than the last, and the Flutter app already shipped `0.17.0+19`.
> Entries at `0.17.0` and below describe the archived **Flutter era** (now under
> [`legacy/flutter/`](legacy/flutter/)).

## [0.19.0] - 2026-06-11

**Authentication — Phase 2.** Sign in with Apple + Google, session persistence,
and account deletion. Backend token validation is a seam (the Amplify backend
isn't provisioned yet); a dev fallback signs in locally so the flow works end to end.

### Added
- **Sign in with Apple** via the official `SignInWithAppleButton`, with a secure
  random nonce (SHA-256 in the request) for replay protection.
- **Sign in with Google** via the GoogleSignIn SDK (added as an SPM package, guarded
  with `canImport` so the app still builds if the package is absent).
- **`AuthService`** orchestrating provider sign-in → backend token exchange
  (`POST /auth/{provider}`) → session, with a local **dev fallback** while
  `AppConfig.hasBackend` is false.
- **Session persistence**: the session restores on cold launch; sign-out and
  account deletion clear it. `SessionStore` now tracks the signed-in `UserProfile`.
- **Account deletion** in Settings (Apple requirement) with a confirmation dialog,
  plus the signed-in email shown in the Account section.

### Security
- Refresh token stored in the Keychain; access token kept in memory only.
- Apple authorization parsed off the async path so the non-`Sendable`
  `ASAuthorization` is never sent across an actor boundary.
- The Google client id is read from `Info.plist` (`GIDClientID`); a committed
  `PLACEHOLDER` is treated as "not configured" and the button errors gracefully.

### Changed
- The app now starts at the sign-in screen (`SessionStore` defaults to
  unauthenticated) and `restore()` promotes it when a session exists.
- Bumped to `0.19.0+21`.

### Internal
- Auth unit tests: nonce length/uniqueness + a known SHA-256 vector, dev-fallback
  and backend exchange paths (with fakes), API-error wrapping, session restore, and
  sign-out clearing.

## [0.18.0] - 2026-06-11

**Native rewrite — Phase 1 foundation (SwiftUI + cloud).** The first slice of the
[rewrite blueprint](docs/rewrite-blueprint.md): the app scaffold, design system,
navigation shell, privacy shield, and the core service seams later phases build on.

### Added
- **Native SwiftUI app scaffold** generated from `project.yml` (XcodeGen), iOS 17+,
  iPhone-first, dark UI. Targets `ClientVault` + `ClientVaultTests`.
- **Five-tab navigation shell** (`TabView` + one `NavigationStack` per tab):
  Dashboard, Projects, Clients, Vault, Settings — each with a native, branded
  empty/placeholder state, search bars, and toolbar actions.
- **Design system** (`Core/DesignSystem`): color palette, type ramp, 4-pt spacing
  + radius tokens, a single motion spec (durations/springs), and a haptics service.
- **Privacy shield**: a branded lock cover driven by scene phase that hides the UI
  the instant the app goes inactive/background, so the app-switcher snapshot never
  shows sensitive content. The vault auto-locks on background.
- **Core service seams** for later phases: `APIClient` (URLSession + structured
  `APIError`, auth/refresh/retry, offline & rate-limit mapping), `KeychainStore`
  + `TokenStore`, an `AppEnvironment` DI container, `SessionStore`,
  `EntitlementStore`, push registration, and local-notification scheduling.
- **Auth screen** with Sign in with Apple + Google buttons (flows wired to the
  session seam; backend validation lands in the Auth phase).
- **Domain + DTO models** for clients, projects, payments, and vault items, with
  DTO ↔ domain mapping (unknown enum values degrade safely).
- **Docs**: in-repo blueprint, SwiftUI architecture, zero-knowledge security model,
  AWS Amplify Gen 2 backend plan, and the version-milestone map.
- **CI**: `ios-ci.yml` generates the project and runs unit tests on an iOS Simulator.

### Security
- **Zero-knowledge vault crypto core**: real AES-256-GCM (CryptoKit) seal/open and
  key wrapping, an `EncryptedPayload` (nonce + ciphertext + tag + version) that is
  the *only* form vault secrets take on the wire, and a `VaultKeyManager` key
  hierarchy (Master Key → KEK via HKDF → wrapped DEK).
- **Argon2id KDF is an explicit, unimplemented seam** — it throws rather than
  silently substituting a weaker derivation, so no build can ship non-Argon2id
  password hashing. A vetted dependency is integrated in the Vault phase.
- Keychain items are `ThisDeviceOnly`; refresh token in Keychain, access token in
  memory only; biometric-protected (`biometryCurrentSet`) storage seam included.

### Changed
- **Archived the Flutter app** to `legacy/flutter/` (source, Android/iOS runners,
  Flutter CI workflows, and Flutter docs). It is preserved in git history but no
  longer built.
- Repointed `CLAUDE.md` and `README.md` to the SwiftUI + Amplify architecture; the
  version source moved from `pubspec.yaml` to `project.yml`.

### Internal
- Foundation unit tests: AES-GCM round-trip, wrong-key/tamper rejection, nonce
  uniqueness, key wrap/unwrap, payload JSON round-trip, design-token ordering, and
  DTO ↔ domain mapping.

## [0.17.0] - 2026-06-10

**List search.** The last piece of FR-9.

### Added
- **Clients tab search** — filter by client name or company.
- **Projects tab search** — filter by project name *or its client's name*.
- Both match the vault's existing search pattern, with a friendly
  "no matches" state.

## [0.16.0] - 2026-06-10

**Vault items belong to clients and projects now.** The data model supported
it since v0.3.0 — the UI finally exposes it (FR-6).

### Added
- **Link to a client and/or project** from the vault item form (optional
  dropdowns; links survive edits, and a link to a deleted record degrades
  gracefully instead of breaking the form).
- **Vault sections on client and project detail screens** listing the linked
  items by title. Revealing one still requires the vault to be unlocked —
  locked taps explain that instead of failing silently.
- **Link chips in the reveal sheet** showing the connected client/project.

### Notes
- Only the link ids are stored in plaintext, in keeping with the rule that
  titles and types are the vault's only unencrypted fields.

## [0.15.0] - 2026-06-10

**Encrypted backup.** Take your data with you — the last big MVP gap
(FR-10 / NFR-5, "no lock-in").

### Added
- **Export encrypted backup** (Settings → Data): everything — clients,
  projects, payments, vault items, and the vault's crypto config — sealed
  into one `.cvbackup` file and saved wherever you choose (Files app, iCloud
  Drive, …). The file is encrypted with a backup passphrase you set
  (Argon2id → AES-256-GCM); vault items additionally stay sealed under their
  original vault key, so secrets are double-encrypted at rest.
- **Import backup**: replaces everything on the device after an explicit
  warning, then relocks the vault — it opens with the master password from
  the backup. Wrong passphrase, damaged files, and backups from newer app
  versions are each rejected with a clear message.
- The KDF parameters travel inside the file, so older backups keep working
  when encryption costs are raised later.
- Codec and row-mapping unit tests (round trip, wrong passphrase, tamper /
  garbage / newer-version rejection).

### Notes
- Attachment **files** are not inside backups yet (only their absence is
  handled cleanly); that ships with cloud file sync. The settings tile says
  so.

## [0.14.0] - 2026-06-10

**Push groundwork + the cloud wire-up guide.** The last scaffolding before
backend provisioning starts.

### Added
- `PushRegistrationService` — the seam where APNs registration plugs in once
  the AWS relay (SNS/Pinpoint) exists; local due-date reminders are untouched
  and keep working offline.
- Settings → Notifications gains a "Push notifications" entry marked **Soon**
  (repo activity and cross-device alerts arrive with the cloud).

### Documentation
- **`docs/cloud-setup.md`** — the complete provisioning playbook: Amplify
  Gen 2 + Cognito, Sign in with Apple (Services ID, entitlement, match
  profile regen), Google OAuth, RevenueCat + App Store Connect products,
  APNs key + relay, and the compliance checklist — each with the exact
  provider/repository in the code where it plugs in.

## [0.13.0] - 2026-06-10

**Plans & subscriptions.** The paywall and entitlement layer for the
Free / Pro split from the Cloud + Subscriptions plan.

### Added
- **Plans screen** (Settings → Plan): Free vs Pro comparison with a
  monthly/annual selector, purchase CTA, and restore-purchases — Pro is
  cloud sync, multi-device, and unlimited clients/projects; the vault stays
  zero-knowledge either way.
- **Entitlement layer**: every feature can ask `ensurePro(...)`, which opens
  the paywall when needed. The `BillingRepository` interface is shaped for
  the RevenueCat (StoreKit 2) adapter; until store products exist, everyone
  is on Free and the CTA explains that subscriptions open at the cloud
  launch.
- **Debug-only "simulate Pro" switch** on the plans screen so feature gates
  can be exercised before the store is live (hidden in release builds).
- Unit tests for the entitlement controller and pre-store billing behavior.

### Notes
- Pricing is intentionally not shown ("announced at launch") — it is an open
  question in the plan. Server-side entitlement validation (RevenueCat
  webhook → Lambda) arrives with the AWS backend; this gate is UX, not
  security.

## [0.12.0] - 2026-06-10

**Accounts.** Sign up and sign in inside the app — the identity layer the
cloud sync and subscription releases will build on (per the Cloud +
Subscriptions plan: account login stays separate from the vault master
password).

### Added
- **Create account / sign in** (Settings → Account): email + password with a
  name field, show/hide password, validation, and clear error messages.
- **Profile screen** with avatar, provider badge, member-since date,
  **sign out**, and **delete account** (the Apple-required in-app deletion;
  app data is untouched).
- **Sign in with Apple / Google buttons** — visible now, activated when the
  Cognito backend goes live; until then they explain that accounts are
  on-device.
- `AuthRepository` interface with an on-device implementation: credentials
  are never stored — only an **Argon2id hash** in the keychain (independent
  salt and parameters from the vault's). One account per device in local
  mode; sessions survive restarts.
- Unit tests for the full account lifecycle (sign-up, wrong-password
  rejection, re-sign-in, single-account rule, deletion).

### Notes
- Accounts are **local-mode** until the AWS (Cognito) backend is provisioned;
  the UI says so explicitly. Swapping in Cognito is a provider rebind
  (`authRepositoryProvider`), not a refactor.

## [0.11.0] - 2026-06-10

**Security hardening + design polish.** Closes the two remaining MVP security
gaps (iOS-only scope — Android wiring is deferred).

### Security
- **Privacy shield** — the UI is covered with a branded lock screen the instant
  the app stops being active, so vault items and client data never appear in
  the iOS app switcher snapshot or behind system sheets.
- **Hardware-bound biometric unlock** — the vault data key is now stored under
  the keychain's own biometric policy (`biometryCurrentSet`, device-bound):
  the OS enforces Face ID at the keychain layer instead of an app-layer check,
  and re-enrolling biometrics invalidates the entry. Existing stashes are
  upgraded automatically on the next unlock.

### Changed
- **Design polish:** dashboard stat cards count up and the page eases in with
  a staggered entrance; secrets cross-fade between hidden and revealed; the
  lock screen animates in and shakes on a wrong password; empty states fade
  in; the tab bar gained a hairline divider.
- **Haptics** on copy, secret reveal, lock, and unlock (success and failure).
- Clearer message when biometric unlock fails ("use your master password").

### Documentation
- `clientvault-plan-flutter.md` now carries an MVP status section: what
  shipped through v0.11.0, what remains (encrypted backup/export, vault-item
  linking UI, tags, list search, Android parity, KDF/throttling hardening),
  and the iOS-only scope decision.

## [0.10.0] - 2026-06-06

**Reminders.** Get notified before payments and project deadlines — even when the app is closed.

### Added
- **Due-date reminders** — local notifications scheduled for unpaid payments and active project deadlines. They fire at 9:00 AM, with a configurable lead time (on the day, 1 day, 3 days, or 1 week before).
- **Notifications settings** — a master toggle, the lead-time picker, and a "Send a test notification" action. Permission is requested on first launch.
- Reminders re-sync automatically whenever payments or projects change and when the app returns to the foreground; tapping a reminder opens the related project.

### Notes
- All notifications are local/on-device — there is no push server. GitHub change notifications are planned for the next version.
- Android schedules reminders inexactly (no exact-alarm permission required). iOS fires them via the system calendar trigger while the app is closed.

## [0.9.1] - 2026-06-06

### Fixed
- Added `NSPhotoLibraryUsageDescription` to iOS Info.plist — required by Apple because `file_picker` references the photo library API; absence caused the v0.9.0 binary to be rejected by App Store Connect (ITMS-90683).

## [0.9.0] - 2026-06-06

**File attachments.** Keep client and project documents in the app.

### Added
- **Attach files** (PDF, image, or any document) to a client or a project, from their detail screens — e.g. save a client's bank-details PDF and open it later.
- **In-app PDF viewer** with pinch-to-zoom (pdfx); other file types open in the system viewer / Quick Look (open_filex).
- Files are copied into the app's on-device storage and listed with their size; deleting removes both the file and its record.

### Changed
- Database schema migrated to **v5** (additive: `attachments`). Deleting a client or project now also removes its attached files.

## [0.8.0] - 2026-06-06

**GitHub browser.** See what's happening in a linked repo.

### Added
- **Issues and pull requests** for a linked repository, alongside commits, in a tabbed **GitHub browser** (opened from the project's repo card). Each shows state (open / closed / draft), author, and age.

### Changed
- The repo card's GitHub action now opens commits, issues, and pull requests together, replacing the commits-only screen.

## [0.7.0] - 2026-06-06

**Feedback round.** Improvements from on-device testing.

### Added
- **Browse repository commits** — open a linked repo's recent commits from the project's GitHub card, and tap any commit to read its full message.
- **Partial / split payments** — each payment tracks an *amount paid so far*, so a ₪4,000 invoice with ₪1,000 received shows **Partial** with ₪3,000 outstanding. Roll-ups and the dashboard total use amounts actually received.
- **Shekel (₪ / ILS) currency** for projects and payments.
- **Recent activity** on the dashboard — a live feed of the latest clients, projects, payments, and vault items.

### Fixed
- **Auto-lock now works.** Moved to an app-wide watcher that locks both when the app is backgrounded and after the chosen idle period in the foreground. The previous hook only ran on the Vault tab and ignored idle time entirely.

### Changed
- Database schema migrated to **v4** (additive: payments gain `paid_amount`); existing fully-paid rows are backfilled.

## [0.6.0] - 2026-06-06

**Phase 5 (part 1) — Vault security polish.**

### Added
- **Change master password** (Settings → Security): re-derives the key and re-wraps the existing data key, so stored items are never re-encrypted and biometric unlock keeps working. A wrong current password is rejected.
- **Configurable auto-lock**: lock immediately, after 1 minute, or after 5 minutes of being backgrounded.
- Crypto re-wrap unit test (the new key opens, the old key is rejected).

### Changed
- Settings security tiles are now functional rather than placeholders.

## [0.5.0] - 2026-06-06

**Phase 3 — Payments.** Invoice/payment tracking per project.

### Added
- **Payments per project**: add / edit / delete payment lines with amount, currency, status (draft / sent / paid), and issued/due/paid dates.
- **Project roll-ups** on the project detail screen — Invoiced, Paid, and Outstanding totals.
- **Overdue flag**, derived (unpaid and past its due date) so it never goes stale.
- **Live "Outstanding"** total on the dashboard (sum of all unpaid amounts).
- Overdue-logic unit tests.

### Changed
- Database schema migrated to **v3** (additive: `payments`); existing data is preserved.
- Deleting a project (or a client) now cascades to its payments in a transaction, so no rows are orphaned.

## [0.4.0] - 2026-06-06

**Phase 4 — GitHub.** Connect an account and link repositories to projects.

### Added
- **Connect GitHub** with a fine-grained personal access token (Settings → GitHub). The token is validated against the API and stored only on-device, in the keychain/keystore.
- **Link a repository to a project** from the project detail screen via a searchable repo picker.
- **Live repository status** on linked projects: visibility, default branch, stars, open issues, and last push.
- Read-only GitHub REST client (dio) with typed, user-facing errors (invalid token, rate limit, offline) and JSON-parsing unit tests.

### Changed
- Settings is now reactive and surfaces the connected GitHub account.
- The shared `secureStoreProvider` moved to `core/storage` (vault DEK and GitHub token share one keychain instance).

### Notes
- Authentication uses a PAT rather than OAuth: with no backend, this keeps any client secret out of the app and stays tightly scoped and revocable. The OAuth device flow remains an option for a later version.

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
