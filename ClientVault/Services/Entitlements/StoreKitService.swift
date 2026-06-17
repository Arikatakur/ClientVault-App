import Foundation
import StoreKit

/// Abstracts StoreKit 2 so the dev environment can work without App Store products.
protocol StoreKitServicing: Sendable {
    func loadProducts() async throws -> [Product]
    func purchase(_ product: Product) async throws -> Bool
    func restorePurchases() async throws
}

/// Dev/CI stand-in. Returns no products; purchase/restore are no-ops.
/// The paywall renders a clean "unavailable" state when the product list is empty.
struct DevStoreKitService: StoreKitServicing {
    func loadProducts() async throws -> [Product] { [] }
    func purchase(_ product: Product) async throws -> Bool { false }
    func restorePurchases() async throws {}
}

struct LiveStoreKitService: StoreKitServicing {
    static let proMonthlyID = "org.clientvault.pro.monthly"

    func loadProducts() async throws -> [Product] {
        try await Product.products(for: [Self.proMonthlyID])
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { return false }
            await transaction.finish()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
    }
}
