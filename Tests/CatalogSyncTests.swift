import Foundation
import SwiftData
import Testing
@testable import MixStack

@Suite("Catalog sync", .tags(.regression))
@MainActor
struct CatalogSyncTests {
    private static let alphaSongID = UUID(uuidString: "A1000001-0000-4000-8000-000000000001")!
    private static let betaSongID = UUID(uuidString: "A1000001-0000-4000-8000-000000000002")!
    private static let projectID = UUID(uuidString: "A1000001-0000-4000-8000-000000000003")!
    private static let mixAlphaID = UUID(uuidString: "A1000001-0000-4000-8000-000000000004")!
    private static let mixBetaID = UUID(uuidString: "A1000001-0000-4000-8000-000000000005")!

    @Test("Export and merge import round-trip preserves counts")
    func roundTripMerge() throws {
        let sourceURL = try PersistenceTestSupport.makeTemporaryStoreURL()
        let sourceContext = try PersistenceTestSupport.makeContext(storeURL: sourceURL)
        try seedCatalogWithAudio(into: sourceContext)

        let zipURL = try CatalogExporter.export(from: sourceContext)

        let destinationURL = try PersistenceTestSupport.makeTemporaryStoreURL()
        let destinationContext = try PersistenceTestSupport.makeContext(storeURL: destinationURL)
        let player = AudioPlayer()

        let counts = try CatalogImporter.importBundle(
            from: zipURL,
            mode: .merge,
            into: destinationContext,
            audioPlayer: player
        )

        #expect(counts.songs == 2)
        #expect(counts.projects == 1)

        let songs = try destinationContext.fetch(FetchDescriptor<Song>())
        let projects = try destinationContext.fetch(FetchDescriptor<Project>())
        #expect(songs.count == 2)
        #expect(projects.count == 1)
        #expect(songs.contains { $0.title == "Catalog Alpha" })
        #expect(songs.contains { $0.title == "Catalog Beta" })
    }

    @Test("Merge skips songs that already exist")
    func mergeSkipsDuplicateIDs() throws {
        let sourceURL = try PersistenceTestSupport.makeTemporaryStoreURL()
        let sourceContext = try PersistenceTestSupport.makeContext(storeURL: sourceURL)
        try seedCatalogWithAudio(into: sourceContext)
        let zipURL = try CatalogExporter.export(from: sourceContext)

        let destinationURL = try PersistenceTestSupport.makeTemporaryStoreURL()
        let destinationContext = try PersistenceTestSupport.makeContext(storeURL: destinationURL)
        try seedCatalogWithAudio(into: destinationContext)

        let player = AudioPlayer()
        let counts = try CatalogImporter.importBundle(
            from: zipURL,
            mode: .merge,
            into: destinationContext,
            audioPlayer: player
        )

        #expect(counts.songs == 0)
        #expect(counts.projects == 0)
        let songs = try destinationContext.fetch(FetchDescriptor<Song>())
        #expect(songs.count == 2)
    }

    private func seedCatalogWithAudio(into context: ModelContext) throws {
        let alphaFile = try writeDummyAudio(named: "alpha.m4a")
        let betaFile = try writeDummyAudio(named: "beta.m4a")

        let alpha = Song(id: Self.alphaSongID, title: "Catalog Alpha", artist: "QA")
        let beta = Song(id: Self.betaSongID, title: "Catalog Beta", artist: "QA")
        context.insert(alpha)
        context.insert(beta)

        let mixAlpha = Mix(
            id: Self.mixAlphaID,
            name: "Original",
            fileName: alphaFile,
            duration: 30,
            isPrimary: true
        )
        mixAlpha.song = alpha
        context.insert(mixAlpha)

        let mixBeta = Mix(
            id: Self.mixBetaID,
            name: "Original",
            fileName: betaFile,
            duration: 45,
            isPrimary: true
        )
        mixBeta.song = beta
        context.insert(mixBeta)

        let project = Project(id: Self.projectID, title: "Catalog EP", kind: .ep)
        context.insert(project)

        let track = ProjectTrack(position: 0, song: alpha)
        track.project = project
        context.insert(track)

        try context.save()
    }

    private func writeDummyAudio(named fileName: String) throws -> String {
        let url = AudioStorage.audioDirectory.appendingPathComponent(fileName)
        let data = Data("dummy-audio".utf8)
        try data.write(to: url, options: .atomic)
        return fileName
    }
}
