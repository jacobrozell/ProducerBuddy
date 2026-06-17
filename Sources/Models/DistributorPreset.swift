import Foundation

/// Preset distributor names for release tracking.
enum DistributorPreset: String, CaseIterable, Identifiable, Sendable {
    case none = ""
    case distroKid = "DistroKid"
    case tuneCore = "TuneCore"
    case amuse = "Amuse"
    case cdBaby = "CD Baby"
    case other = "Other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .other: return "Other"
        default: return rawValue
        }
    }
}
