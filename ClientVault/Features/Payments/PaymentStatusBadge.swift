import SwiftUI

struct PaymentStatusBadge: View {
    let payment: Payment

    private var isOverdue: Bool { payment.isOverdue }

    private var label: String {
        isOverdue ? "Overdue" : payment.status.displayName
    }

    private var color: Color {
        if isOverdue { return Palette.danger }
        switch payment.status {
        case .pending: return Palette.textSecondary
        case .partial:  return Palette.warning
        case .paid:     return Palette.success
        case .overdue:  return Palette.danger
        }
    }

    var body: some View {
        Text(label)
            .font(Typography.caption())
            .fontWeight(.semibold)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.15), in: Capsule())
    }
}
