import SwiftUI

/// The single "motion spec" referenced by the blueprint. Every animation in the
/// app should pull from here so timing and springs stay consistent and tunable
/// in one place.
enum Motion {
    // Durations (seconds)
    static let quick: Double = 0.18
    static let standard: Double = 0.28
    static let slow: Double = 0.44

    /// Default spring for interactive UI (sheets, list changes, selection).
    static let spring = Animation.spring(response: 0.42, dampingFraction: 0.82)

    /// Snappier spring for small, frequent affordances (toggles, taps).
    static let snappy = Animation.spring(response: 0.30, dampingFraction: 0.86)

    /// Gentle ease for entrances (dashboard cards, empty→populated).
    static let entrance = Animation.easeOut(duration: standard)

    /// Crossfade used by the vault reveal sheet (blur-to-clear of a secret).
    static let reveal = Animation.easeInOut(duration: standard)

    /// Instant, no animation — for the privacy shield, which must never animate
    /// the sensitive content into/out of view.
    static let none = Animation.linear(duration: 0)
}
