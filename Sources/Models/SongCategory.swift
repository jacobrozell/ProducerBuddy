import Foundation
import SwiftUI

// swiftlint:disable inclusive_language
/// The stage a song is at in the producer's workflow. Lets the user sort and
/// filter their library by how "done" a track is.
enum SongCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case idea
    case demo
    case workInProgress
    case readyToMix
    case mastered
    case released

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .idea: return "Idea"
        case .demo: return "Demo"
        case .workInProgress: return "Work in Progress"
        case .readyToMix: return "Ready to Mix"
        case .mastered: return "Mastered"
        case .released: return "Released"
        }
    }

    var symbolName: String {
        switch self {
        case .idea: return "lightbulb"
        case .demo: return "waveform"
        case .workInProgress: return "hammer"
        case .readyToMix: return "slider.horizontal.3"
        case .mastered: return "checkmark.seal"
        case .released: return "globe"
        }
    }

    var tint: Color {
        switch self {
        case .idea: return .yellow
        case .demo: return .orange
        case .workInProgress: return .blue
        case .readyToMix: return .purple
        case .mastered: return .green
        case .released: return .pink
        }
    }
}
// swiftlint:enable inclusive_language
