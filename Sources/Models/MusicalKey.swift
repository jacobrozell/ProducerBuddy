import Foundation

/// A musical key used to tag songs. Helps with harmonic mixing and
/// sequencing decisions when ordering an album or EP.
enum MusicalKey: String, Codable, CaseIterable, Identifiable, Sendable {
    case unknown
    case cMajor, gMajor, dMajor, aMajor, eMajor, bMajor
    case fSharpMajor, dFlatMajor, aFlatMajor, eFlatMajor, bFlatMajor, fMajor
    case aMinor, eMinor, bMinor, fSharpMinor, cSharpMinor, gSharpMinor
    case dSharpMinor, bFlatMinor, fMinor, cMinor, gMinor, dMinor

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unknown: return "—"
        case .cMajor: return "C Major"
        case .gMajor: return "G Major"
        case .dMajor: return "D Major"
        case .aMajor: return "A Major"
        case .eMajor: return "E Major"
        case .bMajor: return "B Major"
        case .fSharpMajor: return "F♯ Major"
        case .dFlatMajor: return "D♭ Major"
        case .aFlatMajor: return "A♭ Major"
        case .eFlatMajor: return "E♭ Major"
        case .bFlatMajor: return "B♭ Major"
        case .fMajor: return "F Major"
        case .aMinor: return "A Minor"
        case .eMinor: return "E Minor"
        case .bMinor: return "B Minor"
        case .fSharpMinor: return "F♯ Minor"
        case .cSharpMinor: return "C♯ Minor"
        case .gSharpMinor: return "G♯ Minor"
        case .dSharpMinor: return "D♯ Minor"
        case .bFlatMinor: return "B♭ Minor"
        case .fMinor: return "F Minor"
        case .cMinor: return "C Minor"
        case .gMinor: return "G Minor"
        case .dMinor: return "D Minor"
        }
    }
}
