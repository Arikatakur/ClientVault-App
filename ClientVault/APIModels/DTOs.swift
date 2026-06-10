import Foundation

/// Data-transfer objects: the exact JSON shapes exchanged with the backend.
/// Kept separate from domain entities so wire changes never ripple into the UI.
/// Dates are ISO-8601 (see `JSONDecoder.clientVault`).

struct ClientDTO: Codable {
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

struct ProjectDTO: Codable {
    let id: UUID
    var clientId: UUID?
    var name: String
    var summary: String?
    var status: String
    var dueDate: Date?
    var githubRepo: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}

struct PaymentDTO: Codable {
    let id: UUID
    var projectId: UUID
    var amountMinorUnits: Int
    var currencyCode: String
    var status: String
    var dueDate: Date?
    var paidAt: Date?
    var note: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}

struct VaultItemDTO: Codable {
    let id: UUID
    var title: String
    var type: String
    var tags: [String]
    var clientId: UUID?
    var projectId: UUID?
    var encryptedBody: EncryptedPayload   // ciphertext only
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}
