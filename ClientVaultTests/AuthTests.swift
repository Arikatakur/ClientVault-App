import XCTest
@testable import ClientVault

final class NonceTests: XCTestCase {
    func testRandomNonceHasRequestedLengthAndIsUnique() {
        let a = Nonce.random(length: 32)
        let b = Nonce.random(length: 32)
        XCTAssertEqual(a.count, 32)
        XCTAssertNotEqual(a, b)
    }

    func testSHA256IsStableAndMatchesKnownVector() {
        let h1 = Nonce.sha256("abc")
        let h2 = Nonce.sha256("abc")
        XCTAssertEqual(h1, h2)
        XCTAssertEqual(h1.count, 64) // 32 bytes as hex
        XCTAssertEqual(h1, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}

final class AuthServiceTests: XCTestCase {
    private func makeService(
        hasBackend: Bool,
        api: FakeAPIClient = FakeAPIClient()
    ) -> (service: LiveAuthService, tokens: FakeTokenStore, session: SessionStore) {
        let tokenStore = FakeTokenStore()
        let session = SessionStore(tokenStore: tokenStore)
        let config = AppConfig(
            environment: .development,
            apiBaseURL: URL(string: "https://example.test")!,
            keychainService: "test",
            hasBackend: hasBackend,
            googleClientID: nil
        )
        let service = LiveAuthService(api: api, tokenStore: tokenStore, session: session, config: config)
        return (service, tokenStore, session)
    }

    private func appleCredential(user: String = "user-123") -> ProviderCredential {
        ProviderCredential(
            provider: .apple, identityToken: "id-token", authorizationCode: "code",
            nonce: "raw-nonce", userIdentifier: user, email: "ada@example.com", fullName: "Ada Lovelace"
        )
    }

    func testDevFallbackExchangeSignsInLocally() async throws {
        let (service, tokens, session) = makeService(hasBackend: false)
        try await service.completeSignIn(with:appleCredential())

        XCTAssertEqual(session.phase, .authenticated)
        XCTAssertEqual(session.user?.id, "user-123")
        XCTAssertEqual(session.user?.email, "ada@example.com")
        XCTAssertNotNil(tokens.refresh, "a session token should be stored")
    }

    func testBackendExchangePostsAndStoresTokens() async throws {
        let api = FakeAPIClient()
        api.nextDecodable = AuthTokensDTO(
            accessToken: "AT", refreshToken: "RT", expiresIn: 3600,
            user: UserDTO(id: "u1", email: "u@x.com", displayName: "U")
        )
        let (service, tokens, session) = makeService(hasBackend: true, api: api)

        try await service.completeSignIn(with:
            ProviderCredential(provider: .google, identityToken: "idtok", authorizationCode: nil,
                               nonce: nil, userIdentifier: "g1", email: nil, fullName: nil)
        )

        XCTAssertEqual(tokens.access, "AT")
        XCTAssertEqual(tokens.refresh, "RT")
        XCTAssertEqual(session.user?.id, "u1")
        XCTAssertEqual(api.sent.first?.path, "auth/google")
        XCTAssertEqual(api.sent.first?.method, .post)
        XCTAssertEqual(api.sent.first?.requiresAuth, false)
    }

    func testBackendExchangeWrapsAPIErrorAsAuthError() async {
        let api = FakeAPIClient()
        api.errorToThrow = .server(status: 500)
        let (service, _, _) = makeService(hasBackend: true, api: api)

        do {
            try await service.completeSignIn(with:appleCredential())
            XCTFail("expected an error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .backend(.server(status: 500)))
        } catch {
            XCTFail("expected AuthError, got \(error)")
        }
    }

    func testRestoreWithoutSessionStaysSignedOut() async {
        let (service, _, session) = makeService(hasBackend: false)
        await service.restore()
        XCTAssertEqual(session.phase, .unauthenticated)
    }

    func testRestoreWithDevSessionAuthenticates() async {
        let (service, tokens, session) = makeService(hasBackend: false)
        tokens.refresh = "dev-refresh-x"           // a stored session exists
        await service.restore()
        XCTAssertEqual(session.phase, .authenticated)
    }

    func testRestoreWithBackendFailedRefreshSignsOut() async {
        let (service, tokens, session) = makeService(hasBackend: true)
        tokens.refresh = "RT"
        tokens.refreshResult = false               // refresh fails
        await service.restore()
        XCTAssertEqual(session.phase, .unauthenticated)
        XCTAssertTrue(tokens.cleared)
    }

    func testSignOutClearsSession() async throws {
        let (service, tokens, session) = makeService(hasBackend: false)
        try await service.completeSignIn(with:appleCredential())

        service.signOut()
        XCTAssertEqual(session.phase, .unauthenticated)
        XCTAssertNil(session.user)
        XCTAssertTrue(tokens.cleared)
    }
}

// MARK: - Fakes

private final class FakeTokenStore: TokenStoring, TokenProviding, @unchecked Sendable {
    var access: String?
    var refresh: String?
    var refreshResult = false
    private(set) var cleared = false

    var hasSession: Bool { refresh != nil }
    func save(access: String, refresh: String) { self.access = access; self.refresh = refresh }
    func clear() { access = nil; refresh = nil; cleared = true }
    func currentAccessToken() async -> String? { access }
    func refresh() async throws -> Bool { refreshResult }
}

private final class FakeAPIClient: APIClient, @unchecked Sendable {
    var nextDecodable: Any?
    var errorToThrow: APIError?
    private(set) var sent: [Endpoint] = []

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        sent.append(endpoint)
        if let errorToThrow { throw errorToThrow }
        guard let value = nextDecodable as? T else { throw APIError.invalidResponse }
        return value
    }

    func send(_ endpoint: Endpoint) async throws {
        sent.append(endpoint)
        if let errorToThrow { throw errorToThrow }
    }
}
