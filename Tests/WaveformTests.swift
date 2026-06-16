import Testing
@testable import MixStack

@Suite("Waveform")
struct WaveformTests {

    @Test("Produces exactly the requested number of buckets")
    func bucketCount() {
        let samples = [Float](repeating: 0.5, count: 1000)
        #expect(WaveformGenerator.peaks(from: samples, buckets: 50).count == 50)
    }

    @Test("Peaks are normalized so the tallest is 1")
    func normalizedToOne() {
        let samples: [Float] = [0.1, 0.2, 0.4, 0.8]
        let peaks = WaveformGenerator.peaks(from: samples, buckets: 4)
        #expect(abs((peaks.max() ?? 0) - 1) < 0.0001)
    }

    @Test("A louder region yields a taller bucket")
    func louderRegionTaller() {
        // First half quiet, second half loud.
        let samples = [Float](repeating: 0.1, count: 500) + [Float](repeating: 0.9, count: 500)
        let peaks = WaveformGenerator.peaks(from: samples, buckets: 2)
        #expect(peaks[1] > peaks[0])
    }

    @Test("Negative samples are measured by magnitude")
    func usesMagnitude() {
        let peaks = WaveformGenerator.peaks(from: [-1.0, 0.0], buckets: 2)
        #expect(peaks[0] > peaks[1])
    }

    @Test("Empty input or zero buckets yields no peaks")
    func emptyCases() {
        #expect(WaveformGenerator.peaks(from: [], buckets: 10).isEmpty)
        #expect(WaveformGenerator.peaks(from: [0.5], buckets: 0).isEmpty)
    }

    @Test("Silence stays flat rather than dividing by zero")
    func silenceStaysFlat() {
        let peaks = WaveformGenerator.peaks(from: [Float](repeating: 0, count: 100), buckets: 10)
        #expect(peaks.allSatisfy { $0 == 0 })
    }

    @Test("A new mix has no cached waveform")
    func mixWaveformDefaults() {
        let mix = Mix(name: "Original", fileName: "a.m4a")
        #expect(mix.hasWaveform == false)
        mix.waveform = [0.2, 0.4, 1.0]
        #expect(mix.hasWaveform)
    }
}
