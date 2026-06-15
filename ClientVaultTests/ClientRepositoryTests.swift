import XCTest
@testable import ClientVault

final class ClientRepositoryTests: XCTestCase {

    // MARK: - InMemoryClientRepository

    func testCreateAndList() async throws {
        let repo = InMemoryClientRepository()
        let client = makeClient(name: "Acme")
        _ = try await repo.create(client)
        let list = try await repo.list()
        XCTAssertEqual(list.count, 1)
        XCTAssertEqual(list[0].name, "Acme")
    }

    func testListExcludesSoftDeleted() async throws {
        let repo = InMemoryClientRepository()
        var client = makeClient(name: "Gone")
        client.deletedAt = Date()
        _ = try await repo.create(client)
        let list = try await repo.list()
        XCTAssertTrue(list.isEmpty)
    }

    func testUpdate() async throws {
        let repo = InMemoryClientRepository()
        let original = makeClient(name: "Old Name")
        _ = try await repo.create(original)

        var updated = original
        updated.name = "New Name"
        _ = try await repo.update(updated)

        let list = try await repo.list()
        XCTAssertEqual(list[0].name, "New Name")
    }

    func testDelete() async throws {
        let repo = InMemoryClientRepository()
        let client = makeClient(name: "To delete")
        _ = try await repo.create(client)
        try await repo.delete(id: client.id)
        let list = try await repo.list()
        XCTAssertTrue(list.isEmpty)
    }

    func testListSortedByCreatedAt() async throws {
        let repo = InMemoryClientRepository()
        let earlier = makeClient(name: "First",  createdAt: Date(timeIntervalSinceNow: -10))
        let later   = makeClient(name: "Second", createdAt: Date(timeIntervalSinceNow:   0))
        _ = try await repo.create(later)
        _ = try await repo.create(earlier)
        let list = try await repo.list()
        XCTAssertEqual(list.map(\.name), ["First", "Second"])
    }

    // MARK: - InMemoryProjectRepository

    func testProjectCreateAndList() async throws {
        let repo = InMemoryProjectRepository()
        let project = makeProject(name: "Alpha")
        _ = try await repo.create(project)
        let list = try await repo.list()
        XCTAssertEqual(list.count, 1)
        XCTAssertEqual(list[0].name, "Alpha")
    }

    func testProjectListByClient() async throws {
        let repo = InMemoryProjectRepository()
        let clientA = UUID()
        let clientB = UUID()
        _ = try await repo.create(makeProject(name: "A1", clientId: clientA))
        _ = try await repo.create(makeProject(name: "A2", clientId: clientA))
        _ = try await repo.create(makeProject(name: "B1", clientId: clientB))

        let forA = try await repo.listByClient(clientId: clientA)
        XCTAssertEqual(forA.count, 2)
        XCTAssertTrue(forA.allSatisfy { $0.clientId == clientA })
    }

    func testProjectDelete() async throws {
        let repo = InMemoryProjectRepository()
        let project = makeProject(name: "Temp")
        _ = try await repo.create(project)
        try await repo.delete(id: project.id)
        let list = try await repo.list()
        XCTAssertTrue(list.isEmpty)
    }

    // MARK: - Helpers

    private func makeClient(
        name: String,
        createdAt: Date = Date()
    ) -> Client {
        Client(
            id: UUID(), name: name, company: nil, email: nil, phone: nil,
            notes: nil, createdAt: createdAt, updatedAt: createdAt, deletedAt: nil
        )
    }

    private func makeProject(
        name: String,
        clientId: UUID? = nil,
        createdAt: Date = Date()
    ) -> Project {
        Project(
            id: UUID(), clientId: clientId, name: name, summary: nil,
            status: .lead, dueDate: nil, githubRepo: nil,
            createdAt: createdAt, updatedAt: createdAt, deletedAt: nil
        )
    }
}
