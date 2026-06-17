import Foundation
import Observation

@MainActor @Observable
final class ClientNotesViewModel {
    private(set) var notesByClient: [UUID: [ClientNote]] = [:]
    var isLoading = false
    var errorMessage: String?

    private let repo: ClientNoteRepositing

    init(repo: ClientNoteRepositing) { self.repo = repo }

    func notes(for clientId: UUID) -> [ClientNote] {
        notesByClient[clientId] ?? []
    }

    func load(clientId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            notesByClient[clientId] = try await repo.list(clientId: clientId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func add(clientId: UUID, body: String) async {
        let trimmed = body.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let note = ClientNote(
            id: UUID(),
            clientId: clientId,
            body: trimmed,
            createdAt: Date(),
            updatedAt: Date()
        )
        errorMessage = nil
        do {
            let saved = try await repo.create(note)
            notesByClient[clientId, default: []].insert(saved, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(_ note: ClientNote, body: String) async {
        let trimmed = body.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var updated = note
        updated.body = trimmed
        updated.updatedAt = Date()
        errorMessage = nil
        do {
            let saved = try await repo.update(updated)
            apply(saved)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: UUID, clientId: UUID) async {
        errorMessage = nil
        do {
            try await repo.delete(id: id)
            notesByClient[clientId]?.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ note: ClientNote) {
        guard var list = notesByClient[note.clientId],
              let idx = list.firstIndex(where: { $0.id == note.id }) else { return }
        list[idx] = note
        notesByClient[note.clientId] = list
    }
}
