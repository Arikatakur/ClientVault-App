import Foundation
import Observation

@MainActor
@Observable
final class ClientsViewModel {
    private(set) var clients: [Client] = []
    var isLoading = false
    var errorMessage: String?
    var query = ""

    var filtered: [Client] {
        guard !query.isEmpty else { return clients }
        let q = query.lowercased()
        return clients.filter {
            $0.name.lowercased().contains(q) ||
            ($0.company?.lowercased().contains(q) ?? false)
        }
    }

    private let repo: ClientRepositing

    init(repo: ClientRepositing) { self.repo = repo }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            clients = try await repo.list()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func add(
        name: String,
        company: String?,
        email: String?,
        phone: String?,
        notes: String?
    ) async {
        let now = Date()
        let client = Client(
            id: UUID(),
            name: name,
            company: nilIfBlank(company),
            email: nilIfBlank(email),
            phone: nilIfBlank(phone),
            notes: nilIfBlank(notes),
            createdAt: now,
            updatedAt: now
        )
        do {
            let saved = try await repo.create(client)
            clients.append(saved)
            clients.sort { $0.createdAt < $1.createdAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(_ client: Client) async {
        do {
            let saved = try await repo.update(client)
            if let i = clients.firstIndex(where: { $0.id == saved.id }) {
                clients[i] = saved
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: UUID) async {
        do {
            try await repo.delete(id: id)
            clients.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func nilIfBlank(_ s: String?) -> String? {
        guard let s, !s.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return s
    }
}
