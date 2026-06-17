import Foundation
import CryptoKit
import Observation

enum VaultError: Error, LocalizedError {
    case notConfigured
    case notUnlocked
    case biometricsNotEnrolled
    case invalidDEK

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Vault is not set up yet."
        case .notUnlocked: return "Vault is locked. Please unlock first."
        case .biometricsNotEnrolled: return "Biometric unlock is not enabled."
        case .invalidDEK: return "Stored biometric key is invalid."
        }
    }
}

@MainActor
@Observable
final class VaultViewModel {
    enum ViewState: Equatable {
        case setup    // no VaultConfig stored — first launch
        case locked   // config exists, DEK not in memory
        case unlocked // config exists, DEK in memory, items loaded
    }

    private(set) var viewState: ViewState = .locked
    private(set) var items: [VaultItem] = []
    private(set) var biometricUnlockEnabled: Bool = false
    var isBusy = false
    var errorMessage: String?

    /// DEK lives in memory only; CryptoKit zeroes its backing on dealloc.
    /// Never copied to Data for storage or logging.
    private var dek: SymmetricKey?
    private var config: VaultConfig?

    private let crypto: CryptoService
    private let keychain: KeychainStoring
    private let repo: VaultRepositing
    private let session: SessionStore

    private static let configKey        = "vault.config.v1"
    private static let biometricDEKKey  = "vault.dek.biometric.v1"
    private static let biometricMarker  = "vault.biometric.enrolled"

    init(
        crypto: CryptoService,
        keychain: KeychainStoring,
        repo: VaultRepositing,
        session: SessionStore
    ) {
        self.crypto = crypto
        self.keychain = keychain
        self.repo = repo
        self.session = session
        loadStoredConfig()
    }

    // MARK: - Config persistence

    private func loadStoredConfig() {
        guard
            let data = try? keychain.get(Self.configKey),
            let data,
            let decoded = try? JSONDecoder.clientVault.decode(VaultConfig.self, from: data)
        else {
            viewState = .setup
            return
        }
        config = decoded
        viewState = .locked
        biometricUnlockEnabled = ((try? keychain.get(Self.biometricMarker)) ?? nil) != nil
    }

    // MARK: - First-time setup

    func setupVault(password: String) async throws {
        isBusy = true
        defer { isBusy = false }
        // Both KDF calls run off the main thread — Argon2id is CPU-intensive.
        let (newConfig, derivedDEK) = try await Task.detached(priority: .userInitiated) { [password] in
            let manager = VaultKeyManager(crypto: AESGCMCrypto())
            let cfg = try manager.bootstrap(password: password)
            let key = try manager.unlock(password: password, config: cfg)
            return (cfg, key)
        }.value
        let data = try JSONEncoder.clientVault.encode(newConfig)
        try keychain.set(data, for: Self.configKey)
        config = newConfig
        dek = derivedDEK
        items = []
        viewState = .unlocked
        session.vaultUnlocked()
    }

    // MARK: - Password unlock

    func unlock(password: String) async throws {
        guard let config else { throw VaultError.notConfigured }
        isBusy = true
        defer { isBusy = false }
        let capturedConfig = config
        let derivedDEK = try await Task.detached(priority: .userInitiated) { [password, capturedConfig] in
            try VaultKeyManager(crypto: AESGCMCrypto()).unlock(password: password, config: capturedConfig)
        }.value
        dek = derivedDEK
        viewState = .unlocked
        session.vaultUnlocked()
        try await loadItems()
    }

    // MARK: - Biometric unlock

    func unlockWithBiometrics() async throws {
        guard biometricUnlockEnabled else { throw VaultError.biometricsNotEnrolled }
        // Move the SecItemCopyMatching call — which blocks until the Face ID / Touch ID
        // prompt resolves — off the main actor so the UI stays responsive.
        let keychainRef = keychain
        let dekKey = Self.biometricDEKKey
        let dekData = try await Task.detached(priority: .userInitiated) {
            try keychainRef.get(dekKey)
        }.value
        guard let dekData, dekData.count == 32 else { throw VaultError.invalidDEK }
        dek = SymmetricKey(data: dekData)
        viewState = .unlocked
        session.vaultUnlocked()
        try await loadItems()
    }

    // MARK: - Lock

    /// Zeroes the DEK from memory and locks the vault. Called on background
    /// transition and from the lock button. Safe to call when already locked.
    func lock() {
        dek = nil
        items = []
        viewState = config != nil ? .locked : .setup
        session.lockVault()
    }

    // MARK: - Biometric enrollment

    func enableBiometricUnlock() throws {
        guard let dek else { throw VaultError.notUnlocked }
        let raw = dek.withUnsafeBytes { Data($0) }
        try keychain.setBiometricProtected(raw, for: Self.biometricDEKKey)
        try keychain.set(Data([1]), for: Self.biometricMarker)
        biometricUnlockEnabled = true
    }

    func disableBiometricUnlock() throws {
        try keychain.remove(Self.biometricDEKKey)
        try keychain.remove(Self.biometricMarker)
        biometricUnlockEnabled = false
    }

    // MARK: - Item CRUD

    func loadItems() async throws {
        items = try await repo.fetchItems()
    }

    func addItem(title: String, type: VaultItemType, body: VaultItemBody) async throws {
        guard let dek else { throw VaultError.notUnlocked }
        let bodyData = try JSONEncoder.clientVault.encode(body)
        let encrypted = try crypto.seal(bodyData, using: dek)
        let item = VaultItem(
            id: UUID(),
            title: title,
            type: type,
            tags: [],
            clientId: nil,
            projectId: nil,
            encryptedBody: encrypted,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await repo.save(item)
        try await loadItems()
    }

    func updateItem(_ item: VaultItem, title: String, body: VaultItemBody) async throws {
        guard let dek else { throw VaultError.notUnlocked }
        let bodyData = try JSONEncoder.clientVault.encode(body)
        let encrypted = try crypto.seal(bodyData, using: dek)
        var updated = item
        updated.title = title
        updated.encryptedBody = encrypted
        updated.updatedAt = Date()
        try await repo.save(updated)
        try await loadItems()
    }

    func deleteItem(_ item: VaultItem) async throws {
        try await repo.delete(id: item.id)
        try await loadItems()
    }

    /// Decrypts and returns the plaintext body of a vault item. The caller must
    /// display this only within a locked-on-background context (VaultItemRevealSheet).
    func decryptBody(of item: VaultItem) throws -> VaultItemBody {
        guard let dek else { throw VaultError.notUnlocked }
        let bodyData = try crypto.open(item.encryptedBody, using: dek)
        return try JSONDecoder.clientVault.decode(VaultItemBody.self, from: bodyData)
    }
}
