import Foundation
import SwiftData
import Testing
@testable import MixStack

@Suite("Song import service")
struct SongImportServiceTests {
    @Test("Creates a song and primary mix per imported file")
    @MainActor
    func createsSongAndMix() throws {
        let container = try ModelContainer(
            for: Song.self, Mix.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let audio = ImportedAudio(
            fileName: "test.m4a",
            duration: 180,
            title: "Test Title",
            artist: "Test Artist",
            suggestedTitle: "Test Title",
            sourceBasename: "Test Title"
        )

        let outcome = SongImportService.importSongs([audio], into: context, scheduleBackgroundWork: false)

        let songs = try context.fetch(FetchDescriptor<Song>())
        #expect(outcome.newSongs == 1)
        #expect(outcome.addedVersions == 0)
        #expect(songs.count == 1)
        #expect(songs[0].title == "Test Title")
        #expect(songs[0].artist == "Test Artist")
        #expect(songs[0].mixes.count == 1)
        #expect(songs[0].mixes[0].isPrimary)
        #expect(songs[0].mixes[0].duration == 180)
    }
}

@Suite("Demo audio seeder", .serialized)
struct DemoAudioSeederTests {
    @Test("Launch argument constant matches seed flag")
    func seedArgument() {
        #expect(DemoAudioSeeder.seedLaunchArgument == "-seed_demo_tracks")
    }

    @Test("Creates a demo EP when the library has songs")
    @MainActor
    func createsDemoProject() throws {
        let container = try ModelContainer(
            for: Song.self, Mix.self, Project.self, ProjectTrack.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let songA = Song(title: "Alpha")
        let songB = Song(title: "Beta")
        context.insert(songA)
        context.insert(songB)
        let mixA = Mix(name: "Original", fileName: "a.m4a", duration: 60, isPrimary: true)
        mixA.song = songA
        let mixB = Mix(name: "Original", fileName: "b.m4a", duration: 90, isPrimary: true)
        mixB.song = songB
        context.insert(mixA)
        context.insert(mixB)

        DemoAudioSeeder.createDemoProjectIfNeeded(into: context)
        try context.save()

        let projects = try context.fetch(FetchDescriptor<Project>())
        #expect(projects.count == 1)
        #expect(projects[0].title == "Demo EP")
        #expect(projects[0].tracks.count == 2)
        #expect(projects[0].orderedTracks[0].song?.title == "Alpha")
    }
}
