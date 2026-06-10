import SwiftUI

/// A small uppercase section label used above grouped content.
struct SectionHeader: View {
    let title: String
    var action: (label: String, handler: () -> Void)? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(Typography.caption())
                .foregroundStyle(Palette.textTertiary)
                .tracking(0.8)
            Spacer()
            if let action {
                Button(action.label, action: action.handler)
                    .font(Typography.caption())
                    .foregroundStyle(Palette.accent)
            }
        }
    }
}
