import Testing
@testable import MixStack

@Suite("Adaptive layout", .tags(.unit, .accessibility))
struct AdaptiveLayoutTests {
    @Test("Detects landscape phone height")
    func compactHeight() {
        #expect(AdaptiveLayout.isCompactHeight(.compact))
        #expect(!AdaptiveLayout.isCompactHeight(.regular))
        #expect(!AdaptiveLayout.isCompactHeight(nil))
    }

    @Test("Player artwork shrinks in landscape")
    func playerArtworkSize() {
        let landscape = AdaptiveLayout.playerArtworkSize(compactHeight: true)
        let portrait = AdaptiveLayout.playerArtworkSize(compactHeight: false)
        #expect(landscape < portrait)
    }

    @Test("Sidebar width widens for accessibility Dynamic Type")
    func splitColumnWidthAccessibility() {
        let standard = AdaptiveLayout.splitColumnWidth(dynamicType: .large)
        let largeText = AdaptiveLayout.splitColumnWidth(dynamicType: .accessibility3)
        #expect(largeText.ideal > standard.ideal)
    }
}
