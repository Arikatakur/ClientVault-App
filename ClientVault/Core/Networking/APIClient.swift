import Foundation

/// Transport abstraction. Features depend on this protocol, not URLSession.
protocol APIClient: Sendable {
    /// Sends a request and decodes the JSON response.
    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    /// Sends a request expecting no response body.
    func send(_ endpoint: Endpoint) async throws
}

/// `URLSession`-backed client with a single auth/refresh/retry path and
/// structured error mapping.
final class URLSessionAPIClient: APIClient, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: TokenProviding
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL,
        tokenProvider: TokenProviding,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.session = session
        self.decoder = .clientVault
        self.encoder = .clientVault
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await perform(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    func send(_ endpoint: Endpoint) async throws {
        _ = try await perform(endpoint)
    }

    private func perform(_ endpoint: Endpoint, isRetry: Bool = false) async throws -> Data {
        let request = try await makeRequest(endpoint)
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

            switch http.statusCode {
            case 200..<300:
                return data
            case 401:
                if endpoint.requiresAuth && !isRetry, try await tokenProvider.refresh() {
                    return try await perform(endpoint, isRetry: true)
                }
                throw APIError.sessionExpired
            case 404:
                throw APIError.notFound
            case 429:
                let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
                throw APIError.rateLimited(retryAfter: retryAfter)
            default:
                throw APIError.server(status: http.statusCode)
            }
        } catch let error as APIError {
            throw error
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .dataNotAllowed:
                throw APIError.offline
            case .timedOut:
                throw APIError.timedOut
            default:
                throw APIError.transport(urlError.localizedDescription)
            }
        }
    }

    private func makeRequest(_ endpoint: Endpoint) async throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        )
        if !endpoint.query.isEmpty { components?.queryItems = endpoint.query }
        guard let url = components?.url else { throw APIError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        if endpoint.body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        for (field, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        if endpoint.requiresAuth, let token = await tokenProvider.currentAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
