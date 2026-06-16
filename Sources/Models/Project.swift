import Foundation
import SwiftData

/// The kind of release a `Project` represents. Affects nothing functionally but
/// gives the user a sense of scope and is shown in the UI.
enum ProjectKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case single
    case ep
    case album
    case mixtape

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .single: return "Single"
        case .ep: return "EP"
        case .album: return "Album"
        case .mixtape: return "Mixtape"
        }
    }
}

/// A collection of songs the user is sequencing into a release. Tracks are held
/// in an ordered list via `ProjectTrack` so the user can drag to reorder and get
/// flow suggestions from the sequencing engine.
@Model
final class Project {
    var id: UUID
    var title: String
    var subtitle: String
    var kindRaw: String
    var notes: String
    var dateCreated: Date

    @Relationship(deleteRule: .cascade, inverse: \ProjectTrack.project)
    var tracks: [ProjectTrack]

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String = "",
        kind: ProjectKind = .album,
        notes: String = "",
        dateCreated: Date = .now
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.kindRaw = kind.rawValue
        self.notes = notes
        self.dateCreated = dateCreated
        self.tracks = []
    }

    var kind: ProjectKind {
        get { ProjectKind(rawValue: kindRaw) ?? .album }
        set { kindRaw = newValue.rawValue }
    }

    /// Tracks in their user-defined running order.
    var orderedTracks: [ProjectTrack] {
        tracks.sorted { $0.position < $1.position }
    }

    /// Total runtime of all tracks, using each song's primary mix duration.
    var totalDuration: Double {
        orderedTracks.reduce(0) { $0 + ($1.song?.primaryMix?.duration ?? 0) }
    }
}
