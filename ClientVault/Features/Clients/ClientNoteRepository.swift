import Foundation

protocol ClientNoteRepositing: AnyObject {
    func list(clientId: UUID) async throws -> [ClientNote]
    func create(_ note: ClientNote) async throws -> ClientNote
    func update(_ note: ClientNote) async throws -> ClientNote
    func delete(id: UUID) async throws
}

// MARK: - In-memory dev store

final class InMemoryClientNoteRepository: ClientNoteRepositing {
    private var store: [UUID: ClientNote] = [:]

    func list(clientId: UUID) async throws -> [ClientNote] {
        store.values
            .filter { $0.clientId == clientId && $0.deletedAt == nil }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func create(_ note: ClientNote) async throws -> ClientNote {
        store[note.id] = note
        return note
    }

    func update(_ note: ClientNote) async throws -> ClientNote {
        store[note.id] = note
        return note
    }

    func delete(id: UUID) async throws {
        store[id] = nil
    }
}

// MARK: - Live backend implementation

final class LiveClientNoteRepository: ClientNoteRepositing {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func list(clientId: UUID) async throws -> [ClientNote] {
        let endpoint = Endpoint(
            path: "client-notes",
            query: [URLQueryItem(name: "clientId", value: clientId.uuidString)]
        )
        let dtos: [ClientNoteDTO] = try await api.send(endpoint)
        return dtos.map { $0.toDomain() }
    }

    func create(_ note: ClientNote) async throws -> ClientNote {
        let endpoint = try Endpoint.json("client-notes", method: .post, body: note.toDTO())
        let dto: ClientNoteDTO = try await api.send(endpoint)
        return dto.toDomain()
    }

    func update(_ note: ClientNote) async throws -> ClientNote {
        let endpoint = try Endpoint.json("client-notes/\(note.id)", method: .patch, body: note.toDTO())
        let dto: ClientNoteDTO = try await api.send(endpoint)
        return dto.toDomain()
    }

    func delete(id: UUID) async throws {
        try await api.send(Endpoint(path: "client-notes/\(id)", method: .delete))
    }
}
