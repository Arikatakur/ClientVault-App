import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Centralised, minimal haptics. The blueprint asks for consistent feedback on
/// unlock, copy, and destructive actions — route all of it through here so the
/// vocabulary stays small and uniform.
protocol HapticsServicing: Sendable {
    func success()
    func warning()
    func error()
    func selection()
    func impact(_ strength: Haptics.ImpactStrength)
}

/// Haptics call the UIKit feedback generators, which are intended to be invoked
/// from the main thread; every call site here is a SwiftUI action (already on
/// main), so no extra hopping is needed.
final class Haptics: HapticsServicing, @unchecked Sendable {
    enum ImpactStrength {
        case light, medium, heavy, soft, rigid
    }

    static let shared = Haptics()
    init() {}

    func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    func warning() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }

    func error() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    func selection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    func impact(_ strength: ImpactStrength) {
        #if canImport(UIKit)
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        switch strength {
        case .light: style = .light
        case .medium: style = .medium
        case .heavy: style = .heavy
        case .soft: style = .soft
        case .rigid: style = .rigid
        }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
        #endif
    }
}
