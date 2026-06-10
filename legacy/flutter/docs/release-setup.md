# Release setup — ClientVault iOS → TestFlight

This pipeline builds, signs, and ships the iOS app to **TestFlight from GitHub Actions — no Mac required**.
Signing uses **fastlane match** (your cert + provisioning profile stored encrypted in a private repo) and an
**App Store Connect API key**.

| Workflow | File | Runs |
|----------|------|------|
| CI | `.github/workflows/ci.yml` | analyze · test · debug Android build — every push/PR (Linux) |
| iOS release | `.github/workflows/release-ios.yml` | build · sign · upload to TestFlight — on a `v*` tag (macOS) |
| Signing bootstrap | `.github/workflows/ios-bootstrap-signing.yml` | once, manually — generates & stores signing assets |

---

## One-time setup

### 1. Register the App ID
Apple Developer → **Certificates, Identifiers & Profiles → Identifiers → + → App IDs → App** (Explicit).
- **Bundle ID:** `org.clientvault.app`
- **Capabilities:** none — leave everything unchecked. (If *Data Protection* is preselected, leave it on; it's ideal for a vault.)

### 2. Create the App Store Connect app record
App Store Connect → **My Apps → + → New App**.
- Platform **iOS** · Bundle ID `org.clientvault.app` · Name **ClientVault** · SKU `clientvault` · choose a primary language.
- (TestFlight uploads require this record to already exist.)

### 3. App Store Connect API key
App Store Connect → **Users and Access → Integrations → App Store Connect API → Team Keys → +**.
- Access role: **App Manager**. Download `AuthKey_XXXXXX.p8` (**one-time download**). Note the **Key ID** and **Issuer ID**.

### 4. Private certs repo (for match)
Create an **empty private** GitHub repo, e.g. `clientvault-certs` — match stores your encrypted distribution cert +
provisioning profile there. Create a **Personal Access Token** with access to that repo (classic: `repo` scope, or a
fine-grained token scoped to the repo).

### 5. Team ID
Apple Developer → **Membership** → copy your 10-character **Team ID**.

### 6. GitHub secrets
Repo → **Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Value |
|--------|-------|
| `APP_STORE_CONNECT_KEY_ID` | Key ID from step 3 |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from step 3 |
| `APP_STORE_CONNECT_API_KEY_BASE64` | base64 of the `.p8` (command below) |
| `APPLE_TEAM_ID` | Team ID from step 5 |
| `MATCH_GIT_URL` | `https://github.com/<you>/clientvault-certs.git` |
| `MATCH_GIT_BASIC_AUTHORIZATION` | base64 of `username:PAT` (command below) |
| `MATCH_PASSWORD` | a strong passphrase that encrypts the match repo |

Generate the base64 values in **PowerShell**:
```powershell
# API key -> APP_STORE_CONNECT_API_KEY_BASE64
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\AuthKey_XXXXXX.p8"))

# Git basic auth -> MATCH_GIT_BASIC_AUTHORIZATION  (your GitHub username + the PAT)
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("YOUR_GH_USERNAME:YOUR_PAT"))
```

### 7. Seed signing (run once)
GitHub → **Actions → "Bootstrap iOS signing" → Run workflow**. This creates your distribution certificate + App Store
provisioning profile and commits them, encrypted, to the certs repo. Re-run only if they change or expire.

---

## Cutting a release
```powershell
# 1. bump version in pubspec.yaml (e.g. 0.1.1 -> 0.1.2), update CHANGELOG.md, commit
# 2. tag and push:
git tag v0.1.2
git push origin v0.1.2
```
The release workflow builds a signed IPA (build number = the Actions run number, so every upload is unique) and uploads
to TestFlight. Processing on TestFlight takes a few minutes; then add yourself as a tester.

---

## Notes
- iOS builds run **only on `v*` tags** to keep macOS minutes low (see plan §10 cost notes). Everyday pushes hit the cheap Linux CI.
- This config follows Flutter's official *Continuous Delivery with fastlane* flow. As the plan warns, the **first** iOS
  pipeline run can surface a signing/config nit to tweak — that's expected; iterate on the run logs.
- `.p8`, `.p12`, and `.mobileprovision` files are git-ignored and must **never** be committed.
