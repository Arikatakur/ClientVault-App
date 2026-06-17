import Foundation

/// DTO ↔ domain mapping. Unknown enum strings degrade to a safe default rather
/// than throwing, so one odd record can't break a whole list decode.

extension ClientDTO {
    func toDomain() -> Client {
        Client(
            id: id, name: name, company: company, email: email, phone: phone,
            notes: notes, createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt
        )
    }
}

extension Client {
    func toDTO() -> ClientDTO {
        ClientDTO(
            id: id, name: name, company: company, email: email, phone: phone,
            notes: notes, createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt
        )
    }
}

extension ProjectDTO {
    func toDomain() -> Project {
        Project(
            id: id, clientId: clientId, name: name, summary: summary,
            status: ProjectStatus(rawValue: status) ?? .lead,
            dueDate: dueDate, githubRepo: githubRepo,
            createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt
        )
    }
}

extension Project {
    func toDTO() -> ProjectDTO {
        ProjectDTO(
            id: id, clientId: clientId, name: name, summary: summary,
            status: status.rawValue, dueDate: dueDate, githubRepo: githubRepo,
            createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt
        )
    }
}

extension PaymentDTO {
    func toDomain() -> Payment {
        Payment(
            id: id, projectId: projectId, amountMinorUnits: amountMinorUnits,
            currencyCode: currencyCode, status: PaymentStatus(rawValue: status) ?? .pending,
            dueDate: dueDate, paidAt: paidAt, note: note,
            createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt
        )
    }
}

extension Payment {
    func toDTO() -> PaymentDTO {
        PaymentDTO(
            id: id, projectId: projectId, amountMinorUnits: amountMinorUnits,
            currencyCode: currencyCode, status: status.rawValue,
            dueDate: dueDate, paidAt: paidAt, note: note,
            createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt
        )
    }
}

extension ProjectTaskDTO {
    func toDomain() -> ProjectTask {
        ProjectTask(
            id: id, projectId: projectId, title: title,
            isCompleted: isCompleted, position: position,
            createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt
        )
    }
}

extension ProjectTask {
    func toDTO() -> ProjectTaskDTO {
        ProjectTaskDTO(
            id: id, projectId: projectId, title: title,
            isCompleted: isCompleted, position: position,
            createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt
        )
    }
}

extension ClientNoteDTO {
    func toDomain() -> ClientNote {
        ClientNote(
            id: id, clientId: clientId, body: body,
            createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt
        )
    }
}

extension ClientNote {
    func toDTO() -> ClientNoteDTO {
        ClientNoteDTO(
            id: id, clientId: clientId, body: body,
            createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt
        )
    }
}

extension VaultItemDTO {
    func toDomain() -> VaultItem {
        VaultItem(
            id: id, title: title, type: VaultItemType(rawValue: type) ?? .custom,
            tags: tags, clientId: clientId, projectId: projectId,
            encryptedBody: encryptedBody,
            createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt
        )
    }
}

extension VaultItem {
    func toDTO() -> VaultItemDTO {
        VaultItemDTO(
            id: id, title: title, type: type.rawValue, tags: tags,
            clientId: clientId, projectId: projectId, encryptedBody: encryptedBody,
            createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt
        )
    }
}
