import SwiftUI

/// Type ramp. Uses the rounded system face for a friendly, premium feel while
/// staying fully Dynamic Type-aware (sizes are relative to text styles).
enum Typography {
    static func largeTitle() -> Font { .system(.largeTitle, design: .rounded, weight: .bold) }
    static func title() -> Font { .system(.title2, design: .rounded, weight: .semibold) }
    static func headline() -> Font { .system(.headline, design: .rounded, weight: .semibold) }
    static func body() -> Font { .system(.body, design: .rounded) }
    static func callout() -> Font { .system(.callout, design: .rounded) }
    static func subheadline() -> Font { .system(.subheadline, design: .rounded) }
    static func footnote() -> Font { .system(.footnote, design: .rounded) }
    static func caption() -> Font { .system(.caption, design: .rounded) }

    /// Monospaced — used for secrets, ids, amounts where alignment matters.
    static func mono(_ style: Font.TextStyle = .body) -> Font {
        .system(style, design: .monospaced)
    }
}

extension Text {
    func cvTitle() -> some View { font(Typography.title()).foregroundStyle(Palette.textPrimary) }
    func cvHeadline() -> some View { font(Typography.headline()).foregroundStyle(Palette.textPrimary) }
    func cvBody() -> some View { font(Typography.body()).foregroundStyle(Palette.textPrimary) }
    func cvSecondary() -> some View { font(Typography.subheadline()).foregroundStyle(Palette.textSecondary) }
}
