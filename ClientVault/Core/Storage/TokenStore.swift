import Foundation

/// Supplies bearer tokens to the API client and refreshes them on demand.
protocol TokenProviding: Sendable {
    func currentAccessToken() async -> String?
    /// Attempts to obtain a fresh access token. Returns true on success.
    func refresh() async throws -> Bool
}

/// Lets the session persist/clear credentials.
protocol TokenStoring: Sendable {
    func save(access: String, refresh: String)
    func clear()
    var hasSession: Bool { get }
}

/// Holds the short-lived access token in memory and the refresh token in the
/// Keychain, per the auth blueprint. The refresh round-trip is a seam until the
/// backend auth endpoints exist.
final class TokenStore: TokenProviding, TokenStoring, @unchecked Sendable {
    private let keychain: KeychainStoring
    private let refreshKey = "auth.refreshToken"
    private let lock = NSLock()
    private var accessToken: String?

    init(keychain: KeychainStoring) {
        self.keychain = keychain
    }

    var hasSession: Bool {
        if let data = try? keychain.get(refreshKey), data != nil { return true }
        return false
    }

    func save(access: String, refresh: String) {
        lock.lock(); accessToken = access; lock.unlock()
        try? keychain.set(Data(refresh.utf8), for: refreshKey)
    }

    func clear() {
        lock.lock(); accessToken = nil; lock.unlock()
        try? keychain.remove(refreshKey)
    }

    func currentAccessToken() async -> String? {
        lock.lock(); defer { lock.unlock() }
        return accessToken
    }

    func refresh() async throws -> Bool {
        // TODO(auth): POST /auth/refresh with the stored refresh token, store the
        // new access token, return true. Until the backend exists, no refresh.
        return false
    }
}
