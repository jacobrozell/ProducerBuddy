import Testing
import Foundation
@testable import ProducerBuddy

@Suite("Audio Analyzer")
struct AudioAnalyzerTests {

    private let sampleRate = 11_025.0

    // MARK: Tempo

    /// A burst of energy every beat, like a metronome click track.
    private func clickTrack(bpm: Double, seconds: Double) -> [Float] {
        let count = Int(seconds * sampleRate)
        var samples = [Float](repeating: 0, count: count)
        let period = Int(60.0 / bpm * sampleRate)
        var i = 0
        while i < count {
            for j in i..<min(i + 128, count) { samples[j] = 1 }
            i += period
        }
        return samples
    }

    @Test("Detects the tempo of a 120 BPM click track")
    func detects120BPM() {
        let bpm = AudioAnalyzer.estimateBPM(samples: clickTrack(bpm: 120, seconds: 20), sampleRate: sampleRate)
        #expect(bpm != nil)
        if let bpm { #expect(abs(bpm - 120) <= 6) }
    }

    @Test("Detects the tempo of a 90 BPM click track")
    func detects90BPM() {
        let bpm = AudioAnalyzer.estimateBPM(samples: clickTrack(bpm: 90, seconds: 20), sampleRate: sampleRate)
        #expect(bpm != nil)
        if let bpm { #expect(abs(bpm - 90) <= 6) }
    }

    @Test("Silence has no detectable tempo")
    func silenceHasNoTempo() {
        let silence = [Float](repeating: 0, count: 20_000)
        #expect(AudioAnalyzer.estimateBPM(samples: silence, sampleRate: sampleRate) == nil)
    }

    // MARK: Key

    /// Sums sine tones at the given frequencies into one buffer.
    private func tones(_ freqs: [Double], seconds: Double) -> [Float] {
        let count = Int(seconds * sampleRate)
        var samples = [Float](repeating: 0, count: count)
        for f in freqs {
            let step = 2.0 * Double.pi * f / sampleRate
            for i in 0..<count {
                samples[i] += Float(sin(step * Double(i)))
            }
        }
        return samples
    }

    @Test("A C major triad reads as C major or its relative A minor")
    func detectsCMajorTriad() {
        // C4, E4, G4 — a C major chord.
        let key = AudioAnalyzer.estimateKey(samples: tones([261.63, 329.63, 392.00], seconds: 4), sampleRate: sampleRate)
        #expect(key != nil)
        if let key { #expect([.cMajor, .aMinor].contains(key)) }
    }

    @Test("Silence has no detectable key")
    func silenceHasNoKey() {
        let silence = [Float](repeating: 0, count: 20_000)
        #expect(AudioAnalyzer.estimateKey(samples: silence, sampleRate: sampleRate) == nil)
    }

    // MARK: Key mapping

    @Test("Pitch-class mapping produces the expected keys")
    func pitchClassMapping() {
        #expect(MusicalKey.from(pitchClass: 0, isMajor: true) == .cMajor)
        #expect(MusicalKey.from(pitchClass: 9, isMajor: false) == .aMinor)
        #expect(MusicalKey.from(pitchClass: 6, isMajor: true) == .fSharpMajor)
        // Wraps negative/overflowing pitch classes.
        #expect(MusicalKey.from(pitchClass: 12, isMajor: true) == .cMajor)
        #expect(MusicalKey.from(pitchClass: -1, isMajor: false) == .bMinor)
    }
}
