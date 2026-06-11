import Foundation
import AuthenticationServices
#if canImport(UIKit)
import UIKit
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

/// Drives authentication: provider sign-in (Apple/Google) → backend token
/// exchange → session. Backend validation is a seam (Amplify not provisioned);
/// until `config.hasBackend` is true, a dev fallback trusts the platform-verified
/// identity locally so the flow is exercisable end-to-end.
///
/// The Apple surface is split so the non-`Sendable` `ASAuthorization` is parsed
/// synchronously (off the async path) into a `Sendable` `ProviderCredential`.
protocol AuthServicing: AnyObject {
    /// Returns the SHA-256 nonce to attach to the Apple request, storing the raw
    /// nonce for the exchange. Non-isolated: called synchronously from the
    /// `SignInWithAppleButton` request closure.
    func appleRequestNonce() -> String

    /// Parses an Apple authorization result into a credential (or an error).
    /// Non-isolated and synchronous so it never captures `ASAuthorization` across
    /// an actor hop.
    func makeAppleCredential(from result: Result<ASAuthorization, Error>) -> Result<ProviderCredential, AuthError>

    /// Signs in with Google (presents the SDK UI) and completes the session.
    @MainActor func signInWithGoogle() async throws

    /// Exchanges a verified credential for an app session.
    @MainActor func completeSignIn(with credential: ProviderCredential) async throws

    /// Restores an existing session on launch (if any).
    @MainActor func restore() async

    @MainActor func deleteAccount() async throws

    func signOut()
}

final class LiveAuthService: AuthServicing {
    private let api: APIClient
    private let tokenStore: any TokenStoring & TokenProviding
    private let session: SessionStore
    private let config: AppConfig
    private var currentAppleNonce: String?

    init(
        api: APIClient,
        tokenStore: any TokenStoring & TokenProviding,
        session: SessionStore,
        config: AppConfig
    ) {
        self.api = api
        self.tokenStore = tokenStore
        self.session = session
        self.config = config
    }

    // MARK: Apple

    func appleRequestNonce() -> String {
        let raw = Nonce.random()
        currentAppleNonce = raw
        return Nonce.sha256(raw)
    }

    func makeAppleCredential(
        from result: Result<ASAuthorization, Error>
    ) -> Result<ProviderCredential, AuthError> {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let identityToken = String(data: tokenData, encoding: .utf8)
            else {
                return .failure(.invalidCredential)
            }
            let code = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
            let name = credential.fullName.map { PersonNameComponentsFormatter().string(from: $0) }
            return .success(
                ProviderCredential(
                    provider: .apple,
                    identityToken: identityToken,
                    authorizationCode: code,
                    nonce: currentAppleNonce,
                    userIdentifier: credential.user,
                    email: credential.email,
                    fullName: (name?.isEmpty == false) ? name : nil
                )
            )

        case .failure(let error):
            if let asError = error as? ASAuthorizationError, asError.code == .canceled {
                return .failure(.cancelled)
            }
            return .failure(.providerFailed(error.localizedDescription))
        }
    }

    // MARK: Google

    @MainActor
    func signInWithGoogle() async throws {
        #if canImport(GoogleSignIn)
        guard let presenter = UIApplication.shared.topViewController() else {
            throw AuthError.noPresenter
        }
        let credential: ProviderCredential
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            let user = result.user
            guard let idToken = user.idToken?.tokenString else {
                throw AuthError.invalidCredential
            }
            credential = ProviderCredential(
                provider: .google,
                identityToken: idToken,
                authorizationCode: nil,
                nonce: nil,
                userIdentifier: user.userID ?? idToken,
                email: user.profile?.email,
                fullName: user.profile?.name
            )
        } catch let error as AuthError {
            throw error
        } catch {
            let nsError = error as NSError
            if nsError.domain == "com.google.GIDSignIn", nsError.code == -5 { // canceled
                throw AuthError.cancelled
            }
            throw AuthError.providerFailed(error.localizedDescription)
        }
        try await completeSignIn(with: credential)
        #else
        throw AuthError.providerUnavailable("Google Sign-In isn't available in this build.")
        #endif
    }

    // MARK: Exchange (unit-tested directly)

    @MainActor
    func completeSignIn(with credential: ProviderCredential) async throws {
        if config.hasBackend {
            do {
                let endpoint = try Endpoint.json(
                    "auth/\(credential.provider.rawValue)",
                    method: .post,
                    body: AuthExchangeRequest(credential),
                    requiresAuth: false
                )
                let tokens: AuthTokensDTO = try await api.send(endpoint)
                tokenStore.save(access: tokens.accessToken, refresh: tokens.refreshToken)
                session.completeSignIn(user: tokens.user.toDomain())
            } catch let error as APIError {
                throw AuthError.backend(error)
            }
        } else {
            // Dev fallback — replaced by the server exchange once hasBackend is true.
            tokenStore.save(access: "dev-access", refresh: "dev-refresh-\(credential.userIdentifier)")
            session.completeSignIn(
                user: UserProfile(
                    id: credential.userIdentifier,
                    email: credential.email,
                    displayName: credential.fullName
                )
            )
        }
    }

    // MARK: Session lifecycle

    func signOut() {
        session.signOut()
    }

    @MainActor
    func restore() async {
        guard tokenStore.hasSession else { return }
        if config.hasBackend {
            let refreshed = (try? await tokenStore.refresh()) ?? false
            if refreshed { session.markAuthenticated() } else { session.signOut() }
        } else {
            session.markAuthenticated()
        }
    }

    @MainActor
    func deleteAccount() async throws {
        if config.hasBackend {
            do {
                try await api.send(Endpoint(path: "account", method: .delete))
            } catch let error as APIError {
                throw AuthError.backend(error)
            }
        }
        session.signOut()
    }
}

#if canImport(UIKit)
extension UIApplication {
    var activeKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    /// The top-most presented view controller — the right presenter for SDK UI.
    func topViewController() -> UIViewController? {
        var top = activeKeyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
#endif
