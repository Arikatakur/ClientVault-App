import Foundation
import Observation
import StoreKit

enum Plan: String, Codable {
    case free
    case pro

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro:  return "Pro"
        }
    }
}

enum PremiumFeature {
    case unlimitedClients
    case cloudSync
    case attachments
}

/// Plan/premium gating for the UI.
///
/// IMPORTANT: this is a UX gate only — it decides what to *show*, not what's
/// allowed. The authoritative entitlement check is server-side (StoreKit/App
/// Store Server Notifications → backend webhook). Never trust the client for
/// access to paid cloud features.
@MainActor
@Observable
final class EntitlementStore {
    private(set) var plan: Plan = .free
    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = false
    var purchaseError: String?

    private let storeKit: StoreKitServicing

    init(storeKit: StoreKitServicing) {
        self.storeKit = storeKit
        startTransactionListeners()
    }

    var isPro: Bool { plan == .pro }

    func canUse(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .unlimitedClients, .cloudSync, .attachments:
            return isPro
        }
    }

    /// Applied from a server-validated entitlement (App Store Server Notifications → backend webhook).
    func apply(plan: Plan) {
        self.plan = plan
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        products = (try? await storeKit.loadProducts()) ?? []
    }

    func purchase(_ product: Product) async {
        purchaseError = nil
        do {
            let purchased = try await storeKit.purchase(product)
            if purchased {
                await checkCurrentEntitlements()
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        purchaseError = nil
        do {
            try await storeKit.restorePurchases()
            await checkCurrentEntitlements()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Transaction lifecycle

    private func startTransactionListeners() {
        Task(priority: .background) {
            // Finish any transactions the app didn't process (e.g. terminated mid-purchase).
            for await result in Transaction.unfinished {
                await handleTransaction(result)
            }
            await checkCurrentEntitlements()
        }
        Task(priority: .background) {
            // Receive transactions from other devices, Ask to Buy, etc.
            for await result in Transaction.updates {
                await handleTransaction(result)
            }
        }
    }

    private func checkCurrentEntitlements() async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == LiveStoreKitService.proMonthlyID,
               transaction.revocationDate == nil {
                hasPro = true
            }
        }
        plan = hasPro ? .pro : .free
    }

    private func handleTransaction(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.revocationDate != nil {
            await checkCurrentEntitlements()
        } else if let expiry = transaction.expirationDate, expiry < Date() {
            // Expired subscription — re-evaluate all entitlements.
            await checkCurrentEntitlements()
        } else {
            plan = .pro
        }
        await transaction.finish()
    }
}
