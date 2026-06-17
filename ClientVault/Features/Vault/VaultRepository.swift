import Foundation

protocol VaultRepositing: Sendable {
    func fetchItems() async throws -> [VaultItem]
    func save(_ item: VaultItem) async throws
    func delete(id: UUID) async throws
}

actor InMemoryVaultRepository: VaultRepositing {
    private var store: [UUID: VaultItem] = [:]

    func fetchItems() async throws -> [VaultItem] {
        store.values
            .filter { $0.deletedAt == nil }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func save(_ item: VaultItem) async throws {
        store[item.id] = item
    }

    func delete(id: UUID) async throws {
        guard var item = store[id] else { return }
        item.deletedAt = Date()
        item.updatedAt = Date()
        store[id] = item
    }
}

/// Backend seam — wires up once the Amplify API exists.
struct LiveVaultRepository: VaultRepositing {
    let api: APIClient

    func fetchItems() async throws -> [VaultItem] { [] }
    func save(_ item: VaultItem) async throws {}
    func delete(id: UUID) async throws {}
}
