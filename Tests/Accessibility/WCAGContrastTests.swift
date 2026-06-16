import SwiftUI
import Testing
#if canImport(UIKit)
import UIKit
#endif
@testable import MixStack

@Suite("WCAG contrast", .tags(.accessibility))
struct WCAGContrastTests {
    private struct Pair {
        let foreground: Color
        let background: Color
        let minimum: Double
        let label: String
    }

    @Test("Brand token pairs meet WCAG thresholds")
    func brandPairs() {
        let darkBackground = Color(hex: "#0B0C0F")
        let lightSurface = Color(hex: "#FFFDF8")
        let darkInk = Color(hex: "#E8E5DC")
        let lightInk = Color(hex: "#1A1814")

        let pairs: [Pair] = [
            Pair(foreground: Brand.textOnAccent, background: Brand.accent, minimum: 4.5, label: "text on accent"),
            Pair(foreground: darkInk, background: darkBackground, minimum: 4.5, label: "ink on dark bg"),
            Pair(foreground: lightInk, background: lightSurface, minimum: 4.5, label: "ink on light surface"),
            Pair(foreground: Brand.accent, background: darkBackground, minimum: 3.0, label: "accent on dark bg")
        ]
        for pair in pairs {
            let ratio = WCAGContrastMath.contrastRatio(
                foreground: rgba(pair.foreground),
                background: rgba(pair.background)
            )
            #expect(ratio >= pair.minimum, "\(pair.label) ratio \(ratio) < \(pair.minimum)")
        }
    }

    private func rgba(_ color: Color) -> WCAGContrastMath.RGB {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return WCAGContrastMath.RGB(Double(red), Double(green), Double(blue))
        #else
        return WCAGContrastMath.RGB(0, 0, 0)
        #endif
    }
}

enum WCAGContrastMath {
    struct RGB: Sendable {
        let red: Double
        let green: Double
        let blue: Double

        init(_ red: Double, _ green: Double, _ blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }
    }

    static func contrastRatio(foreground: RGB, background: RGB) -> Double {
        let l1 = relativeLuminance(foreground)
        let l2 = relativeLuminance(background)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func relativeLuminance(_ rgb: RGB) -> Double {
        func channel(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(rgb.red) + 0.7152 * channel(rgb.green) + 0.0722 * channel(rgb.blue)
    }
}
