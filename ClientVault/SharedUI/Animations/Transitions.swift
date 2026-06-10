import SwiftUI

/// Reusable transitions so motion stays consistent across features.
extension AnyTransition {
    /// Cards/rows entering: rise slightly while fading in.
    static var cvRise: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        )
    }

    /// The vault reveal crossfade (a secret blurring into clarity is applied at
    /// the call site; this is the opacity half).
    static var cvReveal: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.98))
    }
}
