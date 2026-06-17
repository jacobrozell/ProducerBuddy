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
    /// Cached, normalized (0–1) waveform peaks for quick drawing. Empty until
    /// generated; computed once at import and reused thereafter.
    var waveform: [Float]
    var roleRaw: String = MixRole.original.rawValue
    var sourceFileName: String?
    var versionLabel: String?
    var sortOrder: Int = 0
    /// Cached integrated loudness estimate (LUFS), nil until analyzed.
    var integratedLUFS: Double?
    var loudnessAnalyzedAt: Date?

    var song: Song?

    init(
        id: UUID = UUID(),
        name: String,
        fileName: String,
        duration: Double = 0,
        notes: String = "",
        isPrimary: Bool = false,
        dateAdded: Date = .now,
        waveform: [Float] = [],
        role: MixRole = .original,
        sourceFileName: String? = nil,
        versionLabel: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.duration = duration
        self.notes = notes
        self.isPrimary = isPrimary
        self.dateAdded = dateAdded
        self.waveform = waveform
        self.roleRaw = role.rawValue
        self.sourceFileName = sourceFileName
        self.versionLabel = versionLabel
        self.sortOrder = sortOrder
    }

    var role: MixRole {
        get { MixRole(rawValue: roleRaw) ?? .original }
        set { roleRaw = newValue.rawValue }
    }

    var hasWaveform: Bool { !waveform.isEmpty }

    /// User-facing label: custom name when set, otherwise role + version.
    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, !isGenericName(trimmed) {
            return trimmed
        }
        if let versionLabel, !versionLabel.isEmpty {
            return "\(role.displayName) \(versionLabel)"
        }
        return role.displayName
    }

    private func isGenericName(_ value: String) -> Bool {
        let lower = value.lowercased()
        return lower == "original" || lower.hasPrefix("mix ")
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
