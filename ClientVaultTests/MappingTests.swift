import XCTest
@testable import ClientVault

final class MappingTests: XCTestCase {
    func testClientRoundTrip() {
        let now = Date()
        let client = Client(
            id: UUID(), name: "Acme", company: "Acme Co.",
            email: "hi@acme.test", phone: nil, notes: nil,
            createdAt: now, updatedAt: now, deletedAt: nil
        )
        XCTAssertEqual(client.toDTO().toDomain(), client)
    }

    func testProjectStatusFallsBackForUnknownString() {
        let now = Date()
        let dto = ProjectDTO(
            id: UUID(), clientId: nil, name: "P", summary: nil,
            status: "not-a-real-status", dueDate: nil, githubRepo: nil,
            createdAt: now, updatedAt: now, deletedAt: nil
        )
        // A single odd record degrades to `.lead` instead of breaking the decode.
        XCTAssertEqual(dto.toDomain().status, .lead)
    }

    func testPaymentRoundTripPreservesMinorUnits() {
        let now = Date()
        let payment = Payment(
            id: UUID(), projectId: UUID(), amountMinorUnits: 12_345,
            currencyCode: "USD", status: .partial, dueDate: nil, paidAt: nil,
            note: "deposit", createdAt: now, updatedAt: now, deletedAt: nil
        )
        let back = payment.toDTO().toDomain()
        XCTAssertEqual(back, payment)
        XCTAssertEqual(back.amountMinorUnits, 12_345)
    }

    func testVaultItemCarriesCiphertextOnly() throws {
        let crypto = AESGCMCrypto()
        let key = crypto.generateDataKey()
        let body = try crypto.seal(Data("secret".utf8), using: key)
        let now = Date()

        let item = VaultItem(
            id: UUID(), title: "GitHub PAT", type: .apiKey, tags: ["dev"],
            clientId: nil, projectId: nil, encryptedBody: body,
            createdAt: now, updatedAt: now, deletedAt: nil
        )

        let back = item.toDTO().toDomain()
        XCTAssertEqual(back, item)
        XCTAssertNotEqual(back.encryptedBody.ciphertext, Data("secret".utf8),
                          "the wire model must carry ciphertext, never plaintext")
    }
}
