import Foundation
import SwiftData

/// Read/write access to songs without tying callers to SwiftData details.
@MainActor
protocol SongRepository {
    func fetchAll() throws -> [Song]
    func fetchCount() throws -> Int
    func insert(_ song: Song)
    func delete(_ song: Song)
    func save() throws
}

/// SwiftData-backed song persistence used by the app shell and services.
struct SwiftDataSongRepository: SongRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Song] {
        try context.fetch(FetchDescriptor<Song>())
    }

    func fetchCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<Song>())
    }

    func insert(_ song: Song) {
        context.insert(song)
    }

    func delete(_ song: Song) {
        context.delete(song)
    }

    func save() throws {
        try context.save()
    }
}
