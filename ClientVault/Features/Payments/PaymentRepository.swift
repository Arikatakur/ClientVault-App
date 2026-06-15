import Foundation

/// CRUD contract for the Payments resource. Exposes both a full `list()` for
/// dashboard rollups and a filtered `list(projectId:)` for per-project detail.
protocol PaymentRepositing: AnyObject {
    func list() async throws -> [Payment]
    func list(projectId: UUID) async throws -> [Payment]
    func create(_ payment: Payment) async throws -> Payment
    func update(_ payment: Payment) async throws -> Payment
    func delete(id: UUID) async throws
}

// MARK: - In-memory dev store (AppConfig.hasBackend == false)

final class InMemoryPaymentRepository: PaymentRepositing {
    private var store: [UUID: Payment] = [:]

    func list() async throws -> [Payment] {
        store.values
            .filter { $0.deletedAt == nil }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func list(projectId: UUID) async throws -> [Payment] {
        store.values
            .filter { $0.projectId == projectId && $0.deletedAt == nil }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func create(_ payment: Payment) async throws -> Payment {
        store[payment.id] = payment
        return payment
    }

    func update(_ payment: Payment) async throws -> Payment {
        store[payment.id] = payment
        return payment
    }

    func delete(id: UUID) async throws {
        store[id] = nil
    }
}

// MARK: - Live backend implementation (seam; wired once hasBackend == true)

final class LivePaymentRepository: PaymentRepositing {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func list() async throws -> [Payment] {
        let dtos: [PaymentDTO] = try await api.send(Endpoint(path: "payments"))
        return dtos.map { $0.toDomain() }
    }

    func list(projectId: UUID) async throws -> [Payment] {
        let dtos: [PaymentDTO] = try await api.send(Endpoint(path: "projects/\(projectId)/payments"))
        return dtos.map { $0.toDomain() }
    }

    func create(_ payment: Payment) async throws -> Payment {
        let endpoint = try Endpoint.json("payments", method: .post, body: payment.toDTO())
        let dto: PaymentDTO = try await api.send(endpoint)
        return dto.toDomain()
    }

    func update(_ payment: Payment) async throws -> Payment {
        let endpoint = try Endpoint.json("payments/\(payment.id)", method: .patch, body: payment.toDTO())
        let dto: PaymentDTO = try await api.send(endpoint)
        return dto.toDomain()
    }

    func delete(id: UUID) async throws {
        try await api.send(Endpoint(path: "payments/\(id)", method: .delete))
    }
}
