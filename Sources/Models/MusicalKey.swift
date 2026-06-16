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

    /// Position on the Camelot wheel used for harmonic-mixing compatibility.
    /// `number` is 1–12 and `isMajor` distinguishes the B (major) ring from the
    /// A (minor) ring. `nil` for `.unknown`.
    var camelot: (number: Int, isMajor: Bool)? {
        switch self {
        case .unknown: return nil
        // Major ring (B)
        case .cMajor: return (8, true)
        case .gMajor: return (9, true)
        case .dMajor: return (10, true)
        case .aMajor: return (11, true)
        case .eMajor: return (12, true)
        case .bMajor: return (1, true)
        case .fSharpMajor: return (2, true)
        case .dFlatMajor: return (3, true)
        case .aFlatMajor: return (4, true)
        case .eFlatMajor: return (5, true)
        case .bFlatMajor: return (6, true)
        case .fMajor: return (7, true)
        // Minor ring (A)
        case .aMinor: return (8, false)
        case .eMinor: return (9, false)
        case .bMinor: return (10, false)
        case .fSharpMinor: return (11, false)
        case .cSharpMinor: return (12, false)
        case .gSharpMinor: return (1, false)
        case .dSharpMinor: return (2, false)
        case .bFlatMinor: return (3, false)
        case .fMinor: return (4, false)
        case .cMinor: return (5, false)
        case .gMinor: return (6, false)
        case .dMinor: return (7, false)
        }
    }

    /// Short Camelot code (e.g. "8A", "11B"), or nil when unknown.
    var camelotCode: String? {
        guard let c = camelot else { return nil }
        return "\(c.number)\(c.isMajor ? "B" : "A")"
    }

    /// Builds a key from a chromatic pitch class (0 = C, 1 = C♯/D♭, … 11 = B)
    /// and a mode. Used by the audio analyzer to turn a detected tonic into a
    /// concrete `MusicalKey`.
    static func from(pitchClass: Int, isMajor: Bool) -> MusicalKey {
        let major: [MusicalKey] = [
            .cMajor, .dFlatMajor, .dMajor, .eFlatMajor, .eMajor, .fMajor,
            .fSharpMajor, .gMajor, .aFlatMajor, .aMajor, .bFlatMajor, .bMajor
        ]
        let minor: [MusicalKey] = [
            .cMinor, .cSharpMinor, .dMinor, .dSharpMinor, .eMinor, .fMinor,
            .fSharpMinor, .gMinor, .gSharpMinor, .aMinor, .bFlatMinor, .bMinor
        ]
        let pc = ((pitchClass % 12) + 12) % 12
        return isMajor ? major[pc] : minor[pc]
    }

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
