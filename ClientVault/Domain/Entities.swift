import Foundation

/// Domain entities — the app's vocabulary, independent of transport (DTOs) and
/// storage. All carry `id`/`createdAt`/`updatedAt` and a soft-delete marker for
/// safe sync. IDs are UUIDs minted client-side so creates are idempotent.

struct Client: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var company: String?
    var email: String?
    var phone: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}

enum ProjectStatus: String, Codable, CaseIterable, Identifiable {
    case lead, active, paused, done
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .lead: return "Lead"
        case .active: return "Active"
        case .paused: return "Paused"
        case .done: return "Done"
        }
    }
}

struct Project: Identifiable, Equatable, Hashable {
    let id: UUID
    var clientId: UUID?
    var name: String
    var summary: String?
    var status: ProjectStatus
    var dueDate: Date?
    var githubRepo: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}

enum PaymentStatus: String, Codable, CaseIterable, Identifiable {
    case pending, partial, paid, overdue
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .partial: return "Partial"
        case .paid:    return "Paid"
        case .overdue: return "Overdue"
        }
    }
}

struct Payment: Identifiable, Equatable {
    let id: UUID
    var projectId: UUID
    var amountMinorUnits: Int        // store money in minor units (cents) — never Double
    var currencyCode: String          // ISO 4217, e.g. "USD"
    var status: PaymentStatus
    var dueDate: Date?
    var paidAt: Date?
    var note: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}

/// Plaintext body encrypted into `VaultItem.encryptedBody`. Never leaves the
/// device unencrypted. `secret` is the primary copyable value (password, API
/// key, card number, note body). The optional fields are shown when non-nil.
struct VaultItemBody: Codable, Sendable {
    var secret: String
    var username: String?
    var url: String?
    var notes: String?
}

enum VaultItemType: String, Codable, CaseIterable, Identifiable {
    case password, apiKey, secureNote, card, custom
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .password: return "Password"
        case .apiKey: return "API Key"
        case .secureNote: return "Secure Note"
        case .card: return "Card"
        case .custom: return "Custom"
        }
    }
}

/// A vault item. Only `title`, `type`, optional `tags`, and the client/project
/// links are plaintext metadata; the secret itself lives in `encryptedBody`,
/// which is AES-GCM ciphertext the server can store but never read.
struct VaultItem: Identifiable, Equatable {
    let id: UUID
    var title: String
    var type: VaultItemType
    var tags: [String]
    var clientId: UUID?
    var projectId: UUID?
    var encryptedBody: EncryptedPayload
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}
