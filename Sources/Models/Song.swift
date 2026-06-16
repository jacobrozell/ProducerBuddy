import Foundation
import SwiftData

/// A single piece of music in the user's library. A song can have multiple
/// `Mix` versions and can belong to many `Project`s.
@Model
final class Song {
    var id: UUID
    var title: String
    var artist: String
    var genre: String
    /// Beats per minute. Used by the sequencing engine to suggest track order.
    var bpm: Int
    var keyRaw: String
    var categoryRaw: String
    var rating: Int
    var notes: String
    var isFavorite: Bool
    var dateAdded: Date

    /// All mix versions for this song. Deleting the song deletes its mixes.
    @Relationship(deleteRule: .cascade, inverse: \Mix.song)
    var mixes: [Mix]

    /// Project tracks that reference this song.
    @Relationship(deleteRule: .cascade, inverse: \ProjectTrack.song)
    var projectTracks: [ProjectTrack]

    init(
        id: UUID = UUID(),
        title: String,
        artist: String = "",
        genre: String = "",
        bpm: Int = 120,
        key: MusicalKey = .unknown,
        category: SongCategory = .idea,
        rating: Int = 0,
        notes: String = "",
        isFavorite: Bool = false,
        dateAdded: Date = .now
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.genre = genre
        self.bpm = bpm
        self.keyRaw = key.rawValue
        self.categoryRaw = category.rawValue
        self.rating = rating
        self.notes = notes
        self.isFavorite = isFavorite
        self.dateAdded = dateAdded
        self.mixes = []
        self.projectTracks = []
    }

    var key: MusicalKey {
        get { MusicalKey(rawValue: keyRaw) ?? .unknown }
        set { keyRaw = newValue.rawValue }
    }

    var category: SongCategory {
        get { SongCategory(rawValue: categoryRaw) ?? .idea }
        set { categoryRaw = newValue.rawValue }
    }

    /// The mix marked as primary, or the most recently added one as a fallback.
    var primaryMix: Mix? {
        mixes.first(where: { $0.isPrimary }) ?? mixes.sorted(by: { $0.dateAdded > $1.dateAdded }).first
    }
}
