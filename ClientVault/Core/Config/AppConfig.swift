import Foundation

/// Build/environment configuration. Values here are non-secret. Secrets (signing,
/// API keys) come from xcconfig/CI, never from source.
struct AppConfig {
    enum Environment: String {
        case development
        case production
    }

    let environment: Environment
    let apiBaseURL: URL
    let keychainService: String

    /// Whether the cloud backend is provisioned. While false (Amplify not set up
    /// yet), auth uses a local dev fallback instead of the server token exchange.
    let hasBackend: Bool

    /// Google OAuth client id (from `GIDClientID` in Info.plist). Nil until set up
    /// in the Google Cloud console; the Google button errors gracefully without it.
    let googleClientID: String?

    /// The active configuration. The API base URL is a placeholder until the
    /// AWS Amplify Gen 2 backend is provisioned (see docs/backend-amplify.md);
    /// it is read from Info.plist (`API_BASE_URL`) when present so each build
    /// configuration can point at its own stage without code changes.
    static let current: AppConfig = {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        let baseURL = urlString.flatMap(URL.init(string:))
            ?? URL(string: "https://api.clientvault.app")!   // placeholder
        #if DEBUG
        let env: Environment = .development
        #else
        let env: Environment = .production
        #endif
        let info = Bundle.main.infoDictionary
        let googleClientID = (info?["GIDClientID"] as? String).flatMap { value in
            // Treat the committed placeholder as "not configured".
            value.contains("PLACEHOLDER") || value.isEmpty ? nil : value
        }
        return AppConfig(
            environment: env,
            apiBaseURL: baseURL,
            keychainService: "com.clientvault.app",
            // Flip to true once the Amplify backend + auth endpoints exist.
            hasBackend: false,
            googleClientID: googleClientID
        )
    }()
}
