import Foundation
import SwiftData
import Testing
@testable import MixStack

@Suite("Import planner")
struct ImportPlannerTests {
    @Test("Auto-adds when single prefix matches")
    @MainActor
    func prefixAutoAdd() {
        let song = Song(title: "Night Drive", exportPrefix: "NightDrive_")
        song.normalizedTitle = "nightdrive"
        let audio = ImportedAudio(
            fileName: "x.m4a",
            duration: 120,
            title: nil,
            artist: nil,
            suggestedTitle: "NightDrive_master",
            sourceBasename: "NightDrive_master"
        )
        let plan = ImportPlanner.plan([audio], existing: [song])
        #expect(!plan.needsReview)
        #expect(plan.items.count == 1)
        if case .existingSong(let id) = plan.items[0].target {
            #expect(id == song.id)
        } else {
            Issue.record("Expected existing song target")
        }
    }

    @Test("Needs review when multiple prefix matches")
    @MainActor
    func multiplePrefixMatches() {
        let a = Song(title: "A", exportPrefix: "Beat_")
        let b = Song(title: "B", exportPrefix: "Beat_")
        let audio = ImportedAudio(
            fileName: "x.m4a",
            duration: 120,
            title: nil,
            artist: nil,
            suggestedTitle: "Beat_mix",
            sourceBasename: "Beat_mix"
        )
        let plan = ImportPlanner.plan([audio], existing: [a, b])
        #expect(plan.needsReview)
        #expect(plan.items[0].needsReview)
    }

    @Test("Needs review when duration differs with prefix match")
    @MainActor
    func durationMismatchReview() throws {
        let container = try ModelContainer(
            for: Song.self, Mix.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let song = Song(title: "Night Drive", exportPrefix: "NightDrive_")
        context.insert(song)
        let mix = Mix(name: "", fileName: "a.m4a", duration: 180, isPrimary: true)
        mix.song = song
        context.insert(mix)
        try context.save()

        let audio = ImportedAudio(
            fileName: "x.m4a",
            duration: 60,
            title: nil,
            artist: nil,
            suggestedTitle: "NightDrive_short",
            sourceBasename: "NightDrive_short"
        )
        let plan = ImportPlanner.plan([audio], existing: [song])
        #expect(plan.needsReview)
    }
}

@Suite("Song catalog organizer")
struct SongCatalogOrganizerTests {
    @Test("Assigns Project export prefix")
    @MainActor
    func assignsProjectPrefix() throws {
        let container = try ModelContainer(
            for: Song.self, Mix.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let song = Song(title: "Project 6")
        let mix = Mix(
            name: "",
            fileName: "p.m4a",
            duration: 120,
            isPrimary: true,
            sourceFileName: "Project_6"
        )
        mix.song = song
        context.insert(song)
        context.insert(mix)

        let result = SongCatalogOrganizer.assignMissingExportPrefixes([song])
        #expect(result == 1)
        #expect(song.exportPrefix == "Project_6_")
    }

    @Test("Merges duplicate version groups")
    @MainActor
    func mergesDuplicates() throws {
        let container = try ModelContainer(
            for: Song.self, Mix.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let older = Song(title: "Night Drive")
        older.normalizedTitle = "nightdrive"
        let newer = Song(title: "Night Drive v2")
        newer.normalizedTitle = "nightdrive"
        context.insert(older)
        context.insert(newer)

        let groups = SongCatalogOrganizer.findMergeGroups([older, newer])
        #expect(groups.count == 1)
        #expect(groups[0].sources.count == 1)

        let result = SongCatalogOrganizer.organize(songs: [older, newer], into: context)
        #expect(result.songsMerged == 1)
        let remaining = try context.fetch(FetchDescriptor<Song>())
        #expect(remaining.count == 1)
    }
}
