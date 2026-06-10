# Version Milestones

The blueprint's 7-phase delivery plan mapped to semantic versions.

The native app **continues the version line at `0.18.0`**, not `0.1.0`. The Flutter
app shipped through `0.17.0+19`, and App Store Connect rejects any TestFlight/App
Store upload whose version or build number isn't greater than the last. So the
rewrite's foundation is `0.18.0` and minor bumps continue from there. (Build number
`CURRENT_PROJECT_VERSION` starts at `20`, above the old `+19`.)

| Version | Phase | Scope | Status |
|---------|-------|-------|--------|
| `0.18.0` | 1 — Foundation | XcodeGen scaffold, design system, nav shell, privacy shield, core service seams, crypto core, docs, CI | ✅ done |
| `0.19.0` | 2 — Auth | Sign in with Apple + Google, backend token exchange seam (+ dev fallback), session persistence, account deletion | ✅ done |
| `0.20.0` | 3 — Clients + Projects | Cloud CRUD, search, swipe actions/context menus, clients ↔ projects, premium list UX | |
| `0.21.0` | 4 — Payments | Per-project invoices/payments, partials, overdue flag, local reminders, dashboard rollups | |
| `0.22.0` | 5 — Vault | Argon2id (vetted dep), full key hierarchy, ciphertext sync, lazy reveal sheet (blur→clear), biometric unlock, clipboard auto-clear | |
| `0.23.0` | 6 — Settings + Plan | Entitlements UX gate + StoreKit, server-validation webhook seam, auto-lock/biometric settings wired | |
| `0.24.0` | 7 — Push | APNs registration upload, optional cross-device pushes, repo-activity (optional) | |
| `0.25.0`+ | Polish | error UX states, animations, haptics, empty/loading states, backup/export | |
| `0.26.0` | TestFlight candidate | app icon, splash, signing (Fastlane Match), `release-ios.yml` (tag `v*`), legal/support links | |
| `1.0.0` | MVP | stable MVP, all critical modules, App Store-ready | |

## Definition of done per phase

A phase is done when its acceptance criteria from
[`rewrite-blueprint.md`](rewrite-blueprint.md) pass, tests exist for new crypto /
mapping / token handling, CI is green, the changelog + version are bumped, and the
work is committed and pushed.
