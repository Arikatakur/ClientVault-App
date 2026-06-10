# Security Model — Zero-Knowledge Vault

The server must never see a plaintext vault secret or the key that decrypts it.
This document describes the crypto, what's implemented today, and what's pending.

## Data classification

| Data | On server |
|------|-----------|
| Account id, profile basics | plaintext (minimized) |
| Client/project/payment names | plaintext if the user accepts (encrypt if feasible) |
| Vault item **metadata** (title, type, tags, client/project links) | plaintext |
| Vault item **secret body** (password, API key, note, card) | **ciphertext only** |

## Key hierarchy

```
vault password ──Argon2id(salt, params)──▶  Master Key (MK)
MK ──HKDF-SHA256("clientvault.kek.v1")──▶   Key-Encryption-Key (KEK)
DEK  = random 256-bit data-encryption key (per user)
wrappedDEK = AES-GCM(DEK) under KEK            ← stored server-side
item.body  = AES-GCM(secret) under DEK         ← stored server-side (ciphertext)
```

- The server stores `wrappedDEK`, KDF params + salt (the **vault config**), and per
  item the `EncryptedPayload` (nonce + ciphertext + tag + version). None of it is
  usable without the password.
- A fresh random nonce is generated per seal (CryptoKit default). **Never** reuse a
  nonce with the same key.
- Domain separation: the raw MK is never used directly as an encryption key; the
  KEK is derived from it via HKDF.

## What's implemented (v0.18.0)

- `Core/Crypto/AESGCMCrypto.swift` — real AES-256-GCM seal/open + key wrap/unwrap
  (CryptoKit). Tested: round-trip, wrong-key & tamper rejection, nonce uniqueness,
  version guard, JSON round-trip.
- `Core/Crypto/EncryptedPayload.swift` — the on-the-wire ciphertext form.
- `Core/Crypto/VaultKeyManager.swift` — the key-hierarchy orchestration
  (bootstrap/unlock, KEK derivation, random salt).
- `Core/Storage/KeychainStore.swift` — Keychain wrapper (`ThisDeviceOnly`) incl. a
  `biometryCurrentSet`-protected variant for the biometric-unlock seam.

## What's pending (Vault phase)

- **Argon2id KDF.** Argon2 is *not* in CryptoKit. `Argon2idKeyDerivation` currently
  **throws `CryptoError.notImplemented`** on purpose — so no build can ship password
  hashing that silently falls back to something weaker. The Vault phase integrates a
  vetted dependency (e.g. **swift-sodium / libsodium**) and implements `deriveKey`.
  Default params (`KDFParameters.default`): 64 MiB memory, 3 iterations, parallelism
  1, 16-byte salt — meeting OWASP Argon2id guidance, and raisable over time while
  staying backward compatible (params are stored with the vault config).
- Biometric DEK unlock wiring; reveal-sheet UX with blur-to-clear; clipboard
  auto-clear; server-side rate limits on auth / vault-config / sync endpoints.

## Threat-model checklist

- [x] Vault secrets encrypted on-device before any upload (AES-GCM).
- [x] Server stores ciphertext + wrapped DEK only — never MK or plaintext.
- [x] Key material / tokens in Keychain (`ThisDeviceOnly`), never `UserDefaults`.
- [x] Access token in memory; refresh token in Keychain.
- [x] App-switcher snapshot protection (privacy shield) + auto-lock on background.
- [ ] Argon2id KDF (pending vetted dependency).
- [ ] Clipboard auto-clear after copying a secret.
- [ ] Local exponential backoff + server-side rate limits on sensitive endpoints.
- [ ] Certificate pinning (optional).
- [x] No secrets in logs/analytics (enforced by code review; never `print` secrets).

## Export compliance

The app uses only standard Apple cryptography (CryptoKit AES-GCM) to protect the
user's own data, which qualifies for the encryption-export exemption.
`ITSAppUsesNonExemptEncryption` is `false` in `Info.plist`. Revisit if non-standard
crypto is ever introduced.
