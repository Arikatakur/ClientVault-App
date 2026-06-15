import Foundation
import Observation

extension Payment {
    /// Overdue is derived, never stored — can't go stale.
    var isOverdue: Bool {
        guard status != .paid else { return false }
        return dueDate.map { $0 < Date() } ?? false
    }
}

@MainActor
@Observable
final class PaymentsViewModel {
    private(set) var payments: [Payment] = []
    var isLoading = false
    var errorMessage: String?

    private let repo: PaymentRepositing

    init(repo: PaymentRepositing) { self.repo = repo }

    // MARK: - Queries

    func payments(for projectId: UUID) -> [Payment] {
        payments.filter { $0.projectId == projectId && $0.deletedAt == nil }
    }

    /// Count of all unpaid payments (pending + partial) across every project.
    var outstandingCount: Int {
        payments.filter { $0.deletedAt == nil && $0.status != .paid }.count
    }

    // MARK: - Formatting

    func formatted(_ payment: Payment) -> String {
        format(minorUnits: payment.amountMinorUnits, currencyCode: payment.currencyCode)
    }

    func formattedTotal(for projectId: UUID) -> (invoiced: String, paid: String, outstanding: String) {
        let rows = payments(for: projectId)
        let currency = rows.first?.currencyCode ?? "USD"
        let invoiced = rows.reduce(0) { $0 + $1.amountMinorUnits }
        let paid = rows.filter { $0.status == .paid }.reduce(0) { $0 + $1.amountMinorUnits }
        let outstanding = rows.filter { $0.status != .paid }.reduce(0) { $0 + $1.amountMinorUnits }
        return (
            format(minorUnits: invoiced, currencyCode: currency),
            format(minorUnits: paid, currencyCode: currency),
            format(minorUnits: outstanding, currencyCode: currency)
        )
    }

    private func format(minorUnits: Int, currencyCode: String) -> String {
        let amount = Decimal(minorUnits) / 100
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = currencyCode
        return fmt.string(from: amount as NSDecimalNumber) ?? "\(currencyCode) \(amount)"
    }

    // MARK: - Load

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            payments = try await repo.list()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Mutations

    func add(
        projectId: UUID,
        amountMinorUnits: Int,
        currencyCode: String,
        status: PaymentStatus,
        dueDate: Date?,
        paidAt: Date?,
        note: String?
    ) async {
        let now = Date()
        let payment = Payment(
            id: UUID(),
            projectId: projectId,
            amountMinorUnits: amountMinorUnits,
            currencyCode: currencyCode,
            status: status,
            dueDate: dueDate,
            paidAt: paidAt,
            note: nilIfBlank(note),
            createdAt: now,
            updatedAt: now
        )
        do {
            let saved = try await repo.create(payment)
            payments.append(saved)
            payments.sort { $0.createdAt < $1.createdAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(_ payment: Payment) async {
        do {
            let saved = try await repo.update(payment)
            if let i = payments.firstIndex(where: { $0.id == saved.id }) {
                payments[i] = saved
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: UUID) async {
        do {
            try await repo.delete(id: id)
            payments.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func nilIfBlank(_ s: String?) -> String? {
        guard let s, !s.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return s
    }
}
