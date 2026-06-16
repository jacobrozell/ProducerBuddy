import SwiftUI

/// Layout rhythm and semantic roles. Prefer `Brand` for product chrome colors.
enum DS {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let pill: CGFloat = 999
    }

    enum Typography {
        static func display(_ size: Font.TextStyle) -> Font {
            .system(size, design: .serif).weight(.bold)
        }

        static func statValue(_ size: Font.TextStyle = .title2) -> Font {
            .system(size, design: .serif).weight(.semibold)
        }
    }
}
