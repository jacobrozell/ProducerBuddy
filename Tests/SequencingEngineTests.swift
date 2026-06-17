import Testing
@testable import MixStack

@Suite("Sequencing Engine")
struct SequencingEngineTests {

    @Test("First track is always an opener")
    func firstTrackIsOpener() {
        let result = SequencingEngine.analyze(bpms: [120, 128])
        #expect(result.first?.move == .opener)
        #expect(result.first?.bpmDelta == 0)
    }

    @Test("A faster following track is a rise")
    func detectsRise() {
        let result = SequencingEngine.analyze(bpms: [100, 130])
        #expect(result[1].move == .rise)
        #expect(result[1].bpmDelta == 30)
    }

    @Test("A slower following track is a fall")
    func detectsFall() {
        let result = SequencingEngine.analyze(bpms: [140, 100])
        #expect(result[1].move == .fall)
        #expect(result[1].bpmDelta == -40)
    }

    @Test("Near-equal BPMs are steady, not a rise or fall")
    func smallChangeIsSteady() {
        let result = SequencingEngine.analyze(bpms: [120, 122])
        #expect(result[1].move == .steady)
    }

    @Test("Large BPM jumps raise a warning")
    func abruptJumpWarns() {
        let result = SequencingEngine.analyze(bpms: [90, 160])
        #expect(result[1].hasWarning)
        #expect(result[1].warningText != nil)
    }

    @Test("Modest changes do not warn")
    func modestChangeNoWarning() {
        let result = SequencingEngine.analyze(bpms: [120, 135])
        #expect(result[1].hasWarning == false)
    }

    @Test("Empty input yields no analyses")
    func emptyInput() {
        #expect(SequencingEngine.analyze(bpms: []).isEmpty)
    }

    @Test("Analysis count matches input count")
    func countMatches() {
        let bpms = [120, 124, 130, 110, 95]
        #expect(SequencingEngine.analyze(bpms: bpms).count == bpms.count)
    }

    @Test("Suggested order keeps every track exactly once")
    func suggestOrderIsPermutation() {
        let songs = [(id: 1, bpm: 120), (id: 2, bpm: 90), (id: 3, bpm: 140), (id: 4, bpm: 100)]
        let order = SequencingEngine.suggestOrder(for: songs)
        #expect(Set(order) == Set([1, 2, 3, 4]))
        #expect(order.count == 4)
    }

    @Test("Suggested order builds up then peaks at the end")
    func suggestOrderHasArc() {
        let songs = [(id: "a", bpm: 80), (id: "b", bpm: 100), (id: "c", bpm: 120), (id: "d", bpm: 160)]
        let order = SequencingEngine.suggestOrder(for: songs)
        // Lowest-energy track opens the record.
        #expect(order.first == "a")
        // Highest-energy track lands at the peak (last).
        #expect(order.last == "d")
    }

    @Test("Two or fewer tracks are returned unchanged")
    func tooFewTracksUnchanged() {
        let songs = [(id: 1, bpm: 100), (id: 2, bpm: 130)]
        #expect(SequencingEngine.suggestOrder(for: songs) == [1, 2])
    }

    @Test("Peak index points at the highest-BPM track")
    func peakIndexFindsMax() {
        #expect(SequencingEngine.peakIndex(bpms: [100, 140, 120]) == 1)
    }

    @Test("Peak index returns the earliest track on a tie")
    func peakIndexEarliestOnTie() {
        #expect(SequencingEngine.peakIndex(bpms: [130, 110, 130]) == 0)
    }

    @Test("Peak index of an empty tracklist is nil")
    func peakIndexEmpty() {
        #expect(SequencingEngine.peakIndex(bpms: []) == nil)
    }

    // MARK: Harmonic mixing

    @Test("A key is compatible with itself")
    func sameKeyCompatible() {
        #expect(SequencingEngine.areHarmonicallyCompatible(.aMinor, .aMinor))
    }

    @Test("Relative major/minor are compatible (same Camelot number)")
    func relativeKeysCompatible() {
        // A minor (8A) ↔ C major (8B)
        #expect(SequencingEngine.areHarmonicallyCompatible(.aMinor, .cMajor))
    }

    @Test("Adjacent keys on the same ring are compatible")
    func adjacentRingCompatible() {
        // A minor (8A) ↔ E minor (9A)
        #expect(SequencingEngine.areHarmonicallyCompatible(.aMinor, .eMinor))
    }

    @Test("Compatibility wraps around the wheel (12 ↔ 1)")
    func ringWrapsAround() {
        // G♯ minor (1A) ↔ C♯ minor (12A)
        #expect(SequencingEngine.areHarmonicallyCompatible(.gSharpMinor, .cSharpMinor))
    }

    @Test("Distant keys clash")
    func distantKeysClash() {
        // C major (8B) ↔ D major (10B) is two steps apart
        #expect(SequencingEngine.areHarmonicallyCompatible(.cMajor, .dMajor) == false)
    }

    @Test("Unknown keys never clash")
    func unknownNeverClashes() {
        #expect(SequencingEngine.areHarmonicallyCompatible(.unknown, .dMajor))
        #expect(SequencingEngine.areHarmonicallyCompatible(.cMajor, .unknown))
    }

    @Test("Key-aware analysis flags a clash on the offending track")
    func analysisFlagsKeyClash() {
        let result = SequencingEngine.analyze(bpms: [120, 122], keys: [.cMajor, .dMajor])
        #expect(result[0].keyClash == false) // opener
        #expect(result[1].keyClash)
        #expect(result[1].keyText != nil)
    }

    @Test("Order moves lists only tracks that change position")
    func orderMovesListsChanges() {
        let tracks = [
            (id: 1, title: "A"),
            (id: 2, title: "B"),
            (id: 3, title: "C")
        ]
        let moves = SequencingEngine.orderMoves(from: tracks, to: [2, 1, 3])
        #expect(moves.count == 2)
        #expect(moves.contains { $0.title == "A" && $0.fromPosition == 1 && $0.toPosition == 2 })
        #expect(moves.contains { $0.title == "B" && $0.fromPosition == 2 && $0.toPosition == 1 })
    }

    @Test("Order moves is empty when the order is unchanged")
    func orderMovesEmptyWhenUnchanged() {
        let tracks = [(id: 1, title: "A"), (id: 2, title: "B"), (id: 3, title: "C")]
        #expect(SequencingEngine.orderMoves(from: tracks, to: [1, 2, 3]).isEmpty)
    }
}
