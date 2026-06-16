import Testing
import Foundation
@testable import MixStack

@Suite("Vocal Detection", .serialized)
struct VocalDetectionTests {

    private let sampleRate = 11_025.0

    // MARK: - Fixtures

    private func steadyTone(frequency: Double, seconds: Double) -> [Float] {
        let count = Int(seconds * sampleRate)
        return (0..<count).map { index in
            Float(sin(2 * Double.pi * frequency * Double(index) / sampleRate))
        }
    }

    /// AM-modulated multi-tone energy in the vocal band, proxying speech-like content.
    private func modulatedVocalBand(seconds: Double) -> [Float] {
        let count = Int(seconds * sampleRate)
        var samples = [Float](repeating: 0, count: count)
        let carriers = [350.0, 700.0, 1_100.0, 1_800.0, 2_600.0]
        let modRate = 4.5
        for index in 0..<count {
            let time = Double(index) / sampleRate
            let syllable = 0.5 + 0.5 * sin(2 * Double.pi * 2.2 * time)
            let envelope = (0.2 + 0.8 * (0.5 + 0.5 * sin(2 * Double.pi * modRate * time))) * syllable
            var sample = 0.0
            for (offset, frequency) in carriers.enumerated() {
                sample += sin(2 * Double.pi * frequency * time + Double(offset) * 0.6)
            }
            sample /= Double(carriers.count)
            let noise = sin(2 * Double.pi * 811 * time)
                + sin(2 * Double.pi * 1_433 * time)
                + sin(2 * Double.pi * 2_177 * time)
                + sin(2 * Double.pi * 3_019 * time)
            samples[index] = Float((sample + 0.45 * noise) * envelope)
        }
        return samples
    }

    // MARK: - Tests

    @Test("Silence has no vocal detection result")
    func silenceIsUnknown() {
        let silence = [Float](repeating: 0, count: 20_000)
        let result = AudioAnalyzer.estimateVocalPresence(samples: silence, sampleRate: sampleRate)
        #expect(result.presence == .unknown)
        #expect(result.confidence == nil)
    }

    @Test("Short audio is too short to analyze")
    func shortAudioIsUnknown() {
        let short = steadyTone(frequency: 220, seconds: 0.5)
        let result = AudioAnalyzer.estimateVocalPresence(samples: short, sampleRate: sampleRate)
        #expect(result.presence == .unknown)
        #expect(result.confidence == nil)
    }

    @Test("Steady low pad reads as instrumental with high confidence")
    func steadyPadIsInstrumental() {
        let pad = steadyTone(frequency: 110, seconds: 12)
        let result = AudioAnalyzer.estimateVocalPresence(samples: pad, sampleRate: sampleRate)
        #expect(result.presence == .instrumental)
        #expect((result.confidence ?? 0) >= VocalDetectionThresholds.labeled)
    }

    @Test("Modulated vocal-band signal reads as vocals")
    func modulatedBandReadsAsVocals() {
        let vocalish = modulatedVocalBand(seconds: 12)
        let result = AudioAnalyzer.estimateVocalPresence(samples: vocalish, sampleRate: sampleRate)
        #expect(result.presence == .vocals)
        #expect((result.confidence ?? 0) >= 0.5)
    }

    @Test("Manual vocal presence blocks auto-apply")
    func manualPresenceIsRespected() {
        let song = Song(title: "Locked", vocalPresence: .vocals, vocalPresenceIsManual: true)
        song.applyDetectedVocals(VocalAnalysis(presence: .instrumental, confidence: 0.9))
        #expect(song.vocalPresence == .vocals)
        #expect(song.vocalPresenceIsManual)
    }

    @Test("Library vocal filters bucket songs correctly")
    func vocalFilters() {
        let confidentBeat = Song(
            title: "Beat",
            vocalPresence: .instrumental,
            vocalConfidence: 0.8
        )
        let uncertain = Song(
            title: "Maybe",
            vocalPresence: .unknown,
            vocalConfidence: 0.5
        )
        let manualVocal = Song(
            title: "Acapella",
            vocalPresence: .vocals,
            vocalPresenceIsManual: true
        )

        #expect(confidentBeat.matches(vocalFilter: .instrumental))
        #expect(!confidentBeat.matches(vocalFilter: .vocals))
        #expect(uncertain.matches(vocalFilter: .uncertain))
        #expect(manualVocal.matches(vocalFilter: .vocals))
    }
}
