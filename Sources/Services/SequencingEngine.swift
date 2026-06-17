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

    /// Plain-language copy for the tap-to-explain badge popover.
    var explanation: String {
        switch self {
        case .opener:
            return "The first track — sets the tone with no prior tempo to compare."
        case .rise:
            return "Faster than the previous track — energy is building."
        case .fall:
            return "Slower than the previous track — energy is easing off."
        case .steady:
            return "About the same tempo as the previous track — a smooth handoff."
        }
    }
}

/// One track that would move when applying a suggested running order.
struct OrderMoveChange: Identifiable, Sendable {
    let id: UUID
    let title: String
    /// 1-based position in the current running order.
    let fromPosition: Int
    /// 1-based position in the suggested running order.
    let toPosition: Int
}

/// The engine's read on a single track in the context of its neighbours.
struct FlowAnalysis: Identifiable, Sendable {
    let id: UUID
    let move: EnergyMove
    let bpmDelta: Int
    /// True when this track is a jarringly large BPM jump from the previous one.
    let hasWarning: Bool
    let warningText: String?
    /// True when this track's key is not harmonically compatible with the
    /// previous track's (both keys known). Compatible neighbours make for
    /// smoother transitions; a clash is a heads-up, not a hard error.
    let keyClash: Bool
    let keyText: String?

    init(
        id: UUID = UUID(),
        move: EnergyMove,
        bpmDelta: Int,
        hasWarning: Bool,
        warningText: String?,
        keyClash: Bool = false,
        keyText: String? = nil
    ) {
        self.id = id
        self.move = move
        self.bpmDelta = bpmDelta
        self.hasWarning = hasWarning
        self.warningText = warningText
        self.keyClash = keyClash
        self.keyText = keyText
    }
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
                results.append(
                    FlowAnalysis(id: UUID(), move: .opener, bpmDelta: 0, hasWarning: false, warningText: nil)
                )
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

    /// Like `analyze(bpms:)` but also flags harmonic key clashes between
    /// neighbouring tracks. `keys` must line up with `bpms` by index.
    static func analyze(bpms: [Int], keys: [MusicalKey]) -> [FlowAnalysis] {
        let base = analyze(bpms: bpms)
        return base.enumerated().map { index, analysis in
            guard index > 0 else { return analysis }
            let previous = keys[index - 1]
            let current = keys[index]
            // Only judge when both keys are known.
            guard previous != .unknown, current != .unknown else { return analysis }

            let compatible = areHarmonicallyCompatible(previous, current)
            let text = compatible
                ? nil
                : "Key clash: \(previous.camelotCode ?? previous.displayName) → "
                    + "\(current.camelotCode ?? current.displayName)"

            return FlowAnalysis(
                id: analysis.id,
                move: analysis.move,
                bpmDelta: analysis.bpmDelta,
                hasWarning: analysis.hasWarning,
                warningText: analysis.warningText,
                keyClash: !compatible,
                keyText: text
            )
        }
    }

    /// Whether two keys mix smoothly under the Camelot wheel rules: same key,
    /// the relative major/minor (same number, opposite ring), or an adjacent
    /// number on the same ring (±1, wrapping 12↔1). Unknown keys never clash.
    static func areHarmonicallyCompatible(_ a: MusicalKey, _ b: MusicalKey) -> Bool {
        guard let ca = a.camelot, let cb = b.camelot else { return true }
        if ca.number == cb.number { return true } // same code or relative maj/min
        if ca.isMajor == cb.isMajor {
            let diff = abs(ca.number - cb.number)
            return diff == 1 || diff == 11 // neighbour on the ring, with wrap
        }
        return false
    }

    /// The index of the highest-BPM (peak-energy) track, or nil when empty. On
    /// ties the earliest peak wins, matching the "build to the first crest" read.
    static func peakIndex(bpms: [Int]) -> Int? {
        guard !bpms.isEmpty else { return nil }
        var best = 0
        for index in bpms.indices where bpms[index] > bpms[best] {
            best = index
        }
        return best
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

    /// Tracks that would change position when moving from the current order to
    /// `suggestedIDs`. Positions are 1-based for display.
    static func orderMoves<ID: Hashable>(
        from tracks: [(id: ID, title: String)],
        to suggestedIDs: [ID]
    ) -> [OrderMoveChange] {
        let currentIndex = Dictionary(uniqueKeysWithValues: tracks.enumerated().map { ($0.element.id, $0.offset) })
        var moves: [OrderMoveChange] = []

        for (newIndex, id) in suggestedIDs.enumerated() {
            guard let oldIndex = currentIndex[id], oldIndex != newIndex else { continue }
            guard let title = tracks.first(where: { $0.id == id })?.title else { continue }
            moves.append(
                OrderMoveChange(
                    id: UUID(),
                    title: title,
                    fromPosition: oldIndex + 1,
                    toPosition: newIndex + 1
                )
            )
        }

        return moves.sorted { $0.fromPosition < $1.fromPosition }
    }
}
