import SwiftUI

/// A rounded elevated surface used to group content into cards. Generic over its
/// content so any view can be wrapped consistently.
struct CardContainer<Content: View>: View {
    var padding: CGFloat = Spacing.lg
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(Palette.surfaceStroke, lineWidth: 1)
            )
    }
}

#Preview {
    CardContainer {
        VStack(alignment: .leading, spacing: 8) {
            Text("Acme Co.").font(Typography.headline()).foregroundStyle(Palette.textPrimary)
            Text("3 active projects").font(Typography.subheadline()).foregroundStyle(Palette.textSecondary)
        }
    }
    .padding()
    .background(Palette.background)
}
