import Foundation
import SwiftData

/// A specific audio render/version of a `Song` (e.g. "Rough Mix", "Master v2").
/// The audio file is copied into the app's documents directory and referenced
/// by its relative filename so it survives across launches.
@Model
final class Mix {
    var id: UUID
    var name: String
    /// Filename relative to the app's audio storage directory.
    var fileName: String
    /// Duration in seconds, cached at import time.
    var duration: Double
    var notes: String
    /// Marks the mix the user considers the "current best" version.
    var isPrimary: Bool
    var dateAdded: Date

    var song: Song?

    init(
        id: UUID = UUID(),
        name: String,
        fileName: String,
        duration: Double = 0,
        notes: String = "",
        isPrimary: Bool = false,
        dateAdded: Date = .now
    ) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.duration = duration
        self.notes = notes
        self.isPrimary = isPrimary
        self.dateAdded = dateAdded
    }

    /// Resolved absolute URL of the audio file in the app's storage directory.
    var fileURL: URL {
        AudioStorage.audioDirectory.appendingPathComponent(fileName)
    }

    var formattedDuration: String {
        guard duration > 0 else { return "--:--" }
        let total = Int(duration.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
