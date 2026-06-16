import Foundation
import SwiftUI

// swiftlint:disable inclusive_language
/// The production role of a mix render (rough, master, tagged, …).
enum MixRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case original
    case rough
    case arrangement
    case instrumental
    case tagged
    case master
    case reference
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .original: return "Original"
        case .rough: return "Rough"
        case .arrangement: return "Arrangement"
        case .instrumental: return "Instrumental"
        case .tagged: return "Tagged"
        case .master: return "Master"
        case .reference: return "Reference"
        case .other: return "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .original: return "waveform"
        case .rough: return "hammer"
        case .arrangement: return "slider.horizontal.2.square"
        case .instrumental: return "music.note"
        case .tagged: return "tag"
        case .master: return "checkmark.seal"
        case .reference: return "ear"
        case .other: return "ellipsis.circle"
        }
    }

    var tint: Color {
        switch self {
        case .original: return .gray
        case .rough: return .orange
        case .arrangement: return .purple
        case .instrumental: return .blue
        case .tagged: return .pink
        case .master: return .green
        case .reference: return .cyan
        case .other: return .secondary
        }
    }
}
// swiftlint:enable inclusive_language
