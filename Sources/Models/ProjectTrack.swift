import Foundation
import SwiftData

/// A positioned reference to a `Song` within a `Project`. Using a join model
/// (rather than a plain array of songs) lets the same song appear in multiple
/// projects and keeps an explicit, reorderable `position`.
@Model
final class ProjectTrack {
    var id: UUID
    /// Zero-based running order within the project.
    var position: Int

    var project: Project?
    var song: Song?

    init(id: UUID = UUID(), position: Int, song: Song? = nil) {
        self.id = id
        self.position = position
        self.song = song
    }
}
