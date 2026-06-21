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
        #expect(A11yID.Settings.exportCatalog == "settings.exportCatalog")
        #expect(A11yID.Settings.importCatalog == "settings.importCatalog")
    }

    @Test("Song identifiers are stable")
    func songIDs() {
        #expect(A11yID.Song.versionStack == "song.versionStack")
        #expect(A11yID.Song.compare == "song.compare")
    }

    @Test("Split view placeholders are stable")
    func splitIDs() {
        #expect(A11yID.Split.selectSong == "split.selectSong")
        #expect(A11yID.Split.selectProject == "split.selectProject")
    }
}
