import Foundation
import Observation

@MainActor @Observable
final class GitHubStore {
    private(set) var connectedProfile: GitHubProfile?
    private(set) var isConnecting = false
    private(set) var connectError: String?

    private let service: GitHubServicing
    private let keychain: KeychainStoring
    private let clientID: String?
    private let hasBackend: Bool

    // Held alive for the duration of the OAuth session.
    private var activeCoordinator: GitHubOAuthCoordinator?

    private static let loginKey = "github.profile.login"
    private static let nameKey  = "github.profile.name"

    init(service: GitHubServicing, keychain: KeychainStoring, clientID: String?, hasBackend: Bool) {
        self.service = service
        self.keychain = keychain
        self.clientID = clientID
        self.hasBackend = hasBackend
        loadSavedProfile()
    }

    func connect() async {
        guard !isConnecting else { return }
        isConnecting = true
        connectError = nil
        defer { isConnecting = false; activeCoordinator = nil }

        do {
            let profile = hasBackend ? try await connectLive() : try await connectDev()
            try saveProfile(profile)
            connectedProfile = profile
        } catch {
            connectError = error.localizedDescription
        }
    }

    func disconnect() {
        try? keychain.remove(Self.loginKey)
        try? keychain.remove(Self.nameKey)
        connectedProfile = nil
        connectError = nil
    }

    // MARK: - Private

    private func connectDev() async throws -> GitHubProfile {
        try await service.exchangeCode("dev-mock-code")
    }

    private func connectLive() async throws -> GitHubProfile {
        guard let clientID else { throw GitHubError.missingClientID }
        let oauthURL = buildOAuthURL(clientID: clientID)
        let coordinator = GitHubOAuthCoordinator()
        activeCoordinator = coordinator
        let callbackURL = try await coordinator.authenticate(url: oauthURL, callbackScheme: "clientvault")
        guard let code = extractCode(from: callbackURL) else {
            throw GitHubError.missingOAuthCode
        }
        return try await service.exchangeCode(code)
    }

    private func buildOAuthURL(clientID: String) -> URL {
        var components = URLComponents(string: "https://github.com/login/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "scope", value: "user:email"),
        ]
        return components.url!
    }

    private func extractCode(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
    }

    private func saveProfile(_ profile: GitHubProfile) throws {
        try keychain.set(Data(profile.login.utf8), for: Self.loginKey)
        if let name = profile.name {
            try keychain.set(Data(name.utf8), for: Self.nameKey)
        }
    }

    private func loadSavedProfile() {
        guard
            let loginData = try? keychain.get(Self.loginKey),
            !loginData.isEmpty
        else { return }
        let login = String(decoding: loginData, as: UTF8.self)
        let name = (try? keychain.get(Self.nameKey)).map { String(decoding: $0, as: UTF8.self) }
        connectedProfile = GitHubProfile(login: login, name: name, avatarURL: nil)
    }
}
