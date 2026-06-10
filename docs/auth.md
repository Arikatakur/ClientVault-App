# Authentication

Phase 2 of the rewrite. Sign in with Apple + Google on the client, with the backend
token exchange as a seam until AWS Amplify (Cognito) is provisioned.

## Flow

```
Apple/Google sign-in ──▶ ProviderCredential ──▶ AuthService.completeSignIn
                                                      │
                              config.hasBackend ?  POST /auth/{provider}
                                   true ──────────▶  validate token, return app tokens + user
                                   false ─────────▶  dev fallback: trust the verified identity locally
                                                      │
                                                      ▼
                              TokenStore.save(access in memory, refresh in Keychain)
                                              SessionStore.completeSignIn(user)
```

- **Apple** (`AuthenticationServices`): the official `SignInWithAppleButton`. The
  request carries `SHA256(nonce)`; the raw nonce is kept to send to the backend for
  replay protection. The `ASAuthorization` result is parsed **synchronously** into a
  `Sendable` `ProviderCredential` (`AuthService.makeAppleCredential`) so the
  non-`Sendable` Apple object never crosses an actor boundary.
- **Google** (`GoogleSignIn` SPM package): `GIDSignIn.signIn(withPresenting:)` from
  the top view controller. All Google code is wrapped in `#if canImport(GoogleSignIn)`
  so the app still builds if the package isn't resolved.

## Session lifecycle

- `SessionStore` starts `.unauthenticated`. On launch, `AuthService.restore()` checks
  for a stored session: with a backend it refreshes the token; in dev it trusts the
  stored refresh token.
- Access token lives in memory (`TokenStore`); refresh token in the Keychain
  (`ThisDeviceOnly`).
- Sign-out and account deletion clear both and route back to the sign-in screen.
- Account deletion (`DELETE /account`) is required by App Review for apps that create
  accounts; Settings has a confirmation dialog for it.

## Configuration needed before this works for real

1. **Apple**: enable the *Sign in with Apple* capability (already in
   `ClientVault.entitlements`) on the App ID; set the team/bundle id at signing.
2. **Google**: create an iOS OAuth client in the Google Cloud console, then replace
   the `GIDClientID` and the reversed-client-id URL scheme placeholders in
   `Info.plist`. `AppConfig` treats a `PLACEHOLDER` value as "not configured".
3. **Backend**: provision Amplify (see `backend-amplify.md`), implement
   `/auth/apple`, `/auth/google`, `/auth/refresh`, and `DELETE /account` to validate
   the provider token and issue app tokens, then flip `AppConfig.hasBackend` to true.

Until step 3, the **dev fallback** signs the user in locally so the rest of the app
is reachable during development.

## Tested

`ClientVaultTests/AuthTests.swift` covers the nonce (length, uniqueness, a known
SHA-256 vector), the dev-fallback and backend exchange paths (with a fake API client
and token store), API-error wrapping, session restore, and sign-out clearing. The
provider UI flows (Apple/Google sheets) are integration-only.
