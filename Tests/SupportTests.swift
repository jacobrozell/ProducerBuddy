import Testing
import SwiftUI
@testable import MixStack

@Suite("Support")
struct SupportTests {

    @Test("Appearance maps to the right color scheme")
    func appearanceColorScheme() {
        #expect(AppAppearance.system.colorScheme == nil)
        #expect(AppAppearance.light.colorScheme == .light)
        #expect(AppAppearance.dark.colorScheme == .dark)
    }

    @Test("Release surface ships its core areas enabled by default")
    func releaseSurfaceDefaults() {
        #expect(ReleaseSurface.settings)
        #expect(ReleaseSurface.shareCards)
        #expect(ReleaseSurface.audioAnalysis)
    }

    @Test("External links are HTTPS")
    func linksAreSecure() {
        #expect(AppLinks.privacy.scheme == "https")
        #expect(AppLinks.support.scheme == "https")
        #expect(AppLinks.accessibility.scheme == "https")
    }

    @Test("Optional tip jar is hidden until configured")
    func tipJarOptional() {
        // Defaults to nil so the Settings row stays hidden.
        #expect(AppLinks.tipJar == nil)
    }
}
