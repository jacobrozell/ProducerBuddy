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

    @Test("Tip jar link is configured and secure")
    func tipJarConfigured() {
        guard let tipJar = AppLinks.tipJar else {
            Issue.record("Expected tip jar URL to be configured")
            return
        }
        #expect(tipJar.scheme == "https")
        #expect(tipJar.host() == "buymeacoffee.com")
    }
}
