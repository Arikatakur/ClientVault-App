import SwiftUI

/// Semantic color tokens for ClientVault's dark, "secure fintech" aesthetic.
///
/// Colors are defined in code (not only the asset catalog) so the whole palette
/// is reviewable in one place and usable from previews and tests. The asset
/// catalog still carries `AccentColor`/`LaunchBackground` for the system to pick
/// up at launch.
enum Palette {
    // Surfaces
    static let background = Color(hex: 0x0C1014)        // near-black with a cool tint
    static let surface = Color(hex: 0x141A21)
    static let surfaceElevated = Color(hex: 0x1C242D)
    static let surfaceStroke = Color(hex: 0x2A343F)

    // Brand / accent
    static let accent = Color(hex: 0x3C8FF2)           // matches AccentColor.colorset
    static let accentMuted = Color(hex: 0x2A5C99)
    static let vault = Color(hex: 0x8B7BF0)            // distinct hue for vault surfaces

    // Text
    static let textPrimary = Color(hex: 0xF2F5F8)
    static let textSecondary = Color(hex: 0x9AA7B4)
    static let textTertiary = Color(hex: 0x5E6B78)
    static let onAccent = Color(hex: 0xFFFFFF)

    // Status
    static let success = Color(hex: 0x36C28B)
    static let warning = Color(hex: 0xF2B33C)
    static let danger = Color(hex: 0xF2545B)
    static let info = Color(hex: 0x3C8FF2)

    // Status by payment state — single source so UI stays consistent.
    static func paymentStatus(_ paid: Bool, overdue: Bool) -> Color {
        if paid { return success }
        return overdue ? danger : warning
    }
}

extension Color {
    /// Build a `Color` from a 0xRRGGBB integer in the sRGB space.
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
