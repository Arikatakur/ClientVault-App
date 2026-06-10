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
        return AppConfig(
            environment: env,
            apiBaseURL: baseURL,
            keychainService: "com.clientvault.app"
        )
    }()
}
