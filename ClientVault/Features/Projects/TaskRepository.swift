import Foundation

protocol TaskRepositing: AnyObject {
    func list(projectId: UUID) async throws -> [ProjectTask]
    func create(_ task: ProjectTask) async throws -> ProjectTask
    func update(_ task: ProjectTask) async throws -> ProjectTask
    func delete(id: UUID) async throws
}

// MARK: - In-memory dev store

final class InMemoryTaskRepository: TaskRepositing {
    private var store: [UUID: ProjectTask] = [:]

    func list(projectId: UUID) async throws -> [ProjectTask] {
        store.values
            .filter { $0.projectId == projectId && $0.deletedAt == nil }
            .sorted { $0.position < $1.position }
    }

    func create(_ task: ProjectTask) async throws -> ProjectTask {
        store[task.id] = task
        return task
    }

    func update(_ task: ProjectTask) async throws -> ProjectTask {
        store[task.id] = task
        return task
    }

    func delete(id: UUID) async throws {
        store[id] = nil
    }
}

// MARK: - Live backend implementation

final class LiveTaskRepository: TaskRepositing {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func list(projectId: UUID) async throws -> [ProjectTask] {
        let endpoint = Endpoint(
            path: "tasks",
            query: [URLQueryItem(name: "projectId", value: projectId.uuidString)]
        )
        let dtos: [ProjectTaskDTO] = try await api.send(endpoint)
        return dtos.map { $0.toDomain() }
    }

    func create(_ task: ProjectTask) async throws -> ProjectTask {
        let endpoint = try Endpoint.json("tasks", method: .post, body: task.toDTO())
        let dto: ProjectTaskDTO = try await api.send(endpoint)
        return dto.toDomain()
    }

    func update(_ task: ProjectTask) async throws -> ProjectTask {
        let endpoint = try Endpoint.json("tasks/\(task.id)", method: .patch, body: task.toDTO())
        let dto: ProjectTaskDTO = try await api.send(endpoint)
        return dto.toDomain()
    }

    func delete(id: UUID) async throws {
        try await api.send(Endpoint(path: "tasks/\(id)", method: .delete))
    }
}
