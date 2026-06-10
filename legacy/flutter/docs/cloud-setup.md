# ClientVault Cloud — provisioning & wire-up guide

The app ships with the full client side of accounts, plans/subscriptions, and
push groundwork (v0.12.0–v0.14.0), all running in **local mode** behind
repository interfaces. This guide lists the external services to provision and
exactly where each one plugs in. Source of truth for the architecture: the
Notion pages *Mobile App — Project Hub* and *Cloud + Subscriptions — Plan*.

Scope note: **iOS-only for now** (decided 2026-06-10) — skip the Android
columns of every console until an Android release is planned.

---

## 1. AWS backend (Amplify Gen 2)

What it gives: Cognito auth, AppSync/DynamoDB (or Aurora) data, S3 attachments.

1. Create/choose the AWS account; install the Amplify Gen 2 tooling
   (`npm create amplify@latest` in a new `backend/` folder or separate repo).
2. Define auth: email/password + **Sign in with Apple** + **Google** as
   identity providers, MFA optional.
3. Deploy (`npx ampx sandbox` to start, pipeline deploy for prod) and add the
   generated `amplify_outputs.json` to the Flutter app (do **not** commit
   secrets; the outputs file is client-safe by design).
4. Flutter wiring:
   - `flutter pub add amplify_flutter amplify_auth_cognito`
   - Implement `CognitoAuthRepository implements AuthRepository`
     (`lib/features/account/auth_repository.dart` is the contract).
   - Rebind `authRepositoryProvider` in
     `lib/features/account/account_controller.dart`.
   - Migrate the local account: on first cloud sign-in, offer to attach the
     existing on-device data to the new identity.

Cost: Cognito free tier is 10k MAU (social sign-ins count as regular MAUs).

## 2. Sign in with Apple

1. Apple Developer portal → the `org.clientvault.app` App ID → enable the
   **Sign in with Apple** capability.
2. Create a **Services ID** (for Cognito's redirect) + key for the Apple IdP;
   add both to the Cognito identity provider config.
3. Regenerate provisioning profiles afterwards: run the existing
   `bootstrap-ios-signing` workflow (fastlane match) so CI profiles pick up
   the capability, and add `com.apple.developer.applesignin` to
   `ios/Runner/Runner.entitlements`.
4. App side: `flutter pub add sign_in_with_apple` (or use Amplify's built-in
   `signInWithWebUI(provider: AuthProvider.apple)`) and implement
   `signInWithApple()` in the Cognito repository.

Free — covered by the existing Apple Developer membership.

## 3. Google sign-in

1. Google Cloud console → OAuth consent screen → create an **iOS OAuth
   client ID** for `org.clientvault.app`.
2. Add Google as a Cognito identity provider (client ID + secret from a web
   client).
3. App side: Amplify `signInWithWebUI(provider: AuthProvider.google)` needs no
   extra package; native `google_sign_in` is optional polish later.

## 4. RevenueCat subscriptions (StoreKit 2)

1. App Store Connect → create the subscription group + two auto-renewing
   products (monthly, annual) once pricing is decided — the paywall
   deliberately shows "Pricing is announced at launch" until then
   (`PlanCatalog.pricingNote`).
2. RevenueCat → new project → add the iOS app (bundle id
   `org.clientvault.app`), upload the App Store Connect API key, define the
   **`pro` entitlement** mapped to both products.
3. App side:
   - `flutter pub add purchases_flutter`
   - Implement `RevenueCatBillingRepository implements BillingRepository`
     (`lib/features/billing/billing_repository.dart` is the contract:
     `currentEntitlement` / `purchase(term)` / `restore`).
   - Rebind `billingRepositoryProvider` in
     `lib/features/billing/entitlement_controller.dart`; the paywall and
     `ensurePro()` gates need no changes.
4. Server side (with the AWS backend): RevenueCat **webhook → Lambda** writes
   entitlement state next to the user record; cloud APIs check it
   server-side. The client gate is UX only.

RevenueCat is free until well past launch scale; the stores take 15–30%.

## 5. Push notifications

Local due-date reminders already work on-device. Remote push needs:

1. Apple Developer portal → **APNs key** (`.p8`) — store it as a GitHub/AWS
   secret, never in the repo.
2. Pick the relay: **Amazon SNS (or Pinpoint)** with the APNs key, fed by
   backend events (e.g. GitHub webhook → Lambda → SNS → device).
3. App side: implement `PushRegistrationService`
   (`lib/features/notifications/push_registration_service.dart`) — request
   permission (the local-notifications permission flow already exists),
   obtain the APNs token, register it with the backend per user/device, and
   rebind `pushRegistrationServiceProvider`. Tap-routing by payload already
   works (`NotificationService.onSelectNotification` → go_router path).
4. Replace the "Push notifications · Soon" tile in Settings with the real
   toggle.

## 6. Compliance (before public release)

- Privacy policy URL + App Store privacy nutrition labels (now collecting
  account data).
- GDPR posture: data export + delete-my-data paths (in-app account deletion
  shipped in v0.12.0; extend it to wipe server data when the backend exists).
- Encryption-at-rest on every store (S3 SSE, DynamoDB/Aurora encryption) —
  the vault additionally stays ciphertext-only end to end.

## Suggested order

1. AWS/Amplify + Cognito (unblocks everything)
2. Apple + Google IdPs into Cognito
3. Data sync (separate design doc — zero-knowledge vault rules in the plan)
4. RevenueCat + store products (needs pricing decision)
5. Push relay
6. Compliance pass
