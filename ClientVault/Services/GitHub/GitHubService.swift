import AuthenticationServices
import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Model

struct GitHubProfile: Codable, Sendable, Equatable {
    let login: String
    let name: String?
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case login, name
        case avatarURL = "avatar_url"
    }
}

enum GitHubError: Error, LocalizedError {
    case missingClientID
    case missingOAuthCode
    case backendNotProvisioned

    var errorDescription: String? {
        switch self {
        case .missingClientID: return "GitHub client ID is not configured."
        case .missingOAuthCode: return "No authorization code in the OAuth callback."
        case .backendNotProvisioned: return "GitHub integration requires the backend to be provisioned."
        }
    }
}

// MARK: - Protocol

/// Backend-facing half of the GitHub OAuth flow: exchanges a code for a profile.
/// Client-secret stays server-side; this method only sends the code.
protocol GitHubServicing: Sendable {
    func exchangeCode(_ code: String) async throws -> GitHubProfile
}

// MARK: - Dev seam

/// Returns a mock profile immediately. Used when `AppConfig.hasBackend == false`.
struct DevGitHubService: GitHubServicing {
    func exchangeCode(_ code: String) async throws -> GitHubProfile {
        GitHubProfile(login: "dev-user", name: "Dev User", avatarURL: nil)
    }
}

// MARK: - Live implementation

/// POSTs the OAuth code to the backend exchange endpoint and returns the profile.
struct LiveGitHubService: GitHubServicing {
    let api: APIClient

    func exchangeCode(_ code: String) async throws -> GitHubProfile {
        // TODO(github): POST { code } → /auth/github/exchange → { login, name, avatar_url }
        // The backend keeps client_secret server-side and returns only the profile.
        throw GitHubError.backendNotProvisioned
    }
}

// MARK: - OAuth coordinator

/// Manages the ASWebAuthenticationSession lifetime.
/// `@unchecked Sendable` because all access is from the main thread (callers are @MainActor).
final class GitHubOAuthCoordinator: NSObject, ASWebAuthenticationPresentationContextProviding, @unchecked Sendable {
    private var session: ASWebAuthenticationSession?

    func authenticate(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let s = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: URLError(.cancelled))
                }
            }
            s.presentationContextProvider = self
            s.prefersEphemeralWebBrowserSession = false
            self.session = s
            s.start()
        }
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Called on the main thread by ASWebAuthenticationSession.
        MainActor.assumeIsolated {
            #if canImport(UIKit)
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: \.isKeyWindow) ?? UIWindow()
            #else
            UIWindow()
            #endif
        }
    }
}
