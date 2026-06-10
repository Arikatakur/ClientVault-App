# Changelog

All notable changes to ClientVault are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project uses
[semantic versioning](https://semver.org/).

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
