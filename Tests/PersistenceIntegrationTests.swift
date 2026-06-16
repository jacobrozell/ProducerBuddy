import Foundation
import SwiftData
import Testing
@testable import MixStack

@Suite("Persistence integration", .tags(.regression, .releaseGate))
@MainActor
struct PersistenceIntegrationTests {
    @Test("Catalog survives simulated relaunch on disk")
    func relaunchPreservesCatalog() throws {
        let storeURL = try PersistenceTestSupport.makeTemporaryStoreURL()

        let firstContext = try PersistenceTestSupport.makeContext(storeURL: storeURL)
        try PersistenceTestSupport.seedSampleCatalog(into: firstContext)

        let relaunchContext = try PersistenceTestSupport.makeContext(storeURL: storeURL)
        let songs = try relaunchContext.fetch(FetchDescriptor<Song>())
        let projects = try relaunchContext.fetch(FetchDescriptor<Project>())

        #expect(songs.count == 1)
        #expect(songs.first?.title == "Persistence Song")
        #expect(songs.first?.mixes.count == 1)
        #expect(projects.count == 1)
        #expect(projects.first?.title == "Persistence EP")
        #expect(projects.first?.tracks.count == 1)
    }

    @Test("UITest catalog seeder is idempotent")
    func uiTestSeederIdempotent() throws {
        let storeURL = try PersistenceTestSupport.makeTemporaryStoreURL()
        let context = try PersistenceTestSupport.makeContext(storeURL: storeURL)

        UITestDataSeeder.seedIfEmpty(into: context)
        UITestDataSeeder.seedIfEmpty(into: context)

        let songs = try context.fetch(FetchDescriptor<Song>())
        let projects = try context.fetch(FetchDescriptor<Project>())
        #expect(songs.count == 1)
        #expect(songs.first?.title == UITestDataSeeder.songTitle)
        #expect(projects.count == 1)
        #expect(projects.first?.title == UITestDataSeeder.projectTitle)
    }
}
