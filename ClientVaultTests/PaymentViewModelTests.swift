import XCTest
@testable import ClientVault

@MainActor
final class PaymentViewModelTests: XCTestCase {

    // MARK: - InMemoryPaymentRepository

    func testCreateAndList() async throws {
        let repo = InMemoryPaymentRepository()
        let payment = makePayment(amountMinorUnits: 5000, status: .pending)
        let saved = try await repo.create(payment)
        XCTAssertEqual(saved.id, payment.id)
        let list = try await repo.list()
        XCTAssertEqual(list.count, 1)
    }

    func testListByProject() async throws {
        let repo = InMemoryPaymentRepository()
        let projectA = UUID()
        let projectB = UUID()
        _ = try await repo.create(makePayment(projectId: projectA, amountMinorUnits: 1000, status: .paid))
        _ = try await repo.create(makePayment(projectId: projectB, amountMinorUnits: 2000, status: .pending))
        let forA = try await repo.list(projectId: projectA)
        XCTAssertEqual(forA.count, 1)
        XCTAssertEqual(forA[0].projectId, projectA)
    }

    func testListExcludesSoftDeleted() async throws {
        let repo = InMemoryPaymentRepository()
        var payment = makePayment(amountMinorUnits: 999, status: .pending)
        payment.deletedAt = Date()
        _ = try await repo.create(payment)
        let list = try await repo.list()
        XCTAssertTrue(list.isEmpty)
    }

    func testUpdate() async throws {
        let repo = InMemoryPaymentRepository()
        let payment = makePayment(amountMinorUnits: 100, status: .pending)
        _ = try await repo.create(payment)
        var updated = payment; updated.amountMinorUnits = 200; updated.status = .paid
        let saved = try await repo.update(updated)
        XCTAssertEqual(saved.amountMinorUnits, 200)
        XCTAssertEqual(saved.status, .paid)
    }

    func testDelete() async throws {
        let repo = InMemoryPaymentRepository()
        let payment = makePayment(amountMinorUnits: 500, status: .pending)
        _ = try await repo.create(payment)
        try await repo.delete(id: payment.id)
        let list = try await repo.list()
        XCTAssertTrue(list.isEmpty)
    }

    // MARK: - PaymentsViewModel rollups

    func testOutstandingCount() async {
        let repo = InMemoryPaymentRepository()
        let vm = PaymentsViewModel(repo: repo)
        let projectId = UUID()
        await vm.add(projectId: projectId, amountMinorUnits: 5000, currencyCode: "USD",
                     status: .pending, dueDate: nil, paidAt: nil, note: nil)
        await vm.add(projectId: projectId, amountMinorUnits: 2000, currencyCode: "USD",
                     status: .paid, dueDate: nil, paidAt: nil, note: nil)
        XCTAssertEqual(vm.outstandingCount, 1)
    }

    func testPaymentsForProject() async {
        let repo = InMemoryPaymentRepository()
        let vm = PaymentsViewModel(repo: repo)
        let projectA = UUID()
        let projectB = UUID()
        await vm.add(projectId: projectA, amountMinorUnits: 1000, currencyCode: "USD",
                     status: .pending, dueDate: nil, paidAt: nil, note: nil)
        await vm.add(projectId: projectB, amountMinorUnits: 2000, currencyCode: "USD",
                     status: .pending, dueDate: nil, paidAt: nil, note: nil)
        XCTAssertEqual(vm.payments(for: projectA).count, 1)
        XCTAssertEqual(vm.payments(for: projectB).count, 1)
    }

    // MARK: - isOverdue

    func testIsOverdueWhenPastDueAndNotPaid() {
        var payment = makePayment(amountMinorUnits: 100, status: .pending)
        payment.dueDate = Date(timeIntervalSinceNow: -86400) // 1 day ago
        XCTAssertTrue(payment.isOverdue)
    }

    func testNotOverdueWhenPaid() {
        var payment = makePayment(amountMinorUnits: 100, status: .paid)
        payment.dueDate = Date(timeIntervalSinceNow: -86400)
        XCTAssertFalse(payment.isOverdue)
    }

    func testNotOverdueWhenFutureDue() {
        var payment = makePayment(amountMinorUnits: 100, status: .pending)
        payment.dueDate = Date(timeIntervalSinceNow: 86400) // tomorrow
        XCTAssertFalse(payment.isOverdue)
    }

    func testNotOverdueWhenNoDueDate() {
        let payment = makePayment(amountMinorUnits: 100, status: .pending)
        XCTAssertFalse(payment.isOverdue)
    }

    // MARK: - Helpers

    private func makePayment(
        projectId: UUID = UUID(),
        amountMinorUnits: Int,
        status: PaymentStatus
    ) -> Payment {
        let now = Date()
        return Payment(
            id: UUID(),
            projectId: projectId,
            amountMinorUnits: amountMinorUnits,
            currencyCode: "USD",
            status: status,
            dueDate: nil,
            paidAt: nil,
            note: nil,
            createdAt: now,
            updatedAt: now
        )
    }
}
