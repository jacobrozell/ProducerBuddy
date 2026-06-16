import Testing
@testable import MixStack

@Suite("Accessibility identifiers", .tags(.accessibility, .releaseGate))
struct AccessibilityIdentifierContractTests {
    @Test("Library identifiers are stable")
    func libraryIDs() {
        #expect(A11yID.Library.addMenu == "library.addMenu")
        #expect(A11yID.Library.importAudio == "library.importAudio")
        #expect(A11yID.Library.sortMenu == "library.sortMenu")
        #expect(A11yID.Library.filtersButton == "library.filtersButton")
    }

    @Test("Player identifiers are stable")
    func playerIDs() {
        #expect(A11yID.Player.bar == "player.bar")
        #expect(A11yID.Player.playPause == "player.playPause")
    }

    @Test("Settings identifiers are stable")
    func settingsIDs() {
        #expect(A11yID.Settings.button == "settings.button")
        #expect(A11yID.Settings.deleteAllData == "settings.deleteAllData")
    }
}
