import Foundation
import SwiftData
import Testing
@testable import MixStack

@Suite("Mix naming parser")
struct MixNamingParserTests {
    @Test("Parses master and version suffix")
    func parsesVersionSuffix() {
        let parsed = MixNamingParser.parse(basename: "NightDrive_v2_master")
        #expect(parsed.baseTitle == "NightDrive")
        #expect(parsed.versionLabel == "v2")
        #expect(parsed.suggestedRole == .master)
    }

    @Test("Parses FL project name")
    func flProject() {
        let parsed = MixNamingParser.parse(basename: "Project_7")
        #expect(parsed.baseTitle == "Project 7")
        #expect(parsed.suggestedRole == .original)
    }
}

@Suite("Export prefix validator")
struct ExportPrefixValidatorTests {
    @Test("Rejects reserved prefix")
    func reserved() {
        let result = ExportPrefixValidator.validate("beat_", existingSongs: [])
        #expect(!result.isValid)
    }

    @Test("Detects collision")
    func collision() {
        let song = Song(title: "A", exportPrefix: "NightDrive_")
        let result = ExportPrefixValidator.validate(
            "NightDrive_",
            excludingSongID: UUID(),
            existingSongs: [song]
        )
        #expect(!result.isValid)
    }
}

@Suite("Import matcher prefix")
struct ImportMatcherPrefixTests {
    @Test("Finds single prefix match")
  @MainActor
    func prefixMatch() {
        let song = Song(title: "Night Drive", exportPrefix: "NightDrive_")
        let match = ImportMatcher.findPrefixMatch(basename: "NightDrive_master", in: [song])
        #expect(match?.id == song.id)
    }

    @Test("Adds version when prefix matches on import")
    @MainActor
    func importAddsVersion() throws {
        let container = try ModelContainer(
            for: Song.self, Mix.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let existing = Song(title: "Night Drive", exportPrefix: "NightDrive_")
        context.insert(existing)
        try context.save()

        let audio = ImportedAudio(
            fileName: "x.m4a",
            duration: 120,
            title: nil,
            artist: nil,
            suggestedTitle: "NightDrive_master",
            sourceBasename: "NightDrive_master"
        )
        let outcome = SongImportService.importSongs([audio], into: context, scheduleBackgroundWork: false)
        #expect(outcome.newSongs == 0)
        #expect(outcome.addedVersions == 1)
        #expect(existing.mixes.count == 1)
        #expect(existing.mixes[0].role == .master)
    }
}
