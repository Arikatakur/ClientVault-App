# SwiftUI Architecture

How the native app is organized. Companion to [`rewrite-blueprint.md`](rewrite-blueprint.md).

## Layers

```
Views (SwiftUI)  ──reads/observes──▶  Stores / ViewModels (@Observable)
                                            │ depend on protocols
                                            ▼
                          Services (APIClient, CryptoService, KeychainStoring, …)
                                            │
                                            ▼
                          Domain entities  ◀──map──▶  DTOs (wire)  ◀──▶  Backend
```

- **Views** hold no business logic. They render state and forward intent.
- **Stores / ViewModels** are `@Observable` classes injected via the SwiftUI
  environment. They orchestrate services and expose loading/error/empty state.
- **Services** are protocol-typed so features depend on abstractions and tests can
  substitute fakes.
- **Domain** is the app's vocabulary; **DTOs** are transport shapes. `Mapping.swift`
  converts between them so wire changes never leak into the UI.

## Dependency injection

`App/AppEnvironment.swift` is the composition root. `AppEnvironment.live()` wires
the production implementations; the app injects the container (and select stores)
into the environment:

```swift
RootView()
    .environment(environment)
    .environment(environment.session)
    .environment(environment.entitlements)
```

Features read what they need:

```swift
@Environment(SessionStore.self) private var session
```

Swap `AppEnvironment.live()` for a test/preview factory to inject fakes.

## Navigation

`App/MainTabView.swift` — a `TabView` with five tabs, each wrapping its root in a
`NavigationStack` so per-tab navigation state is preserved independently.
`App/RootView.swift` switches between the auth flow and the tab shell based on
`SessionStore.phase`.

Tabs: **Dashboard · Projects · Clients · Vault · Settings**.

## State & concurrency

- State via Observation (`@Observable`). Stores mutate from the main thread (UI
  actions); they are intentionally not actor-isolated to keep the DI graph simple.
- Async work uses Swift Concurrency (`async/await`). The `APIClient` is `Sendable`.
- Strict concurrency is set to `targeted` in `project.yml`; revisit once the app
  grows.

## Design system (`Core/DesignSystem`)

| File | Tokens |
|------|--------|
| `Palette.swift` | semantic colors (surfaces, accent, status, vault) |
| `Typography.swift` | rounded type ramp, Dynamic Type-aware |
| `Spacing.swift` | 4-pt spacing scale + corner radii |
| `Motion.swift` | the single motion spec (durations, springs, reveal/none) |
| `Haptics.swift` | success/warning/error/selection/impact |

Use tokens, never magic numbers. The privacy shield uses `Motion.none` so
sensitive content never animates into view.

## Privacy shield

`ClientVaultApp` watches `scenePhase`. On anything other than `.active` it overlays
`SharedUI/PrivacyShieldView` instantly (no transition), so the app-switcher
snapshot shows the branded lock cover. Entering background also auto-locks the
vault via `SessionStore.onEnteredBackground()`.

## Testing

`ClientVaultTests/` covers the foundation: crypto primitives, DTO↔domain mapping,
and design tokens. Run with `xcodebuild ... test` (CI does this on every push).
Add tests alongside each new service and mapping.

## Project generation

`project.yml` (XcodeGen) defines targets, settings, the version, Info.plist, and
entitlements. The `.xcodeproj` is generated, **not** committed (`xcodegen generate`).
This keeps the project reviewable in git and authorable on Windows.
