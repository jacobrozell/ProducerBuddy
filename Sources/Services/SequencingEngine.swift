import Foundation

/// Describes how a track's energy moves relative to the track before it. The
/// app uses BPM as a proxy for energy: a faster track "rises", a slower one
/// "falls". The first track in a sequence has no predecessor so it "opens".
enum EnergyMove: String, Sendable {
    case opener
    case rise
    case fall
    case steady

    var displayName: String {
        switch self {
        case .opener: return "Opener"
        case .rise: return "Rise"
        case .fall: return "Fall"
        case .steady: return "Steady"
        }
    }

    var symbolName: String {
        switch self {
        case .opener: return "play.circle"
        case .rise: return "arrow.up.right"
        case .fall: return "arrow.down.right"
        case .steady: return "arrow.right"
        }
    }
}

/// The engine's read on a single track in the context of its neighbours.
struct FlowAnalysis: Identifiable, Sendable {
    let id: UUID
    let move: EnergyMove
    let bpmDelta: Int
    /// True when an adjacent track is a jarringly large BPM jump or a key clash.
    let hasWarning: Bool
    let warningText: String?
}

/// Pure, dependency-free logic for analysing and suggesting album/EP track
/// order. Kept free of SwiftData so it is trivially unit-testable.
enum SequencingEngine {
    /// A BPM jump larger than this between neighbours is flagged as abrupt.
    static let abruptBPMThreshold = 30
    /// BPM differences within this band are treated as "steady" rather than
    /// a rise or fall.
    static let steadyBPMBand = 4

    /// Classifies each track in `bpms` relative to the previous one.
    /// - Parameter bpms: BPM values in running order.
    /// - Returns: one `FlowAnalysis` per track, in the same order.
    static func analyze(bpms: [Int]) -> [FlowAnalysis] {
        var results: [FlowAnalysis] = []
        results.reserveCapacity(bpms.count)

        for (index, bpm) in bpms.enumerated() {
            guard index > 0 else {
                results.append(FlowAnalysis(id: UUID(), move: .opener, bpmDelta: 0, hasWarning: false, warningText: nil))
                continue
            }

            let previous = bpms[index - 1]
            let delta = bpm - previous
            let move: EnergyMove
            if abs(delta) <= steadyBPMBand {
                move = .steady
            } else if delta > 0 {
                move = .rise
            } else {
                move = .fall
            }

            let abrupt = abs(delta) >= abruptBPMThreshold
            let warning = abrupt
                ? "Big jump: \(abs(delta)) BPM from the previous track"
                : nil

            results.append(
                FlowAnalysis(id: UUID(), move: move, bpmDelta: delta, hasWarning: abrupt, warningText: warning)
            )
        }

        return results
    }

    /// Suggests a running order that builds energy gradually then eases off — a
    /// common album arc. Tracks are sorted by BPM ascending, then the top
    /// third (highest energy) is appended in descending order so the record
    /// peaks before its final wind-down.
    /// - Parameter songs: identifiers paired with their BPM.
    /// - Returns: the input identifiers reordered into the suggested sequence.
    static func suggestOrder<ID>(for songs: [(id: ID, bpm: Int)]) -> [ID] {
        guard songs.count > 2 else { return songs.map(\.id) }

        let ascending = songs.sorted { $0.bpm < $1.bpm }
        let peakCount = max(1, ascending.count / 3)
        let body = ascending.dropLast(peakCount)
        let peak = ascending.suffix(peakCount).reversed()

        return body.map(\.id) + peak.map(\.id)
    }
}
