# ClientVault — Handoff

> Last updated: 2026-06-16. Resume from here next session.

---

## Where we are

**Version:** `0.21.0+23`
**Phase 4 (Payments) is complete.** Per-project payment tracking, rollup totals,
live dashboard counts, and `PaymentsViewModel` are all done and committed.

**Next phase:** `0.22.0` — Vault.

---

## Milestone map (abridged)

| Version | Phase | Status |
|---------|-------|--------|
| `0.18.0` | Foundation — scaffold, design system, nav shell, privacy shield, crypto core | ✅ done |
| `0.19.0` | Auth — Apple + Google sign-in, session persistence, account deletion | ✅ done |
| `0.20.0` | Clients + Projects — cloud CRUD, search, swipe, premium list UX | ✅ done |
| `0.21.0` | Payments — invoices, partials, overdue, dashboard rollups | ✅ done |
| **`0.22.0`** | **Vault — Argon2id, full key hierarchy, ciphertext sync, reveal sheet, biometric** | ← **next** |
| `0.23.0` | Settings + Plan — StoreKit entitlements, auto-lock wired | |
| `0.24.0` | Push — APNs registration, optional cross-device | |
| `0.25.0` | Polish — error UX, animations, empty/loading, backup/export | |
| `0.26.0` | TestFlight candidate — app icon, signing, release CI | |
| `1.0.0` | App Store MVP | |

---

## What to build next: `0.22.0` Vault

The Vault stores encrypted secrets (passwords, API keys, notes, cards) using the
zero-knowledge model defined in `docs/security-model.md`. The `VaultItem` entity
and DTO and mapping already exist in `Domain/`.

### What needs to be built

- [ ] **Key derivation** — `VaultKeyManager`: derive a 256-bit vault key from the
  user's master password using Argon2id (via a vetted Swift library, e.g.
  `swift-sodium`). Expose `unlock(password:)` and `lock()`. Store the derived key
  in memory only; never persist it.
- [ ] **Encryption** — `CryptoService` (`AESGCMCrypto`) is already wired.
  Use it to encrypt/decrypt `VaultItemBody` (the secret payload). The body is a
  `Codable` struct with the secret fields; encode to `Data`, encrypt to
  `EncryptedPayload`, store ciphertext on the server.
- [ ] **`VaultItemRepository`** — protocol + `InMemoryVaultItemRepository` +
  `LiveVaultItemRepository`; same CRUD pattern as the payment/client repos.
- [ ] **`VaultViewModel`** (`@MainActor @Observable`) — list, search by title/type,
  add/update/delete; holds the vault key (in memory), exposes `isLocked`.
- [ ] **`VaultView`** — currently a placeholder; replace with a full list:
  searchable, grouped by type or flat, row shows title + type badge.
- [ ] **Reveal sheet** — tapping a vault item shows the decrypted secret with a
  copy button; clipboard auto-clears after 60 s.
- [ ] **Biometric unlock** — `LAContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)`
  to unlock on return from background (if the vault was locked).
- [ ] **Auto-lock** — lock the vault on background / after a configurable timeout.

### Security invariants (from CLAUDE.md §18 and docs/security-model.md)

- **Never transmit plaintext secret fields.** Encrypt on-device before any
  network call. Server stores only `EncryptedPayload` (ciphertext + nonce + tag).
- **Never persist the vault key.** Keep it in memory only; wipe on lock.
- **Use random nonces** (CryptoKit default). Never reuse.
- **Clipboard auto-clear** — schedule a task to clear after 60 s.
- **Privacy shield** already covers the app-switcher snapshot; no extra work
  needed there.

### Argon2id dependency

Add `swift-sodium` (or equivalent vetted library) to `project.yml` as a Swift
Package Manager dependency. Do not use `CommonCrypto` for KDF — it only has
PBKDF2. `CryptoKit` does not expose Argon2id.

---

## Payments phase — what was deferred (optional follow-up)

Local notification reminders (`LocalNotificationScheduler`) for unpaid payments
with a due date were scoped as optional in `0.21.0` and not implemented. These
can be added in a `0.21.1` patch or folded into `0.25.0` (Polish):

- Inject `LocalNotificationScheduling` into `PaymentsViewModel`.
- On `add` / `update`: if `status != .paid && dueDate != nil`, call
  `scheduler.schedule(id: "payment-\(id)", ...)` 1 day before due date.
- On `delete` / mark paid: call `scheduler.cancel(id:)`.
- Request notification authorization once at first add (not at launch).

---

## Key files to know

| Path | Purpose |
|------|---------|
| `project.yml` | Version source of truth (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`) |
| `ClientVault/App/AppEnvironment.swift` | DI root — add `vaultVM` here for 0.22.0 |
| `ClientVault/Domain/Entities.swift` | `VaultItem`, `VaultItemType` already defined |
| `ClientVault/APIModels/DTOs.swift` | `VaultItemDTO` already defined |
| `ClientVault/Domain/Mapping.swift` | `VaultItem` ↔ `VaultItemDTO` mapping already done |
| `ClientVault/Core/Crypto/` | `CryptoService` (AES-GCM), `EncryptedPayload` — ready to use |
| `ClientVault/Features/Vault/VaultView.swift` | Placeholder to replace |
| `ClientVault/Features/Payments/PaymentRepository.swift` | Pattern to copy for VaultItemRepository |
| `docs/security-model.md` | Zero-knowledge key hierarchy — read before writing any vault code |

---

## Architecture reminders

- **Dev fallback pattern:** `config.hasBackend ? Live… : InMemory…` in `AppEnvironment.live()`
- **Soft deletes:** set `deletedAt`, filter in `list()`, don't hard-delete
- **Money:** `amountMinorUnits: Int` + `currencyCode: String` — never `Double`
- **UUIDs are client-minted** — creates are idempotent
- **No business logic in views** — ViewModels/Stores are `@Observable` + `@MainActor`
- **Single shared VMs** — `PaymentsViewModel` (and future `VaultViewModel`) live in
  `AppEnvironment` so the dashboard and detail screens share the same data
- The project is **authored on Windows** — build gate is CI (`.github/workflows/ios-ci.yml`)

---

## Version bump checklist (for 0.22.0)

1. `project.yml`: `MARKETING_VERSION: "0.22.0"`, `CURRENT_PROJECT_VERSION: "24"`
2. `CHANGELOG.md`: add `## [0.22.0]` section
3. Conventional commit: `feat(vault): …`
4. Tag: `git tag v0.22.0 && git push origin v0.22.0` (when user asks to push)
