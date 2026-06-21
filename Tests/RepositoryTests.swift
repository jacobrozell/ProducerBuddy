import SwiftData
import Testing
@testable import MixStack

@Suite("Repositories")
struct RepositoryTests {
    @Test("Song repository fetch and count")
    @MainActor
    func songRepositoryRoundTrip() throws {
        let container = try ModelContainer(
            for: Song.self, Mix.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let repo = SwiftDataSongRepository(context: context)

        #expect(try repo.fetchCount() == 0)

        let song = Song(title: "Test")
        repo.insert(song)
        try repo.save()

        #expect(try repo.fetchCount() == 1)
        #expect(try repo.fetchAll().first?.title == "Test")

        repo.delete(song)
        try repo.save()
        #expect(try repo.fetchCount() == 0)
    }

    @Test("Project repository fetch")
    @MainActor
    func projectRepositoryRoundTrip() throws {
        let container = try ModelContainer(
            for: Project.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let repo = SwiftDataProjectRepository(context: context)

        let project = Project(title: "Set")
        repo.insert(project)
        try repo.save()

        #expect(try repo.fetchAll().count == 1)
        #expect(try repo.fetchAll().first?.title == "Set")
    }
}
