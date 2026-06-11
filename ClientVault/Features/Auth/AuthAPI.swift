import Foundation

/// Wire shapes for the auth exchange. The app posts a provider credential to
/// `/auth/{provider}`; the backend validates the identity token and returns app
/// tokens + the user. See docs/backend-amplify.md.

struct AuthExchangeRequest: Encodable {
    let provider: String
    let identityToken: String
    let authorizationCode: String?
    let nonce: String?
    let email: String?
    let fullName: String?

    init(_ credential: ProviderCredential) {
        provider = credential.provider.rawValue
        identityToken = credential.identityToken
        authorizationCode = credential.authorizationCode
        nonce = credential.nonce
        email = credential.email
        fullName = credential.fullName
    }
}

struct AuthTokensDTO: Decodable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int?
    let user: UserDTO
}

struct UserDTO: Decodable, Equatable {
    let id: String
    let email: String?
    let displayName: String?

    func toDomain() -> UserProfile {
        UserProfile(id: id, email: email, displayName: displayName)
    }
}
