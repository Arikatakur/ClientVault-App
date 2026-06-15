import Foundation

/// CRUD contract for the Clients resource. Feature code depends on this protocol
/// so the backend seam is swappable without touching the UI.
protocol ClientRepositing: AnyObject {
    func list() async throws -> [Client]
    func create(_ client: Client) async throws -> Client
    func update(_ client: Client) async throws -> Client
    func delete(id: UUID) async throws
}

// MARK: - In-memory dev store (AppConfig.hasBackend == false)

/// Shared in-memory store used during development. Resets on cold launch —
/// acceptable pre-backend; the live implementation persists via the cloud.
final class InMemoryClientRepository: ClientRepositing {
    private var store: [UUID: Client] = [:]

    func list() async throws -> [Client] {
        store.values
            .filter { $0.deletedAt == nil }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func create(_ client: Client) async throws -> Client {
        store[client.id] = client
        return client
    }

    func update(_ client: Client) async throws -> Client {
        store[client.id] = client
        return client
    }

    func delete(id: UUID) async throws {
        store[id] = nil
    }
}

// MARK: - Live backend implementation (seam; wired once hasBackend == true)

final class LiveClientRepository: ClientRepositing {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func list() async throws -> [Client] {
        let dtos: [ClientDTO] = try await api.send(Endpoint(path: "clients"))
        return dtos.map { $0.toDomain() }
    }

    func create(_ client: Client) async throws -> Client {
        let endpoint = try Endpoint.json("clients", method: .post, body: client.toDTO())
        let dto: ClientDTO = try await api.send(endpoint)
        return dto.toDomain()
    }

    func update(_ client: Client) async throws -> Client {
        let endpoint = try Endpoint.json("clients/\(client.id)", method: .patch, body: client.toDTO())
        let dto: ClientDTO = try await api.send(endpoint)
        return dto.toDomain()
    }

    func delete(id: UUID) async throws {
        try await api.send(Endpoint(path: "clients/\(id)", method: .delete))
    }
}
