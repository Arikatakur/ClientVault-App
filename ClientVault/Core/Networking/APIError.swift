import Foundation

/// Structured API errors mapped to user-friendly messaging. Acceptance criteria
/// call out offline, rate-limited, and session-expired states explicitly.
enum APIError: Error, Equatable, Sendable {
    case offline
    case timedOut
    case unauthorized
    case sessionExpired
    case rateLimited(retryAfter: TimeInterval?)
    case notFound
    case server(status: Int)
    case decoding(String)
    case transport(String)
    case invalidResponse

    /// Copy suitable for showing in an alert/toast. Never leaks technical detail.
    var userMessage: String {
        switch self {
        case .offline:
            return "You appear to be offline. Check your connection and try again."
        case .timedOut:
            return "The request timed out. Please try again."
        case .unauthorized, .sessionExpired:
            return "Your session expired. Please sign in again."
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Too many attempts. Try again in \(Int(seconds))s."
            }
            return "Too many attempts. Please wait a moment and try again."
        case .notFound:
            return "We couldn't find what you were looking for."
        case .server:
            return "Something went wrong on our side. Please try again shortly."
        case .decoding, .transport, .invalidResponse:
            return "Something went wrong. Please try again."
        }
    }
}
