# CLAUDE.md

## Project Instructions for Claude Code

This file defines the development workflow, Git rules, versioning system, commit style, changelog requirements, release process, and Flutter-specific engineering standards for this project.

Claude must follow these instructions whenever working on this repository.

---

# 1. Project Context

This is a Flutter mobile app project.

Target platforms:

- iOS
- Later: Android
- Later optional: Windows, macOS, Linux

Primary stack:

- Flutter
- Dart
- Material 3
- Riverpod
- go_router
- Drift / SQLite
- flutter_secure_storage
- local_auth
- GitHub Actions
- Fastlane / TestFlight

The app is intended to become a real production mobile app, not just a demo.

Claude should behave like a senior Flutter engineer.

---

# 2. Main Rule

Every meaningful update must be treated as a versioned change.

After each completed version, Claude must:

1. Update the app version.
2. Update the changelog.
3. Create clear commits.
4. Push the changes to GitHub.
5. Clearly explain what changed.

Do not leave important work uncommitted.

Do not commit broken builds unless the commit is clearly marked as a temporary work-in-progress and the app still runs.

---

# 3. Versioning System

Use semantic versioning:

```txt
x.y.z
```

Examples:

```txt
0.1.0
0.2.0
0.2.1
1.0.0
```

## 3.1 Version Meaning

### x = Major Version

Increase `x` for big changes.

Use this when:

- the app architecture changes heavily
- core data/storage structure changes in a breaking way
- old local database migrations may not be compatible
- a major feature set is added
- the app reaches a public launch milestone
- the app moves from MVP to production-ready

Examples:

```txt
0.9.0 -> 1.0.0
1.0.0 -> 2.0.0
```

Example major updates:

- App Store launch version
- replacing the whole app architecture
- moving from local-only to cloud sync
- redesigning the entire app navigation
- changing the encryption/storage model in a breaking way

---

### y = Minor Version

Increase `y` for medium-sized changes.

Use this when:

- adding a new feature
- adding a new screen
- adding a new module
- adding a new service
- improving an existing system significantly
- adding TestFlight/App Store release support

Examples:

```txt
0.1.0 -> 0.2.0
0.2.0 -> 0.3.0
```

Example minor updates:

- adding Clients module
- adding Projects module
- adding Vault module
- adding Payments module
- adding GitHub integration
- adding Settings screen
- adding local backup/export
- adding biometric unlock
- adding TestFlight pipeline

When increasing `y`, reset `z` to 0.

Example:

```txt
0.2.4 -> 0.3.0
```

---

### z = Patch Version

Increase `z` for small changes.

Use this when:

- fixing bugs
- improving UI details
- refactoring small parts
- changing text
- improving animations
- fixing layout issues
- cleaning code
- improving performance without major feature changes
- fixing CI/CD issues

Examples:

```txt
0.1.0 -> 0.1.1
0.1.1 -> 0.1.2
```

Example patch updates:

- fixing broken navigation
- fixing iPhone layout overflow
- fixing Flutter analyzer warnings
- fixing build number issue
- fixing GitHub Actions workflow
- improving card spacing
- cleaning unused imports
- fixing TestFlight upload error

---

# 4. Flutter Version Update Rules

Whenever a new version is completed, update version numbers in all relevant files.

Common Flutter files may include:

```txt
pubspec.yaml
CHANGELOG.md
README.md
ios/Runner.xcodeproj/project.pbxproj
android/app/build.gradle
```

Primary version source:

```txt
pubspec.yaml
```

Flutter version format:

```yaml
version: 0.2.0+3
```

Meaning:

```txt
0.2.0 = user-facing app version
3 = build number
```

Rules:

- The semantic version should follow `x.y.z`.
- The build number after `+` must increase for every TestFlight/App Store build.
- iOS build number must increase for every upload.
- Android versionCode must increase for every Play Store build.
- Do not decrease build numbers.

Example:

```yaml
version: 0.3.0+7
```

---

# 5. Commit Message Style

Use conventional commits.

Commit format:

```txt
type(scope): short description
```

Examples:

```txt
feat(auth): add biometric unlock
feat(vault): add encrypted vault item model
fix(ios): resolve TestFlight signing issue
docs(readme): add Flutter setup instructions
chore(deps): update Flutter packages
ci(github): add iOS release workflow
```

---

# 6. Allowed Commit Types

Use these commit types:

## feat

For new features.

Examples:

```txt
feat(clients): add client list screen
feat(projects): add project detail screen
feat(vault): add encrypted secret reveal flow
feat(payments): add payment status tracking
```

---

## fix

For bug fixes.

Examples:

```txt
fix(router): prevent redirect loop on startup
fix(vault): clear clipboard after copying secret
fix(ui): fix overflow on small iPhones
fix(ios): correct bundle identifier
```

---

## docs

For documentation changes.

Examples:

```txt
docs(readme): add setup instructions
docs(changelog): add version 0.2.0 notes
docs(security): document vault encryption model
```

---

## chore

For maintenance tasks.

Examples:

```txt
chore(deps): install riverpod and go_router
chore(config): update bundle identifier
chore(project): organize Flutter folders
```

---

## refactor

For code changes that do not change behavior.

Examples:

```txt
refactor(core): split app services
refactor(vault): move crypto logic into service layer
```

---

## style

For formatting or visual code style changes that do not affect logic.

Examples:

```txt
style(theme): adjust Material 3 colors
style(ui): clean dashboard card spacing
```

---

## perf

For performance improvements.

Examples:

```txt
perf(db): reduce unnecessary rebuilds
perf(vault): avoid bulk decrypting vault items
```

---

## test

For test-related changes.

Examples:

```txt
test(vault): add encryption service tests
test(router): add navigation guard tests
```

---

## build

For build system changes.

Examples:

```txt
build(ios): configure app signing
build(android): configure release bundle
build(flutter): update pubspec version
```

---

## ci

For CI/CD changes.

Examples:

```txt
ci(github): add Flutter analyze workflow
ci(github): add TestFlight release workflow
ci(match): add iOS signing bootstrap workflow
```

---

# 7. Branch Naming Rules

When creating a branch, use this format:

```txt
type/short-description
```

Examples:

```txt
feat/client-crud
feat/vault-module
fix/ios-signing
docs/update-readme
chore/flutter-setup
refactor/app-architecture
ci/testflight-release
```

Keep branch names lowercase.

Use hyphens instead of spaces.

---

# 8. Changelog Rules

Claude must maintain a file called:

```txt
CHANGELOG.md
```

The changelog must be updated for every version.

Use this format:

```md
# Changelog

## [0.2.0] - 2026-06-07

### Added
- Added client list screen.
- Added project detail screen.
- Added base Drift database schema.

### Changed
- Improved dashboard layout.
- Updated app routing structure.

### Fixed
- Fixed iOS build number issue.
```

---

# 9. Changelog Categories

Use these categories when relevant:

```txt
Added
Changed
Fixed
Removed
Deprecated
Security
Performance
Documentation
Internal
```

Only include categories that have content.

Do not add empty categories.

---

# 10. GitHub Push Rules

After each completed version:

```bash
git status
git add .
git commit -m "type(scope): message"
git push
```

If there are multiple logical changes, split them into multiple commits.

Example:

```bash
git add lib/features/clients lib/core/router
git commit -m "feat(clients): add client list and detail routes"

git add CHANGELOG.md pubspec.yaml
git commit -m "docs(release): add changelog for 0.2.0"

git push
```

Do not make one huge commit if the work contains unrelated changes.

---

# 11. When to Commit

Commit after a clean, working step.

Good commit points:

- Flutter scaffold completed
- navigation completed
- one screen completed
- one feature module completed
- database migration completed
- bug fixed
- changelog updated
- version bumped
- TestFlight config updated
- CI workflow fixed

Bad commit points:

- broken Dart analyzer
- app cannot start
- incomplete unfinished feature that breaks navigation
- temporary debugging code
- commented-out broken code
- secrets accidentally added to files

If a feature is partially done but the app still works, the commit message should make that clear.

Example:

```txt
feat(vault): add encrypted item model and placeholder UI
```

---

# 12. Development Workflow

For each task, Claude should follow this workflow:

1. Read the existing project structure.
2. Understand the requested change.
3. Make a short implementation plan.
4. Edit files.
5. Run checks where possible.
6. Fix errors.
7. Update documentation if needed.
8. Update changelog if the change is versioned.
9. Commit using conventional commits.
10. Push to GitHub.
11. Report what changed.

---

# 13. Checks Before Committing

Before committing, Claude should run available checks.

Use whichever scripts/files exist in the project.

Common Flutter commands:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

For code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

For iOS CI files or Fastlane:

```bash
cd ios
bundle exec fastlane lanes
```

Only run commands that make sense for the current environment.

If a command does not exist or cannot run, explain why.

If a check fails, fix it before committing.

---

# 14. Flutter Architecture Rules

Use a clean feature-first structure.

Recommended structure:

```txt
lib/
  main.dart
  app.dart

  core/
    config/
    constants/
    database/
    errors/
    router/
    security/
    services/
    theme/
    utils/

  features/
    dashboard/
      data/
      domain/
      presentation/
    clients/
      data/
      domain/
      presentation/
    projects/
      data/
      domain/
      presentation/
    payments/
      data/
      domain/
      presentation/
    vault/
      data/
      domain/
      presentation/
    github/
      data/
      domain/
      presentation/
    settings/
      data/
      domain/
      presentation/

  shared/
    widgets/
    models/
    providers/
```

Rules:

- Keep UI, data, and domain logic separated.
- Avoid giant files.
- Avoid business logic inside widgets.
- Use Riverpod providers for state and dependency injection.
- Use repositories/services for data access.
- Keep reusable widgets in `shared/widgets`.
- Keep app-wide constants in `core/constants`.
- Keep themes in `core/theme`.
- Keep routing in `core/router`.

---

# 15. State Management Rules

Use Riverpod.

Rules:

- Prefer `Notifier`, `AsyncNotifier`, or providers depending on complexity.
- Avoid global mutable variables.
- Keep provider names clear.
- Use `AsyncValue` for loading/error/data states.
- Do not hide errors silently.
- Avoid unnecessary rebuilds.
- Keep network/database logic outside widgets.

Example naming:

```txt
clientRepositoryProvider
clientListProvider
selectedClientProvider
vaultUnlockControllerProvider
```

---

# 16. Navigation Rules

Use `go_router`.

Rules:

- Keep route definitions centralized.
- Use named routes when possible.
- Protect locked vault routes.
- Avoid stringly-typed navigation spread across the app.
- Use bottom tabs for main sections.
- Use pushed detail routes for client/project/vault details.

Main tabs:

```txt
Dashboard
Projects
Clients
Vault
Settings
```

---

# 17. Database Rules

Use Drift / SQLite for local-first storage.

Rules:

- Store normal app data locally.
- Use migrations for schema changes.
- Never break old local data without migration.
- Keep database tables typed and documented.
- Avoid raw SQL unless necessary.
- Use repositories to access Drift DAOs/tables.
- Do not store secrets in plaintext.

Recommended entities:

```txt
Client
Project
Payment
VaultItem
Tag
VaultMeta
```

---

# 18. Security Rules

This project may store sensitive user data.

Claude must treat security as a core requirement.

Rules:

- Do not commit real secrets.
- Do not log vault secrets, tokens, passwords, or API keys.
- Do not store secret values in plaintext local storage.
- Use `flutter_secure_storage` for tokens and key material.
- Use vetted crypto libraries only.
- Do not invent custom cryptography.
- Use AES-GCM or other authenticated encryption if encryption code is implemented.
- Use random nonces correctly.
- Keep decrypted secrets in memory only as long as needed.
- Auto-clear clipboard after copied secrets.
- Add screenshot protection on vault screens where possible.
- Auto-lock vault on background or timeout.
- GitHub tokens must be stored securely.
- Environment values must come from GitHub Secrets or secure config, not committed files.

Never commit:

```txt
.env
.p8 files
.p12 files
.mobileprovision files
API keys
tokens
passwords
private signing certificates
```

---

# 19. iOS / TestFlight Rules

For iOS builds:

- Bundle ID in code must match App Store Connect.
- SKU does not need to match code.
- Build number must increase every upload.
- Use GitHub Actions macOS runners for iOS builds from Windows.
- Use Fastlane Match for signing assets.
- Keep signing repository private.
- Store App Store Connect API key as a GitHub Secret.
- Do not commit `.p8` keys.
- Do not commit signing certificates/profiles.
- Use release tags for expensive iOS builds.

Expected secrets:

```txt
APP_STORE_CONNECT_API_KEY
APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
APPLE_TEAM_ID
MATCH_GIT_URL
MATCH_PASSWORD
MATCH_GIT_BASIC_AUTHORIZATION
```

---

# 20. Android Rules

For Android builds:

- Keep package name stable once published.
- Increase versionCode for release builds.
- Do not commit keystore files.
- Store signing passwords in GitHub Secrets.
- Use `flutter build appbundle` for Play Store releases.

---

# 21. CI/CD Rules

Use GitHub Actions.

Recommended workflows:

```txt
.github/workflows/ci.yml
.github/workflows/bootstrap-ios-signing.yml
.github/workflows/release-ios.yml
.github/workflows/release-android.yml
```

CI workflow should usually run:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

iOS release workflow should run only on version tags:

```txt
v*
```

Example:

```bash
git tag v0.2.0
git push origin v0.2.0
```

---

# 22. Release Workflow

When preparing a version release:

1. Decide version bump:
   - major = big/product-breaking change
   - minor = new feature or system
   - patch = bug fix or small improvement

2. Update `pubspec.yaml`.

3. Update `CHANGELOG.md`.

4. Run checks.

5. Commit changes.

6. Tag the version.

7. Push commits.

8. Push tags.

Commands:

```bash
git tag v0.2.0
git push
git push origin v0.2.0
```

Tag format:

```txt
vX.Y.Z
```

Examples:

```txt
v0.1.0
v0.2.0
v1.0.0
```

---

# 23. Version Milestone Plan

Suggested MVP version plan:

## 0.1.0 — Project Foundation

Includes:

- Flutter project setup
- Material 3 theme
- folder structure
- bottom tab shell
- go_router setup
- Riverpod setup
- base shared widgets
- README and changelog

---

## 0.2.0 — Local Database Foundation

Includes:

- Drift setup
- SQLite setup
- first migrations
- Client model
- Project model
- repository structure
- sample CRUD flow

---

## 0.3.0 — Clients and Projects

Includes:

- Clients list
- Client detail
- Create/edit client
- Projects list
- Project detail
- Create/edit project
- Link projects to clients

---

## 0.4.0 — Payments

Includes:

- Payment model
- Create/edit payment
- Payment statuses
- Project payment rollups
- Dashboard totals

---

## 0.5.0 — Vault Foundation

Includes:

- Master password setup
- Vault lock screen
- encrypted VaultItem model
- crypto service
- reveal/copy secret flow
- clipboard auto-clear

---

## 0.6.0 — Biometrics and Security Polish

Includes:

- Face ID / Touch ID / fingerprint unlock
- auto-lock
- screenshot protection
- secure storage integration
- change master password flow

---

## 0.7.0 — GitHub Integration

Includes:

- GitHub OAuth
- secure token storage
- repo browser
- link repo to project
- project repo status card

---

## 0.8.0 — Backup, Settings, and Polish

Includes:

- encrypted export/import
- settings screen
- lock timeout setting
- theme polish
- animations
- haptics
- empty/loading/error states

---

## 0.9.0 — TestFlight Candidate

Includes:

- app icon
- splash screen
- iOS signing
- GitHub Actions release workflow
- TestFlight upload
- privacy-safe settings
- legal/support links
- no broken debug UI

---

## 1.0.0 — MVP App Store Candidate

Includes:

- stable MVP
- all critical modules working
- clean UI
- critical bugs fixed
- ready for external testing
- ready for App Store preparation

---

# 24. Pull Request Rules

If working with pull requests, use this PR format:

```md
## Summary

Briefly explain what changed.

## Version

Example: 0.3.0

## Changes

- Added ...
- Changed ...
- Fixed ...

## Testing

- Ran `flutter analyze`
- Ran `flutter test`
- Tested navigation manually

## Screenshots / Videos

Attach if UI changed.

## Notes

Mention anything important for review.
```

---

# 25. README Requirements

The repository should include a clear `README.md`.

README should contain:

- project name
- short description
- tech stack
- setup instructions
- run instructions
- folder structure summary
- versioning rules
- development workflow
- TestFlight notes
- security notes

---

# 26. Documentation Rules

Keep documentation inside:

```txt
docs/
```

Recommended files:

```txt
docs/clientvault-prd-mvp.md
docs/flutter-architecture.md
docs/security-model.md
docs/database-schema.md
docs/versioning.md
docs/release-checklist.md
docs/app-store-prep.md
docs/testflight-pipeline.md
```

When major systems are added, document them.

Examples:

- vault encryption system
- local database schema
- GitHub integration
- iOS signing pipeline
- backup/export system

---

# 27. Code Quality Rules

Claude must keep the code:

- readable
- typed
- modular
- scalable
- secure
- testable
- easy to debug

Avoid:

- huge files
- duplicated logic
- random magic numbers
- unclear names
- dead code
- commented-out broken code
- unnecessary dependencies
- business logic inside widgets

Use constants for important values.

Use typed models for app data.

Prefer small, focused widgets.

---

# 28. Local Data Safety

Because this app may store important work and vault data, local data must be handled carefully.

Rules:

- never break old database data without migration
- include database schema versioning
- add migration logic when schema changes
- do not delete user data unless user chooses delete data
- keep encrypted backups compatible where possible
- document breaking changes clearly

---

# 29. App Store Safety Rules

Before preparing TestFlight or App Store builds:

- remove unfinished debug UI
- avoid unused permissions
- avoid private APIs
- add privacy policy link
- add support contact
- add terms/legal links if needed
- make sure the app does not crash
- make sure buttons work
- make sure placeholder features are not misleading
- complete export compliance honestly
- increase iOS build number before upload

---

# 30. What Claude Should Report After Each Version

After finishing a version, Claude should report:

```md
## Version Completed: x.y.z

### Summary
Short summary of what was added or fixed.

### Commits
- commit hash/message if available

### Changelog
Mention that CHANGELOG.md was updated.

### Tests
Mention what checks were run.

### GitHub
Mention whether changes were pushed.

### Next Recommended Version
Suggest the next logical version.
```

---

# 31. Important Final Instruction

Claude should behave like a senior Flutter engineer, not just a code generator.

For every update:

- think about maintainability
- protect the project from messy code
- protect user data
- keep versions clean
- update changelog
- commit properly
- push to GitHub
- explain clearly what changed

The goal is to build a real Flutter mobile app that can eventually be launched on TestFlight, the App Store, and Google Play.