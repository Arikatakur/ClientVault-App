import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}

/// A single API operation. Built by feature repositories and handed to the
/// `APIClient`. Endpoint shapes mirror the blueprint's conceptual API.
struct Endpoint {
    var path: String
    var method: HTTPMethod = .get
    var query: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data? = nil
    var requiresAuth: Bool = true

    /// Convenience builder that JSON-encodes a request body.
    static func json<Body: Encodable>(
        _ path: String,
        method: HTTPMethod,
        body: Body,
        requiresAuth: Bool = true,
        encoder: JSONEncoder = .clientVault
    ) throws -> Endpoint {
        Endpoint(
            path: path,
            method: method,
            body: try encoder.encode(body),
            requiresAuth: requiresAuth
        )
    }
}

extension JSONEncoder {
    /// Shared encoder: ISO-8601 dates to match the backend contract.
    static var clientVault: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var clientVault: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
