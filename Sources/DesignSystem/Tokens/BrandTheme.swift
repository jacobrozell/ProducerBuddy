import SwiftUI
import UIKit

/// MixStack brand palette — studio archive on warm parchment (light) and near-black (dark).
/// Accent violet is shared across modes for producer identity; body text meets WCAG AA on surfaces.
enum Brand {
    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static let background = dynamic(
        light: UIColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1),
        dark: UIColor(red: 0.04, green: 0.05, blue: 0.06, alpha: 1)
    )
    static let backgroundSecondary = dynamic(
        light: UIColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1),
        dark: UIColor(red: 0.06, green: 0.07, blue: 0.09, alpha: 1)
    )
    static let surface = dynamic(
        light: UIColor(red: 1.0, green: 0.99, blue: 0.97, alpha: 1),
        dark: UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1)
    )
    static let surfaceElevated = dynamic(
        light: UIColor(red: 0.94, green: 0.92, blue: 0.88, alpha: 1),
        dark: UIColor(red: 0.11, green: 0.12, blue: 0.15, alpha: 1)
    )
    static let line = dynamic(
        light: UIColor(red: 0.83, green: 0.81, blue: 0.77, alpha: 1),
        dark: UIColor(red: 0.16, green: 0.18, blue: 0.22, alpha: 1)
    )

    static let textPrimary = dynamic(
        light: UIColor(red: 0.10, green: 0.09, blue: 0.08, alpha: 1),
        dark: UIColor(red: 0.91, green: 0.90, blue: 0.86, alpha: 1)
    )
    static let textSecondary = dynamic(
        light: UIColor(red: 0.36, green: 0.34, blue: 0.31, alpha: 1),
        dark: UIColor(red: 0.60, green: 0.59, blue: 0.55, alpha: 1)
    )
    static let textFaint = dynamic(
        light: UIColor(red: 0.54, green: 0.52, blue: 0.47, alpha: 1),
        dark: UIColor(red: 0.40, green: 0.39, blue: 0.37, alpha: 1)
    )

    /// Primary accent — 4.5:1 on dark background as large text / UI chrome.
    static let accent = Color(hex: "#7C3AED")
    static let accentBright = Color(hex: "#9F67FF")
    static let accentMuted = Color(hex: "#7C3AED").opacity(0.14)

    static let destructive = dynamic(
        light: UIColor(red: 0.66, green: 0.17, blue: 0.15, alpha: 1),
        dark: UIColor(red: 0.55, green: 0.17, blue: 0.13, alpha: 1)
    )
    static let textOnAccent = Color.white
}
