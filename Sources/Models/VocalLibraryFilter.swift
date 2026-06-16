import Foundation

/// Library filter for vocal presence on the main song list.
enum VocalLibraryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case vocals = "With Vocals"
    case instrumental = "Instrumental"
    case uncertain = "Uncertain"

    var id: String { rawValue }

    var menuTitle: String {
        switch self {
        case .all: return "All Tracks"
        case .vocals: return "With Vocals"
        case .instrumental: return "Instrumental"
        case .uncertain: return "Uncertain"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .all: return "Show all tracks"
        case .vocals: return "Show tracks with vocals"
        case .instrumental: return "Show instrumental tracks"
        case .uncertain: return "Show tracks with uncertain vocal detection"
        }
    }

    var symbolName: String {
        switch self {
        case .all: return "music.note.list"
        case .vocals: return "mic.fill"
        case .instrumental: return "waveform"
        case .uncertain: return "questionmark.circle"
        }
    }
}
