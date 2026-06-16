import Foundation

/// Single source of truth for "is product area X reachable in this build?".
///
/// Build wide internally, ship narrow publicly: features can be merged to the
/// main branch while still hidden from release builds by flipping a flag here,
/// rather than deleting code. CI and dogfood builds can reveal everything by
/// launching with `-enable_full_product_surface`.
enum ReleaseSurface {
    /// True when the process was launched asking for the full surface (CI,
    /// dogfood). Never pass this argument to App Store builds.
    private static var fullSurfaceRequested: Bool {
        CommandLine.arguments.contains("-enable_full_product_surface")
    }

    /// Whether a gated area is reachable: visible if shipping-enabled OR the
    /// full surface was explicitly requested.
    private static func isEnabled(_ shipDefault: Bool) -> Bool {
        shipDefault || fullSurfaceRequested
    }

    // MARK: Product areas (flip to expand the public surface)

    /// The Settings tab. Ships on.
    static var settings: Bool { isEnabled(true) }

    /// Sharable visual release cards. Ships on.
    static var shareCards: Bool { isEnabled(true) }

    /// Automatic BPM/key detection. Ships on, but can be hidden if a device QA
    /// pass finds the estimates misleading.
    static var audioAnalysis: Bool { isEnabled(true) }
}
