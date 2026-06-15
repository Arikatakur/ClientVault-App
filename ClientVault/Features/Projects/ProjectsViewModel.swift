import Foundation
import Observation

@MainActor
@Observable
final class ProjectsViewModel {
    private(set) var projects: [Project] = []
    var isLoading = false
    var errorMessage: String?
    var query = ""
    var statusFilter: ProjectStatus? = nil

    /// Filtered + searched subset for display.
    /// Search matches project name or the linked client's name (looked up via
    /// the shared ClientsViewModel, passed in at call sites).
    func filtered(clients: [Client]) -> [Project] {
        var result = projects.filter { $0.deletedAt == nil }
        if let status = statusFilter {
            result = result.filter { $0.status == status }
        }
        if !query.isEmpty {
            let q = query.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(q) ||
                clientName(for: $0.clientId, in: clients)?.lowercased().contains(q) == true
            }
        }
        return result
    }

    private let repo: ProjectRepositing

    init(repo: ProjectRepositing) { self.repo = repo }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            projects = try await repo.list()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func add(
        name: String,
        clientId: UUID?,
        status: ProjectStatus,
        dueDate: Date?,
        summary: String?,
        githubRepo: String?
    ) async {
        let now = Date()
        let project = Project(
            id: UUID(),
            clientId: clientId,
            name: name,
            summary: nilIfBlank(summary),
            status: status,
            dueDate: dueDate,
            githubRepo: nilIfBlank(githubRepo),
            createdAt: now,
            updatedAt: now
        )
        do {
            let saved = try await repo.create(project)
            projects.append(saved)
            projects.sort { $0.createdAt < $1.createdAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(_ project: Project) async {
        do {
            let saved = try await repo.update(project)
            if let i = projects.firstIndex(where: { $0.id == saved.id }) {
                projects[i] = saved
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: UUID) async {
        do {
            try await repo.delete(id: id)
            projects.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clientName(for clientId: UUID?, in clients: [Client]) -> String? {
        guard let id = clientId else { return nil }
        return clients.first { $0.id == id }?.name
    }

    private func nilIfBlank(_ s: String?) -> String? {
        guard let s, !s.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return s
    }
}
