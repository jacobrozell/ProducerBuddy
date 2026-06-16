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
    /// Defaults support lightweight migration for libraries created before vocal detection.
    var vocalPresenceRaw: String = VocalPresence.unknown.rawValue
    /// Auto-detect confidence in `0…1`, or `nil` when not analyzed / too ambiguous.
    var vocalConfidence: Double?
    /// When true, import and re-detect must not overwrite `vocalPresence`.
    var vocalPresenceIsManual: Bool = false
    /// Files whose basename starts with this prefix import as new versions. E.g. `NightDrive_`
    var exportPrefix: String = ""
    var exportPrefixIsManual: Bool = false
    /// Lowercased title stem used for import matching.
    var normalizedTitle: String = ""

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
        dateAdded: Date = .now,
        vocalPresence: VocalPresence = .unknown,
        vocalConfidence: Double? = nil,
        vocalPresenceIsManual: Bool = false,
        exportPrefix: String = "",
        exportPrefixIsManual: Bool = false
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
        self.vocalPresenceRaw = vocalPresence.rawValue
        self.vocalConfidence = vocalConfidence
        self.vocalPresenceIsManual = vocalPresenceIsManual
        self.exportPrefix = exportPrefix
        self.exportPrefixIsManual = exportPrefixIsManual
        self.normalizedTitle = MixNamingParser.normalize(title)
        self.mixes = []
        self.projectTracks = []
    }

    /// Updates title-derived fields after renames.
    func refreshNormalizedTitle() {
        normalizedTitle = MixNamingParser.normalize(title)
        if !exportPrefixIsManual, exportPrefix.isEmpty, VersionImportSettings.autoSuggestExportPrefix {
            exportPrefix = ExportPrefixSuggester.suggest(from: title)
        }
    }

    /// Mixes ordered for the version stack UI.
    var orderedMixes: [Mix] {
        mixes.sorted { a, b in
            if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
            return a.dateAdded > b.dateAdded
        }
    }

    var key: MusicalKey {
        get { MusicalKey(rawValue: keyRaw) ?? .unknown }
        set { keyRaw = newValue.rawValue }
    }

    var vocalPresence: VocalPresence {
        get { VocalPresence(rawValue: vocalPresenceRaw) ?? .unknown }
        set { vocalPresenceRaw = newValue.rawValue }
    }

    /// Applies auto-detected vocal metadata unless the user has set it manually.
    func applyDetectedVocals(_ vocal: VocalAnalysis) {
        guard !vocalPresenceIsManual else { return }
        vocalConfidence = vocal.confidence
        vocalPresence = vocal.presence
    }

    /// Whether the library should show a confident vocal/instrumental row icon.
    var hasConfidentVocalLabel: Bool {
        if vocalPresenceIsManual { return vocalPresence != .unknown }
        guard VocalDetectionThresholds.isLabeled(vocalConfidence) else { return false }
        return vocalPresence != .unknown
    }

    /// Matches the library's vocal filter chips.
    func matches(vocalFilter: VocalLibraryFilter) -> Bool {
        switch vocalFilter {
        case .all:
            return true
        case .vocals:
            if vocalPresenceIsManual { return vocalPresence == .vocals }
            return vocalPresence == .vocals
                && VocalDetectionThresholds.isLabeled(vocalConfidence)
        case .instrumental:
            if vocalPresenceIsManual { return vocalPresence == .instrumental }
            return vocalPresence == .instrumental
                && VocalDetectionThresholds.isLabeled(vocalConfidence)
        case .uncertain:
            guard !vocalPresenceIsManual else { return false }
            return VocalDetectionThresholds.isUncertain(vocalConfidence)
        }
    }

    var category: SongCategory {
        get { SongCategory(rawValue: categoryRaw) ?? .idea }
        set { categoryRaw = newValue.rawValue }
    }

    /// The mix marked as primary, or the most recently added one as a fallback.
    var primaryMix: Mix? {
        mixes.first(where: { $0.isPrimary }) ?? mixes.max(by: { $0.dateAdded < $1.dateAdded })
    }
}
