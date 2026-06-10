# ClientVault iOS Rewrite Blueprint (SwiftUI + Cloud Backend)

> **In-repo mirror** of the Notion page *"ClientVault iOS Rewrite Blueprint
> (SwiftUI + Cloud Backend)"* (fetched 2026-06-10). This is the **single source
> of truth** for the rewrite. If this and the Notion page diverge, reconcile them.

This is a build spec + implementation blueprint for rewriting ClientVault as a
native iOS (SwiftUI) app with a cloud backend (no local-only mode).

## Product goals (non-negotiables)
- **Premium iOS UI/UX**: native, fast, delightful; Apple-quality motion,
  typography, haptics, micro-interactions.
- **Zero-knowledge Vault remains**: the server must never see plaintext vault
  secrets. Metadata minimization required.
- **Cloud-first**: multi-device, server-backed; offline optional, not primary.
- **Account-based**: Sign in with Apple + Google + optional email/password.
- **Secure by design**: strict threat model, E2E encryption for vault secrets,
  secure key handling, rate limiting, device binding, auditability.

## Non-goals / scope control
- Android app (out of scope).
- Cross-platform UI parity (irrelevant).
- Full enterprise compliance (SOC2) on day 1 — but architecture must not block it.

## High-level architecture
**iOS app (SwiftUI + Swift Concurrency)** → **API layer** → **Backend** →
**Database + Object storage + Push**.

Backend options (pick one, implement end-to-end):
- **Option A (recommended): AWS Amplify Gen 2** — Cognito (Apple/Google
  federation), AppSync (GraphQL) or API Gateway + Lambda (REST), DynamoDB (or
  Aurora Serverless v2), S3, SNS/Pinpoint for device tokens.
- **Option B: Supabase** — Supabase Auth, PostgREST + Edge Functions, Postgres +
  RLS, Storage buckets, APNs via a server function.
- **Option C: Firebase** — Firebase Auth, Cloud Functions, Firestore, Cloud
  Storage, FCM/APNs.

**Decision:** default to **Option A (AWS Amplify Gen 2)** — scales cleanly and
keeps auth + push + storage in one platform. See `backend-amplify.md`.

## Security & crypto model (zero-knowledge vault)
**Data classification**
- *Plaintext allowed on server (minimize)*: account identifiers, non-sensitive
  profile; client/project/payment names may be plaintext if the user accepts
  (prefer encrypting if feasible); vault item *metadata* (title + type, optional tags).
- *Must be encrypted client-side before upload*: vault item secret bodies
  (passwords, API keys, secure notes, cards), secret attachments.

**Key hierarchy**
- **Master Key (MK)** from a vault password and/or device-bound Secure Enclave key.
- **Data Encryption Key (DEK)**: random 256-bit per-user key.
- **Item keys**: encrypt each item with DEK + unique nonce, or derive per-item
  subkeys via HKDF.

**KDF**: Argon2id; store params with the vault config; allow raising cost over
time while staying backward compatible.

**Storage (server)**: encrypted vault items (ciphertext + nonce + version),
wrapped DEK (DEK encrypted under an MK-derived key), vault config (KDF params,
cipher version, timestamps). Server never receives MK or plaintext secrets.

**Biometric unlock**: a `biometryCurrentSet`-protected Keychain entry unlocks the
DEK without the vault password (opt-in). If biometrics change, it invalidates and
falls back to the password.

**Threat-model checklist**: no plaintext secrets in logs/analytics; clipboard
clearing; app-switcher snapshot protection; brute-force protection (local
backoff + server rate limits); TLS only (pinning optional); Keychain only,
never `UserDefaults`.

## Functional requirements
1. **Auth + Account** — Apple, Google, optional email/password, account deletion
   (Apple requirement), sign out.
2. **Clients** — CRUD, search, optional attachments, clients ↔ projects.
3. **Projects** — CRUD, status (lead/active/paused/done), due date + reminders,
   optional GitHub repo link.
4. **Payments** — per-project invoices/payments, partial payments, overdue flag,
   reminders.
5. **Vault** — lock/unlock, items CRUD, lazy reveal sheet, link to client/project,
   search + tags.
6. **Backup/Export** — cloud-first; optional encrypted export (`.cvbackup`-style)
   for portability.
7. **Plan/Premium** — entitlement model (UX gate), server-side validation later
   (webhook → backend).

## iOS implementation blueprint (SwiftUI)
- SwiftUI + Swift Concurrency, minimal UIKit bridging.
- Networking: `URLSession` + `Codable` + structured errors (Alamofire only if needed).
- DI: lightweight container / protocol-based injection.
- State: `@Observable` (Observation) or `ObservableObject` + `@StateObject`.
- Persistence: cloud-first; optional offline cache via GRDB (recommended) or SwiftData.

**Folder structure** (as implemented): `App/`, `Core/` (Networking, Crypto,
Storage, DesignSystem, Telemetry), `Features/` (Auth, Dashboard, Clients,
Projects, Payments, Vault, Settings), `SharedUI/` (Components, Animations),
`Services/` (Push, Notifications, Entitlements), `APIModels/`, `Domain/`, `Tests/`.

## Premium UI/UX requirements
- `NavigationStack` per tab with state preservation; native list behaviors (swipe
  actions, context menus, integrated search); sheets with detents + material blur,
  interactive dismiss disabled for destructive ops unless confirmed.
- A single **motion spec** (durations, springs, easing); shared/matched-geometry
  transitions; list insertion/deletion animations; reveal-sheet crossfade with a
  secure blur-to-clear for secrets.
- Haptics on unlock/copy/destructive — consistent and minimal.
- Friendly branded empty states with one obvious action; smooth empty→populated.
- **Privacy shield**: cover UI instantly when inactive/background; no snapshots
  with sensitive content.

## Auth implementation
- **Apple**: `AuthenticationServices`, scopes `.fullName`/`.email` (first login);
  backend validates the Apple identity token, creates/looks up the user.
- **Google**: GoogleSignIn SDK; backend validates the Google ID token.
- **Session**: short-lived access token + refresh token (or Cognito tokens);
  access token in memory, refresh token in Keychain; sign-out clears both.

## Backend API (conceptual)
- **Auth**: `POST /auth/apple|google|email/login|email/signup|refresh|logout`,
  `DELETE /account`.
- **Core**: `GET/POST/PATCH/DELETE` for `/clients`, `/projects`, `/payments`.
- **Vault**: `GET/PUT /vault/config`, `GET/POST/PATCH/DELETE /vault/items`
  (ciphertext only), optional `/vault/attachments`.
- **Sync**: per-entity `updatedAt` + conflict policy (vault: last-write-wins;
  others may merge).

## Database (conceptual)
Entities: `users`, `clients`, `projects` (FK clientId), `payments` (FK projectId),
`vault_config` (FK userId), `vault_items` (FK userId, optional client/project),
`attachments`. Required fields: `id` (UUID), `createdAt`, `updatedAt`, soft delete.
Permissions: rows scoped by `userId`, enforced at the DB/auth-rule level.

## Push + local notifications
Local notifications for payment-due reminders and project deadlines. Push for
cross-device changes / repo activity (optional). iOS obtains the APNs token;
backend stores it per user+device and triggers via the provider.

## GitHub integration (optional)
Do not store a PAT in the backend unless E2E-encrypted. Prefer OAuth (needs
backend). Minimal v1: read-only repo metadata via an OAuth token in the Keychain.

## Delivery plan (build order)
1. Bootstrap + design system + nav shell + privacy shield.
2. Auth end-to-end (Apple + Google) with backend validation + provisioning.
3. Clients + Projects cloud CRUD + search + premium list UX.
4. Payments + reminders.
5. Vault crypto + cloud ciphertext + reveal sheet + biometric unlock.
6. Settings + Plan/entitlements scaffolding.
7. Push registration seam + optional pushes.

## Acceptance criteria
- Feels native (motion, haptics, typography, list behaviors).
- Auth works (Apple/Google), survives restarts.
- Cloud CRUD reliable; no cross-user data leaks.
- Vault secrets never uploaded in plaintext; server stores only ciphertext.
- App-switcher never shows sensitive content.
- Unit tests for crypto primitives and critical mapping.
- Friendly error UX: offline, rate limited, session expired, invalid vault
  password, corrupted vault item.

## Operating instructions
- Treat this document as the single source of truth.
- Build iOS-only with SwiftUI; implement one backend stack end-to-end (no mixing).
- Keep code modular/testable; avoid god objects.
- Tests for crypto, auth token handling, API mapping.
- **Never** log secrets, print decrypted vault fields, or send plaintext vault
  secrets to analytics.

> **Security rule:** vault secret fields must be encrypted on-device before any
> network transmission. If unsure, stop and implement encryption first.
