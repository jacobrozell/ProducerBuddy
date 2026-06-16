import Foundation
import SwiftData

/// Seeds a minimal catalog for UI smoke tests (no audio files required).
enum UITestDataSeeder {
    static let songTitle = "UITest Song"
    static let projectTitle = "UITest EP"

    @MainActor
    static func seedIfEmpty(into context: ModelContext) {
        let songCount = (try? context.fetchCount(FetchDescriptor<Song>())) ?? 0
        guard songCount == 0 else { return }

        let song = Song(title: songTitle, artist: "MixStack QA", bpm: 120, key: .aMinor, category: .readyToMix)
        context.insert(song)

        let mix = Mix(name: "Master", fileName: "uitest-master.m4a", duration: 180, isPrimary: true)
        mix.song = song
        context.insert(mix)

        let project = Project(title: projectTitle, subtitle: "Smoke test project", kind: .ep)
        context.insert(project)

        let track = ProjectTrack(position: 0, song: song)
        track.project = project
        context.insert(track)

        try? context.save()
    }
}
