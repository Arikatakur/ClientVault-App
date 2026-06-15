import Foundation

/// CRUD contract for the Projects resource.
protocol ProjectRepositing: AnyObject {
    func list() async throws -> [Project]
    func listByClient(clientId: UUID) async throws -> [Project]
    func create(_ project: Project) async throws -> Project
    func update(_ project: Project) async throws -> Project
    func delete(id: UUID) async throws
}

// MARK: - In-memory dev store

final class InMemoryProjectRepository: ProjectRepositing {
    private var store: [UUID: Project] = [:]

    func list() async throws -> [Project] {
        store.values
            .filter { $0.deletedAt == nil }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func listByClient(clientId: UUID) async throws -> [Project] {
        store.values
            .filter { $0.clientId == clientId && $0.deletedAt == nil }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func create(_ project: Project) async throws -> Project {
        store[project.id] = project
        return project
    }

    func update(_ project: Project) async throws -> Project {
        store[project.id] = project
        return project
    }

    func delete(id: UUID) async throws {
        store[id] = nil
    }
}

// MARK: - Live backend implementation

final class LiveProjectRepository: ProjectRepositing {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func list() async throws -> [Project] {
        let dtos: [ProjectDTO] = try await api.send(Endpoint(path: "projects"))
        return dtos.map { $0.toDomain() }
    }

    func listByClient(clientId: UUID) async throws -> [Project] {
        let endpoint = Endpoint(
            path: "projects",
            query: [URLQueryItem(name: "clientId", value: clientId.uuidString)]
        )
        let dtos: [ProjectDTO] = try await api.send(endpoint)
        return dtos.map { $0.toDomain() }
    }

    func create(_ project: Project) async throws -> Project {
        let endpoint = try Endpoint.json("projects", method: .post, body: project.toDTO())
        let dto: ProjectDTO = try await api.send(endpoint)
        return dto.toDomain()
    }

    func update(_ project: Project) async throws -> Project {
        let endpoint = try Endpoint.json("projects/\(project.id)", method: .patch, body: project.toDTO())
        let dto: ProjectDTO = try await api.send(endpoint)
        return dto.toDomain()
    }

    func delete(id: UUID) async throws {
        try await api.send(Endpoint(path: "projects/\(id)", method: .delete))
    }
}
