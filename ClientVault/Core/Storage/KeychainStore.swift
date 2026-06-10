import Foundation
import Security

/// Abstraction over secure storage. Secrets (tokens, wrapped keys) live here —
/// never in `UserDefaults`.
protocol KeychainStoring: Sendable {
    func set(_ data: Data, for key: String) throws
    func get(_ key: String) throws -> Data?
    func remove(_ key: String) throws

    /// Stores data behind a biometric gate that invalidates if the enrolled
    /// biometrics change (`biometryCurrentSet`). Used for the optional vault
    /// biometric unlock.
    func setBiometricProtected(_ data: Data, for key: String) throws
}

enum KeychainError: Error, Equatable {
    case unexpectedStatus(OSStatus)
    case accessControlCreationFailed
}

/// `kSecClassGenericPassword`-backed Keychain wrapper, scoped by service.
/// Items are `ThisDeviceOnly` so they never sync to iCloud Keychain or migrate
/// in an unencrypted backup.
final class KeychainStore: KeychainStoring {
    private let service: String

    init(service: String) {
        self.service = service
    }

    func set(_ data: Data, for key: String) throws {
        try remove(key)
        var query = baseQuery(for: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }

    func get(_ key: String) throws -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess: return item as? Data
        case errSecItemNotFound: return nil
        default: throw KeychainError.unexpectedStatus(status)
        }
    }

    func remove(_ key: String) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func setBiometricProtected(_ data: Data, for key: String) throws {
        try remove(key)
        var error: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            &error
        ) else {
            throw KeychainError.accessControlCreationFailed
        }
        var query = baseQuery(for: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessControl as String] = access
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}
