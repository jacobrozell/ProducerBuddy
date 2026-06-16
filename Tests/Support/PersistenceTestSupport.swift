import Foundation
import SwiftData
@testable import MixStack

enum PersistenceTestSupport {
    static func makeTemporaryStoreURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MixStackTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("catalog.store")
    }

    static func makeContext(storeURL: URL) throws -> ModelContext {
        let container = try ModelContainerFactory.makeContainer(mode: .customURL(storeURL))
        return ModelContext(container)
    }

    @MainActor
    static func seedSampleCatalog(into context: ModelContext) throws {
        let song = Song(title: "Persistence Song", artist: "QA", bpm: 128, key: .cMajor)
        context.insert(song)

        let mix = Mix(name: "Take 1", fileName: "persist.m4a", duration: 210, isPrimary: true)
        mix.song = song
        context.insert(mix)

        let project = Project(title: "Persistence EP", kind: .ep)
        context.insert(project)

        let track = ProjectTrack(position: 0, song: song)
        track.project = project
        context.insert(track)

        try context.save()
    }
}
