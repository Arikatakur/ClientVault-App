import Foundation
import Observation

enum Plan: String, Codable {
    case free
    case pro

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        }
    }
}

/// Plan/premium gating for the UI.
///
/// IMPORTANT: this is a UX gate only — it decides what to *show*, not what's
/// allowed. The authoritative entitlement check is server-side (StoreKit/App
/// Store Server Notifications → backend webhook). Never trust the client for
/// access to paid cloud features.
@Observable
final class EntitlementStore {
    private(set) var plan: Plan

    init(plan: Plan = .free) {
        self.plan = plan
    }

    var isPro: Bool { plan == .pro }

    /// Applied from a server-validated entitlement once StoreKit is wired.
    func apply(plan: Plan) {
        self.plan = plan
    }

    /// Whether a given premium capability should be offered in the UI.
    func canUse(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .unlimitedClients, .cloudSync, .attachments:
            return isPro
        }
    }
}

enum PremiumFeature {
    case unlimitedClients
    case cloudSync
    case attachments
}
