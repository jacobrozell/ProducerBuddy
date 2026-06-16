import Testing
import SwiftData
import Foundation
@testable import ProducerBuddy

@Suite("Models")
@MainActor
struct ModelTests {

    /// Builds an in-memory container so tests never touch disk.
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Song.self, Mix.self, Project.self, ProjectTrack.self,
            configurations: config
        )
        return ModelContext(container)
    }

    @Test("Song enum accessors round-trip through their raw storage")
    func songEnumAccessors() {
        let song = Song(title: "Test", bpm: 128, key: .aMinor, category: .readyToMix)
        #expect(song.key == .aMinor)
        #expect(song.category == .readyToMix)
        song.key = .cMajor
        song.category = .mastered
        #expect(song.keyRaw == MusicalKey.cMajor.rawValue)
        #expect(song.categoryRaw == SongCategory.mastered.rawValue)
    }

    @Test("Primary mix prefers the flagged mix")
    func primaryMixPrefersFlagged() throws {
        let context = try makeContext()
        let song = Song(title: "Track")
        context.insert(song)

        let a = Mix(name: "Rough", fileName: "a.m4a", dateAdded: .now)
        let b = Mix(name: "Master", fileName: "b.m4a", isPrimary: true, dateAdded: .now.addingTimeInterval(-100))
        a.song = song
        b.song = song
        context.insert(a)
        context.insert(b)

        #expect(song.primaryMix?.id == b.id)
    }

    @Test("Primary mix falls back to most recent when none flagged")
    func primaryMixFallsBack() throws {
        let context = try makeContext()
        let song = Song(title: "Track")
        context.insert(song)

        let older = Mix(name: "v1", fileName: "a.m4a", dateAdded: .now.addingTimeInterval(-200))
        let newer = Mix(name: "v2", fileName: "b.m4a", dateAdded: .now)
        older.song = song
        newer.song = song
        context.insert(older)
        context.insert(newer)

        #expect(song.primaryMix?.id == newer.id)
    }

    @Test("Project orders tracks by position regardless of insertion order")
    func projectOrdersTracks() throws {
        let context = try makeContext()
        let project = Project(title: "EP", kind: .ep)
        context.insert(project)

        let t2 = ProjectTrack(position: 2, song: Song(title: "C"))
        let t0 = ProjectTrack(position: 0, song: Song(title: "A"))
        let t1 = ProjectTrack(position: 1, song: Song(title: "B"))
        for t in [t2, t0, t1] {
            t.project = project
            context.insert(t)
        }

        let titles = project.orderedTracks.map { $0.song?.title }
        #expect(titles == ["A", "B", "C"])
    }

    @Test("Project total duration sums primary mix durations")
    func projectTotalDuration() throws {
        let context = try makeContext()
        let project = Project(title: "Album")
        context.insert(project)

        let song = Song(title: "Long")
        let mix = Mix(name: "Master", fileName: "m.m4a", duration: 180, isPrimary: true)
        mix.song = song
        context.insert(song)
        context.insert(mix)

        let track = ProjectTrack(position: 0, song: song)
        track.project = project
        context.insert(track)

        #expect(project.totalDuration == 180)
    }

    @Test("Mix formats duration as minutes and seconds")
    func mixFormatsDuration() {
        let mix = Mix(name: "x", fileName: "x.m4a", duration: 95)
        #expect(mix.formattedDuration == "1:35")
        let empty = Mix(name: "y", fileName: "y.m4a", duration: 0)
        #expect(empty.formattedDuration == "--:--")
    }
}
