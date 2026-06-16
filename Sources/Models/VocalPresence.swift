import Foundation

/// Shared confidence cutoffs for vocal detection across analysis, storage, and UI.
enum VocalDetectionThresholds {
    static let minimum = 0.35
    static let labeled = 0.65
    static let strong = 0.85

    static func isLabeled(_ confidence: Double?) -> Bool {
        (confidence ?? 0) >= labeled
    }

    static func isUncertain(_ confidence: Double?) -> Bool {
        guard let confidence else { return false }
        return confidence >= minimum && confidence < labeled
    }
}

/// Whether a song's primary mix contains prominent vocals, as detected or set
/// by the user.
enum VocalPresence: String, Codable, CaseIterable, Identifiable, Sendable {
    case unknown
    case instrumental
    case vocals

    var id: String { rawValue }

    /// Detail and list display.
    var displayName: String {
        switch self {
        case .unknown: return "Not analyzed"
        case .instrumental: return "Instrumental"
        case .vocals: return "With Vocals"
        }
    }

    /// Editor picker label.
    var pickerName: String {
        switch self {
        case .unknown: return "Unknown"
        case .instrumental: return "Instrumental"
        case .vocals: return "With Vocals"
        }
    }

    /// Short label for compact badges.
    var shortName: String {
        switch self {
        case .unknown: return "—"
        case .instrumental: return "Inst."
        case .vocals: return "Vocals"
        }
    }

    var symbolName: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .instrumental: return "waveform"
        case .vocals: return "mic.fill"
        }
    }
}
