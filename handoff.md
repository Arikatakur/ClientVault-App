# ClientVault — Handoff

> Last updated: 2026-06-16. Resume from here next session.

---

## Where we are

**Version:** `0.20.0+22`
**Phase 3 (Clients + Projects) is complete.** Full list UX, detail screens, add/edit
forms, cross-linking, and in-memory dev repos are all done and committed.

**Next phase:** `0.21.0` — Payments.

---

## Milestone map (abridged)

| Version | Phase | Status |
|---------|-------|--------|
| `0.18.0` | Foundation — scaffold, design system, nav shell, privacy shield, crypto core | ✅ done |
| `0.19.0` | Auth — Apple + Google sign-in, session persistence, account deletion | ✅ done |
| `0.20.0` | Clients + Projects — cloud CRUD, search, swipe, premium list UX | ✅ done |
| **`0.21.0`** | **Payments — invoices, partials, overdue, reminders, dashboard rollups** | ← **next** |
| `0.22.0` | Vault — Argon2id, full key hierarchy, ciphertext sync, reveal sheet, biometric | |
| `0.23.0` | Settings + Plan — StoreKit entitlements, auto-lock wired | |
| `0.24.0` | Push — APNs registration, optional cross-device | |
| `0.25.0` | Polish — error UX, animations, empty/loading, backup/export | |
| `0.26.0` | TestFlight candidate — app icon, signing, release CI | |
| `1.0.0` | App Store MVP | |

---

## What to build next: `0.21.0` Payments

Payments are per-project. The domain entity (`Payment`) and DTO (`PaymentDTO`) and
mapping already exist in `Domain/`. The `VaultView` is still a placeholder.

### What needs to be built

- [ ] `PaymentRepository` protocol + `InMemoryPaymentRepository` + `LivePaymentRepository`
  - `list(projectId:)`, `create`, `update`, `delete`
- [ ] `PaymentsViewModel` (`@Observable`) — list per-project, rollup totals
  (invoiced, paid, outstanding), overdue detection
- [ ] Project detail view: add a **Payments section** to `ProjectDetailView`
  showing per-project payment rows with status badges and roll-up totals
- [ ] Add/edit payment form — amount (minor units + currency), status, due date, paid
  date (shown when status = paid), optional note
- [ ] Dashboard tile live counts — wire "Outstanding" tile in `DashboardView`
  by summing unpaid `amountMinorUnits` across `projectsVM.projects`
- [ ] Local notifications (optional, part of this phase per blueprint) — schedule
  reminders for unpaid payments with a due date; use the existing
  `LocalNotificationScheduler`

### Overdue logic

A payment is overdue when `status != .paid` and `dueDate < Date()`. The domain
entity carries `status: PaymentStatus` (pending / partial / paid / overdue).
The `.overdue` case can be computed on the fly or stored — keep it computed so it
never goes stale.

### Money display

`amountMinorUnits: Int` + `currencyCode: String` (ISO 4217). Format for display:
```swift
let amount = Decimal(payment.amountMinorUnits) / 100
// use NumberFormatter with .currencyCode
```
Never use `Double` for money.

---

## Key files to know

| Path | Purpose |
|------|---------|
| `project.yml` | Version source of truth (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`) |
| `ClientVault/App/AppEnvironment.swift` | DI root — add `paymentsVM` here |
| `ClientVault/Domain/Entities.swift` | `Payment`, `PaymentStatus` already defined |
| `ClientVault/APIModels/DTOs.swift` | `PaymentDTO` already defined |
| `ClientVault/Domain/Mapping.swift` | `Payment` ↔ `PaymentDTO` mapping already done |
| `ClientVault/Features/Clients/ClientRepository.swift` | Pattern to copy for PaymentRepository |
| `ClientVault/Features/Projects/ProjectDetailView.swift` | Add payments section here |
| `ClientVault/Features/Dashboard/DashboardView.swift` | Wire the "Outstanding" tile |
| `ClientVault/Services/Notifications/LocalNotificationScheduler.swift` | Due-date reminders |

---

## Architecture reminders

- **Dev fallback pattern:** `config.hasBackend ? Live… : InMemory…` in `AppEnvironment.live()`
- **Soft deletes:** set `deletedAt`, filter in `list()`, don't hard-delete
- **Money:** `amountMinorUnits: Int` + `currencyCode: String` — never `Double`
- **UUIDs are client-minted** — creates are idempotent
- **No business logic in views** — ViewModels/Stores are `@Observable`
- **ProjectsVM.filtered(clients:)** takes a clients array for cross-search; same
  pattern may be needed for PaymentsVM if it needs project/client context
- The project is **authored on Windows** — build gate is CI (`.github/workflows/ios-ci.yml`)

---

## Version bump checklist (for 0.21.0)

1. `project.yml`: `MARKETING_VERSION: "0.21.0"`, `CURRENT_PROJECT_VERSION: "23"`
2. `CHANGELOG.md`: add `## [0.21.0]` section
3. Conventional commit: `feat(payments): …`
4. Tag: `git tag v0.21.0 && git push origin v0.21.0` (when user asks to push)
