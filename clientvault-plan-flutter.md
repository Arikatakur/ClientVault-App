# ClientVault — Product Plan, MVP & Technical Design (RTD)
### Flutter Edition

> A cross-platform mobile app to manage projects, clients, payments, accounts, passwords, and API keys in one place — with GitHub integration, a polished animated UI, and a Windows → iPhone shipping pipeline via GitHub Actions.

---

## 0. Locked decisions

| # | Decision | Choice | Notes |
|---|----------|--------|-------|
| 1 | Framework | **Flutter (Dart)** | iOS + Android from one codebase; can also target Windows/macOS/Linux desktop later |
| 2 | Dev machine | **Windows** | Full Flutter dev + Android testing works natively |
| 3 | iOS distribution | **GitHub Actions (macOS runners) → TestFlight/App Store** | Build + sign + submit iOS without owning a Mac |
| 4 | Users | **Solo / single-user** | No auth backend needed for MVP |
| 5 | Data | **Local-first, encrypted on-device (SQLite)** | Offline; secrets never leave the phone in v1 |
| 6 | Vault model | **One encrypted `VaultItem` type** | Cleaner than separate tables per credential type |

The key enabler: **the macOS GitHub Actions runner *is* your Mac.** Anything that genuinely requires macOS (Xcode build, code signing) runs there. You develop and test Android on Windows; iOS builds happen in CI. See §10.

---

## 1. Product vision

ClientVault is a personal command center for freelance/dev work. Each **client** has **projects**; each project tracks **payments** and links to a **GitHub repo**; and a secure **vault** holds the credentials (logins, API keys, server accounts) tied to those clients and projects. Local-first, fast, beautiful, with biometric-locked secrets and live repo status.

One line: *everything I need to run my client work — money, code, and credentials — behind one Face ID tap.*

---

## 2. Tech stack (Flutter)

| Layer | Choice | Notes |
|-------|--------|-------|
| Framework | **Flutter + Dart** | Verify latest stable channel at setup |
| Navigation | **go_router** | Declarative routing, deep links |
| UI / theming | **Material 3** (+ Cupertino where iOS-native feel matters) | Flutter's styling is built-in — no CSS layer needed |
| Animations | **`flutter_animate`** + built-in `AnimationController`/implicit animations + **Hero** | Flutter's animation system is a core strength |
| Charts / visuals | **`fl_chart`** + custom painters | For dashboard + budget visuals |
| Micro-animations | **`lottie`** | Optional delight |
| Local DB | **Drift** (type-safe SQLite) + `sqlite3_flutter_libs` | Reactive queries, migrations, codegen |
| Secure storage | **`flutter_secure_storage`** | iOS Keychain / Android Keystore — stores keys, not data |
| Biometrics | **`local_auth`** | Face ID / Touch ID / fingerprint |
| Crypto | **`cryptography`** package (AES-GCM, KDFs) | Argon2id via `cryptography`, or `pointycastle`/`argon2` as fallback. **Do not roll your own crypto.** |
| State | **Riverpod** (`flutter_riverpod`) | Modern, testable; `dio` for HTTP |
| GitHub auth | **`flutter_appauth`** (OAuth + PKCE) | PAT as a power-user fallback |
| Haptics | **`HapticFeedback`** (built into Flutter services) | Tactile feedback on copy/lock |
| CI/CD | **GitHub Actions** + optionally **fastlane** | See §10 |

---

## 3. MVP scope

### In the MVP (v1)
- **Clients**: create/edit/archive; name, company, contact, notes, tags.
- **Projects**: linked to a client; status, budget, due date, linked GitHub repo.
- **Payments**: simple records per project (amount, status: draft/sent/paid/overdue, dates).
- **Vault**: master-password setup, biometric unlock, encrypted CRUD for credentials/API keys/accounts; reveal + copy (auto-clear clipboard).
- **GitHub (read-only)**: OAuth login, list repos, link a repo to a project, show last commit / open issues / language on the project screen.
- **Dashboard**: overview cards — active projects, outstanding payments total, recent activity.
- **Security baseline**: encryption at rest, auto-lock, screenshot protection on vault screens.
- **Settings**: lock timeout, change master password, encrypted local backup/export + import.

### Deferred (post-MVP)
Cloud sync / multi-device · TOTP / 2FA code generation · invoice PDFs + payment reminders · creating GitHub issues from the app, webhooks, activity charts · multi-user/team sharing · time tracking. Keeping these out is what makes v1 shippable.

---

## 4. Feature modules

**Clients** — searchable list (filter by tag/status) → detail (contact, linked projects, linked vault items, payment summary).

**Projects** — list (filter by status/client) → detail (description, budget vs paid, due date, **linked repo card** with live status, linked payments, linked credentials). Statuses: `lead → active → paused → done`.

**Payments** — per-project records; project rolls up `total / paid / outstanding`; dashboard surfaces overdue. Currency per record.

**Vault** — locked list/grid by type (password, API key, account, secure note, card). Tap → biometric/master check → reveal. Each item links optionally to a client and/or project. Copy clears the clipboard after ~30s. Search on titles only (never bulk-decrypt).

**GitHub** — connect once via OAuth; browse repos; link one to a project. Project screen shows last commit (message + time), open issue count, language, stars. Token treated as a secret (secure storage).

**Dashboard** — at-a-glance cards + recent activity feed (new payment, repo commit, item added).

---

## 5. Data model

Secrets live encrypted; everything else is plaintext-but-on-device.

**Client** — `id (PK)`, name, company?, email?, phone?, notes?, status (`active|archived`), createdAt, updatedAt.

**Project** — `id (PK)`, `clientId (FK)`, name, description?, status (`lead|active|paused|done`), budget?, currency, startDate?, dueDate?, `repoId?`, `repoFullName?`, createdAt, updatedAt.

**Payment** — `id (PK)`, `projectId (FK)`, amount, currency, status (`draft|sent|paid|overdue`), issuedDate?, dueDate?, paidDate?, notes?.

**VaultItem** (the only encrypted table)
| Field | Type | Notes |
|-------|------|-------|
| id | uuid (PK) | plaintext |
| type | `password\|apiKey\|account\|note\|card` | plaintext (for filtering) |
| title | text | plaintext (for search/list) |
| clientId / projectId | uuid? (FK) | optional links |
| ciphertext | blob | **AES-256-GCM encrypted payload** |
| nonce | blob | unique per item |
| authTag | blob | GCM integrity tag |
| createdAt / updatedAt | timestamp | plaintext |

> Decrypted payload is JSON, e.g. `{ username, secret, url, totpSeed?, notes }`. Only `title` and `type` are searchable without unlocking.

**Tag** + join tables (cross-cutting labels with a color).

**VaultMeta** (one row — crypto config): `kdfSalt`, `kdfParams` (Argon2id memory/iterations/parallelism), `wrappedDEK` (DEK encrypted with the password-derived key), `verifier` (detects wrong master password).

> The GitHub OAuth token is **not** in the DB — it lives in `flutter_secure_storage`.

---

## 6. Architecture

```
┌──────────────────────────────────────────────┐
│              UI (Flutter + go_router)         │
│  Tabs: Dashboard · Projects · Clients · Vault │
│        · Settings   +  pushed detail screens  │
├──────────────────────────────────────────────┤
│        State: Riverpod · dio (GitHub)         │
├───────────────┬──────────────┬───────────────┤
│  Drift (ORM)  │ Crypto svc   │ GitHub client │
│  SQLite       │ (cryptography│ (OAuth+REST)  │
│               │  package)    │               │
├───────────────┼──────────────┼───────────────┤
│ sqlite3 (on   │ secure_      │  GitHub API   │
│ device)       │ storage +    │  (network)    │
│ encrypted     │ local_auth   │               │
│ blobs         │ (Keychain/   │               │
│               │  Keystore)   │               │
└───────────────┴──────────────┴───────────────┘
```

- **Local-first**: all reads/writes hit SQLite instantly; GitHub is the only network dependency and degrades gracefully offline.
- **Crypto service** is one module that owns the in-memory DEK and exposes `encrypt(obj)` / `decrypt(item)`. Nothing else touches keys.
- **Sync path (post-MVP)**: add Supabase (Postgres + RLS); vault items sync as **ciphertext only** — server never holds plaintext or the DEK (true end-to-end encryption).

---

## 7. Security model  ← the part that matters most

Design is framework-agnostic (identical to the original plan); only the libraries are Dart. Uses **envelope encryption** and never stores your master password.

### Key hierarchy
1. **Master password** (something you know) → never stored.
2. **KEK** = `Argon2id(masterPassword, kdfSalt, params)`.
3. **DEK** = random 256-bit key, generated once at setup.
4. `wrappedDEK = AES-256-GCM(DEK, KEK)` — persisted in `VaultMeta`.
5. Each **VaultItem** = `AES-256-GCM(payload, DEK, uniqueNonce)`.

### Flows
- **Setup**: generate DEK → user sets master password → derive KEK → wrap DEK → store `salt + kdfParams + wrappedDEK + verifier`. Persist **nothing** about the password.
- **Biometric unlock**: also wrap the DEK with a biometric-gated key in secure storage, so Face ID unlocks the same DEK without re-typing.
- **Unlock**: enter password (or biometrics) → derive/fetch KEK → unwrap DEK → hold in memory only.
- **Use**: encrypt/decrypt on demand with the in-memory DEK + a fresh random nonce each write.
- **Lock**: zero the DEK from memory on background and after the idle timeout.
- **Change master password**: re-derive KEK, re-wrap the *same* DEK — no need to re-encrypt every item.

### Hardening checklist
- AES-256-**GCM** only (authenticated; rejects tampered ciphertext).
- **Argon2id** KDF (memory-hard); PBKDF2-HMAC-SHA256 high-iteration fallback for old devices.
- Unique random nonce per encryption; never reuse.
- All keys/tokens in `flutter_secure_storage` (Keychain/Keystore) — never plain prefs.
- GitHub token is a secret → secure storage; minimal OAuth scopes.
- Screenshot/recents protection on vault screens (Android `FLAG_SECURE`; iOS blur on app switch).
- Auto-clear clipboard ~30s after copying a secret.
- Auto-lock on background + configurable idle timeout.
- No analytics/telemetry touching vault contents — ever.
- Use **audited libraries**; do not invent crypto.

### Threat model
**Protects against:** lost/stolen device, casual snooping, shoulder-surfing, screenshot leaks, at-rest DB inspection.
**Does *not* fully protect against:** a rooted/jailbroken or malware-infected device, a keylogger, or someone with your *unlocked* phone and master password.

> Coursework note: a single-user, local-first vault on vetted crypto with this envelope design is a solid, defensible project. The bar rises sharply if it ever becomes multi-user or stores *clients'* credentials — then you'd want a security review and should lean on established secret managers rather than reinventing them.

---

## 8. UI/UX & design system

Aesthetic: **dark-mode-first "secure fintech"** — deep neutral background, one vivid accent, generous spacing, rounded cards, subtle depth.

**Navigation:** bottom tabs → `Dashboard · Projects · Clients · Vault · Settings`, with pushed detail routes (go_router).

**Core screens:** onboarding + master-password setup (strength meter) · lock screen (biometric + password fallback) · dashboard · projects list/detail · clients list/detail · vault (locked list → reveal sheet) · payments overview · GitHub repo browser + link flow · settings.

**Animation touchpoints** (what makes it feel "amazing"):
- Hero transitions list → detail.
- Animated reveal for secrets (blur-to-clear) with a haptic tick.
- Skeleton loaders + smooth empty states (`flutter_animate`).
- Spring bottom sheets and modals.
- Pull-to-refresh on repos; animated count-ups on dashboard totals.
- Haptics on copy, lock, and successful save.

> When we build the UI, I'll follow the environment's frontend design guidelines for polish and consistency.

---

## 9. GitHub integration spec

- **Auth**: OAuth 2.0 + PKCE via `flutter_appauth` (register a GitHub OAuth app). **Minimal scopes** — `repo` only if you need private repos, else `public_repo` + `read:user`. PAT field as a power-user fallback.
- **Token storage**: `flutter_secure_storage`.
- **API**: GitHub REST v3 (simple) or GraphQL v4 (fewer round-trips). MVP: list user repos; repo detail (last commit, open issues, language, stars).
- **Linking**: store `repoFullName` on the Project; detail screen fetches live status, cached via Riverpod/dio, refreshed on pull.
- **Post-MVP**: create issues from a project, commit-activity charts, optional webhooks → push notifications.

---

## 10. Build & deployment — Windows → iPhone via GitHub Actions

This is the linchpin that made Flutter viable for your setup. You **cannot** build/sign iOS locally on Windows (Xcode is macOS-only), but GitHub's **macOS runners ship with Xcode**, so the whole iOS build + sign + submit happens in CI.

### Recommended pipeline shape
Split work by cost: cheap Linux jobs on every push, the expensive macOS iOS build only on release tags.

```yaml
# .github/workflows/release-ios.yml  (skeleton — we'll flesh this out together)
on:
  push:
    tags: ['v*']          # iOS build runs only on release tags
jobs:
  ios:
    runs-on: macos-latest # this runner is your Mac
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs   # Drift codegen
      # --- code signing (fastlane match syncs certs/profiles from a private repo) ---
      - run: bundle exec fastlane match appstore --readonly
      # --- build the signed IPA ---
      - run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
      # --- upload to TestFlight / App Store via App Store Connect API ---
      - run: bundle exec fastlane pilot upload   # or `deliver` for App Store
```

```yaml
# .github/workflows/ci.yml  (cheap, every push)
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest   # Linux = cheapest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --debug   # validate Android build
```

### Code signing without a Mac
The fiddliest first-time step. The standard tame-it approach:
- **fastlane match** generates and stores your Apple distribution certificate + provisioning profile (encrypted) in a private git repo, then syncs them into the runner. It creates the certs itself, so no Mac-side CSR is needed; any genuinely Mac-only step runs on the macOS runner anyway.
- **App Store Connect API key** (`.p8`, generated in the App Store Connect web UI — no Mac) authenticates uploads and signing without interactive Apple login/2FA.

Expect the first pipeline setup to take an evening. After that, it's push a tag → app on TestFlight.

### GitHub secrets to configure (repo → Settings → Secrets)
- `APP_STORE_CONNECT_API_KEY` (base64 `.p8`), `..._KEY_ID`, `..._ISSUER_ID`
- `MATCH_GIT_URL` + a deploy key/PAT, and `MATCH_PASSWORD` (passphrase)
- (If not using match: base64 `.p12` cert + password, base64 provisioning profile)
- *No real secrets ever get committed — they live here, encrypted.*

### Cost reality (current, 2026)
- macOS runners ≈ **$0.05–0.06/min** (after the Jan 2026 ~39% cut).
- On a **private** repo, macOS minutes draw your free allowance at a **10× rate**.
- Free plan = 2,000 min/mo (≈ **~200 macOS min**); Pro = 3,000 (≈ **~300 macOS min**).
- A Flutter iOS build ≈ 10–15 min → ~13–20 free builds/month on Free tier.
- **Build iOS on release tags only** (tests/Android on Linux for every push) → a solo project stays within free tier; overage is a few $/month worst case.
- **Keep ClientVault a private repo** (security app + signing config). Public repos get free standard runners but you don't want this code public.
- **Tips:** grab the **GitHub Student Developer Pack** (free Pro). Or use **Codemagic** — a Flutter-native CI with its own free macOS build minutes — if you prefer a Flutter-focused dashboard.

### Android (the easy side)
Build/sign Android locally on Windows (`flutter build appbundle`) and ship to Google Play, or do it in the Linux CI job. No special hardware needed.

---

## 11. RTD — Requirements

### Functional requirements
- **FR-1** Create/edit/archive clients with contact info and tags.
- **FR-2** Create/edit projects linked to a client (status, budget, due date).
- **FR-3** Link a GitHub repo to a project and show its live status.
- **FR-4** Record payments per project; roll up total/paid/outstanding; flag overdue.
- **FR-5** Set a master password; unlock via password or biometrics.
- **FR-6** Encrypted CRUD for vault items (password, API key, account, note, card), optionally linked to a client/project.
- **FR-7** Reveal and copy a secret; clipboard auto-clears.
- **FR-8** Dashboard shows active projects, outstanding total, recent activity.
- **FR-9** Search clients/projects by name and vault items by title.
- **FR-10** Export/import an encrypted local backup.

### Non-functional requirements
- **NFR-1 Security**: AES-256-GCM at rest; Argon2id KDF; keys in Keychain/Keystore; auto-lock; screenshot protection.
- **NFR-2 Performance**: 60fps animations; instant local reads; lazy-decrypt (never bulk-decrypt the vault).
- **NFR-3 Offline-first**: full functionality offline; GitHub features fail gracefully.
- **NFR-4 Portability**: one codebase on iOS + Android; desktop targets available later.
- **NFR-5 Data portability**: encrypted backup/restore; no lock-in.
- **NFR-6 Privacy**: no third-party analytics on vault data; secrets stay on-device in v1.
- **NFR-7 Buildability**: iOS ships from Windows via GitHub Actions; reproducible, tag-triggered releases.
- **NFR-8 Reliability**: versioned, reversible DB migrations.

---

## 12. Build roadmap (milestones)

| Phase | Goal | Rough size |
|-------|------|-----------|
| **0 — Setup** *(tonight)* | Flutter scaffold + go_router + Material 3 theme + Drift + folder structure + git repo + 5-tab skeleton | 1–2 hrs |
| **0.5 — Prove the pipeline** *(early!)* | Get a trivial build onto **TestFlight via GitHub Actions** before building features | the unlock |
| **1 — Core CRUD** | Clients + Projects (linked) + basic Dashboard | small sprint |
| **2 — Vault** | Crypto service, master password, biometric lock, encrypted item CRUD | the meaty one |
| **3 — Payments** | Records + project roll-ups + overdue flags | small |
| **4 — GitHub** | OAuth + repo browser + link to project + live status | medium |
| **5 — Polish** | Animations, haptics, skeletons, empty states, themes, encrypted backup | ongoing |
| **6 — Post-MVP** | Cloud sync (E2E), TOTP, notifications, desktop build, multi-device | future |

> **Why Phase 0.5 is early:** the worst outcome is building the whole app on Windows and only discovering iOS signing/CI pain at the end. Validate the Windows → iPhone path with a hello-world build *first*, then build features with confidence.

---

## 13. First session plan — "when you get home"

**Step 1 — scaffold** (confirm the latest stable Flutter channel first):
```bash
flutter create clientvault
cd clientvault
git init && git add -A && git commit -m "chore: scaffold ClientVault"
```

**Step 2 — add core deps:**
```bash
flutter pub add go_router drift sqlite3_flutter_libs path_provider path \
  flutter_secure_storage local_auth cryptography \
  flutter_riverpod dio flutter_appauth flutter_animate fl_chart lottie
flutter pub add --dev drift_dev build_runner
```

**Step 3 — session checkpoints:**
1. 5-tab navigation renders with placeholder screens (go_router).
2. Material 3 dark theme + design tokens (colors, spacing, radii, typography).
3. Drift schema + first migration for `Client` and `Project`; create + list a client end-to-end (run `build_runner`).
4. Commit.

**Step 4 — kick off Phase 0.5** (can run in parallel/next):
1. Create the GitHub OAuth app + Apple App Store Connect API key.
2. Add the two workflow files from §10.
3. Set up `fastlane match` and the GitHub secrets.
4. Push a `v0.0.1` tag → confirm the build lands on TestFlight.

---

## 14. Open questions

1. **Signing approach** — `fastlane match` (recommended, scales cleanly) or manual cert/profile secrets to start?
2. **iOS distribution target** — TestFlight only at first (faster, no review), or straight to App Store review?
3. **Desktop** — want a Windows/macOS desktop build of ClientVault on the roadmap, or mobile-only?
4. **Theme** — dark-only for MVP, or dark + light toggle?
5. **GitHub Student Pack** — do you already have it / want me to flag what's useful in it for this project?
6. **Coursework overlap** — should the vault crypto be written up exam-ready (deeper rationale), or purely a personal tool?

Answer these tonight and we start at Step 1.
