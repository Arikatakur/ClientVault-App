import Foundation

enum AuthProvider: String, Equatable {
    case apple
    case google
}

/// A verified sign-in credential from a provider, before it's exchanged with the
/// backend. `identityToken` is the provider's signed token the server validates.
struct ProviderCredential: Equatable {
    let provider: AuthProvider
    let identityToken: String
    let authorizationCode: String?
    /// Raw nonce sent in the Apple request (the request carried its SHA-256); the
    /// backend checks it against the token's `nonce` claim to prevent replay.
    let nonce: String?
    let userIdentifier: String
    let email: String?
    let fullName: String?
}

/// The signed-in user as the app knows them.
struct UserProfile: Equatable, Codable {
    let id: String
    let email: String?
    let displayName: String?
}

enum AuthError: Error, Equatable, Sendable {
    case cancelled
    case invalidCredential
    case providerFailed(String)
    case providerUnavailable(String)
    case noPresenter
    case backend(APIError)

    /// User-facing copy. `cancelled` returns empty — the UI should stay silent
    /// when the user backs out.
    var userMessage: String {
        switch self {
        case .cancelled:
            return ""
        case .invalidCredential:
            return "We couldn't read your sign-in details. Please try again."
        case .providerFailed:
            return "Sign-in didn't complete. Please try again."
        case .providerUnavailable(let why):
            return why
        case .noPresenter:
            return "Couldn't open the sign-in screen. Please try again."
        case .backend(let apiError):
            return apiError.userMessage
        }
    }
}
