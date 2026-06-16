import SwiftUI

/// Width constraints for a `NavigationSplitView` sidebar column.
struct SplitColumnWidth {
    let min: CGFloat
    let ideal: CGFloat
    let max: CGFloat
}

/// Shared size-class and Dynamic Type helpers for adaptive navigation and layout.
enum AdaptiveLayout {
    /// Landscape phone and other short-height layouts.
    static func isCompactHeight(_ vertical: UserInterfaceSizeClass?) -> Bool {
        vertical == .compact
    }

    /// iPad-style two-column navigation when horizontal space is regular.
    static func usesSplitNavigation(_ horizontal: UserInterfaceSizeClass?) -> Bool {
        horizontal == .regular
    }

    /// Extra bottom inset so content clears the tab bar and now-playing bar.
    static func bottomChromeClearance(
        dynamicType: DynamicTypeSize,
        showsNowPlayingBar: Bool
    ) -> CGFloat {
        var clearance = tabBarClearance(for: dynamicType)
        if showsNowPlayingBar { clearance += 56 }
        return clearance
    }

    static func tabBarClearance(for dynamicType: DynamicTypeSize) -> CGFloat {
        if dynamicType >= .accessibility5 { return 220 }
        if dynamicType >= .accessibility3 { return 160 }
        if dynamicType.isAccessibilitySize { return 120 }
        return 88
    }

    /// Prefer stacked layouts when text is large or height is compact (landscape).
    static func usesStackedLayout(
        dynamicType: DynamicTypeSize,
        verticalSizeClass: UserInterfaceSizeClass?
    ) -> Bool {
        dynamicType.isAccessibilitySize || isCompactHeight(verticalSizeClass)
    }

    /// Hero artwork cap in landscape so controls remain visible without scrolling.
    static func playerArtworkSize(compactHeight: Bool) -> CGFloat {
        compactHeight ? 140 : 280
    }

    /// Onboarding hero diameter scales down in landscape.
    static func onboardingHeroSize(compactHeight: Bool, scaled: CGFloat) -> CGFloat {
        compactHeight ? min(scaled, 96) : min(scaled, 140)
    }

    /// Sidebar column width for `NavigationSplitView` on iPad.
    static func splitColumnWidth(dynamicType: DynamicTypeSize) -> SplitColumnWidth {
        if dynamicType.isAccessibilitySize {
            SplitColumnWidth(min: 380, ideal: 420, max: 520)
        } else {
            SplitColumnWidth(min: 320, ideal: 380, max: 440)
        }
    }
}

private struct AdaptiveEmptyStateLayout: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        let clearance = AdaptiveLayout.tabBarClearance(for: dynamicTypeSize)
        if dynamicTypeSize.isAccessibilitySize {
            ScrollView {
                content
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.top, 8)
                    .padding(.bottom, clearance)
            }
            .scrollBounceBehavior(.basedOnSize)
        } else {
            content.safeAreaPadding(.bottom, clearance)
        }
    }
}

extension View {
    /// Scrollable empty states with tab-bar clearance for accessibility text sizes.
    func adaptiveEmptyStateLayout() -> some View {
        modifier(AdaptiveEmptyStateLayout())
    }

    /// WCAG 2.5.5 — minimum 44×44 pt interactive target.
    func minimumTapTarget(_ size: CGFloat = 44) -> some View {
        frame(minWidth: size, minHeight: size, alignment: .center)
            .contentShape(Rectangle())
    }

    /// Sidebar selection tint for split-view lists.
    @ViewBuilder
    func listSidebarSelection(isSelected: Bool, enabled: Bool) -> some View {
        if enabled, isSelected {
            listRowBackground(Brand.accentMuted)
        } else {
            self
        }
    }
}
