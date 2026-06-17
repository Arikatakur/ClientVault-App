import Foundation
import Observation

@MainActor @Observable
final class TasksViewModel {
    private(set) var tasksByProject: [UUID: [ProjectTask]] = [:]
    var isLoading = false
    var errorMessage: String?

    private let repo: TaskRepositing

    init(repo: TaskRepositing) { self.repo = repo }

    func tasks(for projectId: UUID) -> [ProjectTask] {
        tasksByProject[projectId] ?? []
    }

    func load(projectId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            tasksByProject[projectId] = try await repo.list(projectId: projectId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func add(projectId: UUID, title: String) async {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let existing = tasks(for: projectId)
        let task = ProjectTask(
            id: UUID(),
            projectId: projectId,
            title: trimmed,
            isCompleted: false,
            position: existing.count,
            createdAt: Date(),
            updatedAt: Date()
        )
        errorMessage = nil
        do {
            let saved = try await repo.create(task)
            tasksByProject[projectId, default: []].append(saved)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(_ task: ProjectTask) async {
        var updated = task
        updated.isCompleted.toggle()
        updated.updatedAt = Date()
        errorMessage = nil
        do {
            let saved = try await repo.update(updated)
            apply(saved)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: UUID, projectId: UUID) async {
        errorMessage = nil
        do {
            try await repo.delete(id: id)
            tasksByProject[projectId]?.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ task: ProjectTask) {
        guard var list = tasksByProject[task.projectId],
              let idx = list.firstIndex(where: { $0.id == task.id }) else { return }
        list[idx] = task
        tasksByProject[task.projectId] = list
    }
}
