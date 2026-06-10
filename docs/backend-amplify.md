# Backend — AWS Amplify Gen 2

The chosen backend stack (blueprint Option A). One platform for auth + API + data
+ storage + push. **Not yet provisioned** — this is the design the Auth phase
builds against.

## Services

| Concern | Service |
|---------|---------|
| Auth | **Cognito** (federated: Sign in with Apple, Google) |
| API | **AppSync (GraphQL)** preferred, or API Gateway + Lambda (REST) |
| Database | **DynamoDB** (single-table or per-entity), Aurora Serverless v2 only if relational needs emerge |
| File storage | **S3** (encrypted attachments) |
| Push | **SNS / Pinpoint** relay for APNs device tokens |
| Entitlements | App Store Server Notifications → webhook (Lambda) → entitlement record |

## Auth flow

1. iOS gets an Apple identity token / Google ID token.
2. The token is exchanged with Cognito (federation), or sent to a Lambda that
   validates it and provisions/looks up the user.
3. App receives Cognito tokens: **access token kept in memory**, **refresh token
   in Keychain** (`TokenStore`). `URLSessionAPIClient` attaches the bearer and
   refreshes once on 401.
4. Account deletion (`DELETE /account`, an Apple requirement) removes the user and
   their data.

## Data ownership & isolation

- Every row is scoped by `userId` and isolated at the **authorization-rule** level
  (Amplify Data `allow.owner()` / IAM), not just in app code — no cross-user leaks.
- Entities (mirror the domain models): `users`, `clients`, `projects` (FK
  `clientId`), `payments` (FK `projectId`), `vault_config` (FK `userId`),
  `vault_items` (FK `userId`, optional `clientId`/`projectId`), `attachments`.
- Common fields: `id` (UUID, client-minted), `createdAt`, `updatedAt`, `deletedAt`
  (soft delete for safe sync).

## Vault storage (zero-knowledge)

The backend stores, per user:
- **vault_config**: KDF params, salt, `wrappedDEK` (`EncryptedPayload`), cipher
  version, timestamps.
- **vault_items**: metadata (title, type, tags, links) **+ `encryptedBody`
  ciphertext**. The server cannot decrypt either. See
  [`security-model.md`](security-model.md).

## Endpoints (conceptual)

```
POST   /auth/apple | /auth/google | /auth/refresh | /auth/logout
DELETE /account
GET/POST/PATCH/DELETE  /clients | /projects | /payments
GET/PUT                /vault/config
GET/POST/PATCH/DELETE  /vault/items        # ciphertext payloads only
POST                   /devices            # register APNs token
```

With AppSync these become GraphQL queries/mutations; the `Endpoint`/`APIClient`
abstraction in the app stays the same regardless.

## Sync semantics

- Per-entity `updatedAt` drives conflict resolution.
- Vault items: **last-write-wins**. Clients/projects/payments may use last-write-
  wins now, field-level merge later.

## Config & secrets

- The app reads `API_BASE_URL` from `Info.plist` (per build configuration) with a
  placeholder default in `AppConfig`. Point each stage (dev/prod) at its own URL.
- Generated backend config (`amplify_outputs.json` / `amplifyconfiguration.json`)
  is **git-ignored** and provisioned via CI — never committed.
- Backend secrets live in AWS / GitHub Secrets, not in source.

## Rate limiting (security)

Apply server-side rate limits on auth, `vault/config` fetch, and sync endpoints to
back up the client's local exponential backoff against brute force.
