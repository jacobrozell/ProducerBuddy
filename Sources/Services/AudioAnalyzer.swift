import Foundation
import AVFoundation

/// The result of analysing an audio file. Values are estimates and may be nil
/// when the audio is too short or couldn't be read.
struct AudioAnalysis: Sendable {
    let bpm: Int?
    let key: MusicalKey?
}

/// Estimates tempo (BPM) and musical key directly from an audio file.
///
/// This is a lightweight, dependency-free estimator — not a commercial-grade
/// detector. Tempo comes from autocorrelating an onset-energy envelope; key
/// comes from a Goertzel chromagram correlated against the Krumhansl–Schmuckler
/// key profiles. It's good enough to pre-fill metadata the user can correct, and
/// it runs off the main actor so the UI stays responsive.
///
/// All members are non-isolated `static` functions: awaiting `analyze` from a
/// `@MainActor` context runs the heavy work on the global executor.
enum AudioAnalyzer {
    /// Reads `url`, then estimates its BPM and key.
    static func analyze(url: URL) async -> AudioAnalysis {
        guard let audio = loadMonoSamples(url: url, targetRate: 11_025, maxSeconds: 90),
              audio.samples.count > audio.sampleRate else { // need at least ~1s
            return AudioAnalysis(bpm: nil, key: nil)
        }
        let bpm = estimateBPM(samples: audio.samples, sampleRate: audio.sampleRate)
        let key = estimateKey(samples: audio.samples, sampleRate: audio.sampleRate)
        return AudioAnalysis(bpm: bpm, key: key)
    }

    // MARK: - Loading

    /// Reads up to `maxSeconds` of audio, downmixes to mono, and decimates
    /// toward `targetRate` to keep the later math cheap.
    private static func loadMonoSamples(
        url: URL, targetRate: Double, maxSeconds: Double
    ) -> (samples: [Float], sampleRate: Double)? {
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        let format = file.processingFormat
        let nativeRate = format.sampleRate
        guard nativeRate > 0 else { return nil }

        let framesToRead = min(
            AVAudioFrameCount(file.length),
            AVAudioFrameCount(nativeRate * maxSeconds)
        )
        guard framesToRead > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesToRead),
              (try? file.read(into: buffer, frameCount: framesToRead)) != nil,
              let channels = buffer.floatChannelData else { return nil }

        let channelCount = Int(format.channelCount)
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return nil }

        // Average channels down to mono.
        var mono = [Float](repeating: 0, count: frameLength)
        for ch in 0..<channelCount {
            let data = channels[ch]
            for i in 0..<frameLength {
                mono[i] += data[i]
            }
        }
        if channelCount > 1 {
            let scale = 1 / Float(channelCount)
            for i in 0..<frameLength { mono[i] *= scale }
        }

        // Integer decimation with simple block averaging toward the target rate.
        let factor = max(1, Int((nativeRate / targetRate).rounded()))
        guard factor > 1 else { return (mono, nativeRate) }

        var decimated = [Float]()
        decimated.reserveCapacity(frameLength / factor + 1)
        var i = 0
        while i < frameLength {
            var sum: Float = 0
            var n = 0
            for j in i..<min(i + factor, frameLength) {
                sum += mono[j]
                n += 1
            }
            if n > 0 { decimated.append(sum / Float(n)) }
            i += factor
        }
        return (decimated, nativeRate / Double(factor))
    }

    // MARK: - Tempo

    /// Estimates BPM by autocorrelating an onset-energy envelope and folding the
    /// best lag into a musical range.
    static func estimateBPM(samples: [Float], sampleRate: Double) -> Int? {
        let window = 512
        let hop = 256
        guard samples.count > window * 4 else { return nil }

        // Short-time energy per frame.
        var energy = [Float]()
        energy.reserveCapacity(samples.count / hop)
        var start = 0
        while start + window <= samples.count {
            var sum: Float = 0
            for i in start..<(start + window) { sum += samples[i] * samples[i] }
            energy.append(sum)
            start += hop
        }
        guard energy.count > 8 else { return nil }

        // Onset envelope: positive energy increases (rough note onsets).
        var onset = [Float](repeating: 0, count: energy.count)
        for i in 1..<energy.count {
            onset[i] = max(0, energy[i] - energy[i - 1])
        }
        // Centre the envelope so autocorrelation isn't dominated by its mean.
        let mean = onset.reduce(0, +) / Float(onset.count)
        for i in onset.indices { onset[i] -= mean }

        let framesPerSecond = sampleRate / Double(hop)
        let minBPM = 70.0, maxBPM = 180.0
        let minLag = max(1, Int((60.0 * framesPerSecond / maxBPM).rounded()))
        let maxLag = min(onset.count - 1, Int((60.0 * framesPerSecond / minBPM).rounded()))
        guard maxLag > minLag else { return nil }

        var bestLag = minLag
        var bestScore = -Float.greatestFiniteMagnitude
        for lag in minLag...maxLag {
            var score: Float = 0
            for i in lag..<onset.count {
                score += onset[i] * onset[i - lag]
            }
            if score > bestScore {
                bestScore = score
                bestLag = lag
            }
        }
        guard bestScore > 0 else { return nil }

        var bpm = 60.0 * framesPerSecond / Double(bestLag)
        // Fold octave errors into the plausible range.
        while bpm < minBPM { bpm *= 2 }
        while bpm > maxBPM { bpm /= 2 }
        return Int(bpm.rounded())
    }

    // MARK: - Key

    /// Krumhansl–Schmuckler tonal hierarchy profiles (relative weights of each
    /// scale degree), used to score the detected chroma against all 24 keys.
    private static let majorProfile: [Double] =
        [6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88]
    private static let minorProfile: [Double] =
        [6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17]

    /// Estimates the musical key from a 12-bin chromagram correlated against the
    /// major and minor profiles for every possible tonic.
    static func estimateKey(samples: [Float], sampleRate: Double) -> MusicalKey? {
        let chroma = chromagram(samples: samples, sampleRate: sampleRate)
        guard chroma.contains(where: { $0 > 0 }) else { return nil }

        var best: (score: Double, key: MusicalKey)?
        for tonic in 0..<12 {
            for isMajor in [true, false] {
                let profile = isMajor ? majorProfile : minorProfile
                // Rotate the profile so its tonic aligns with `tonic`.
                let rotated = (0..<12).map { profile[(($0 - tonic) % 12 + 12) % 12] }
                let score = correlation(chroma, rotated)
                if best == nil || score > best!.score {
                    best = (score, MusicalKey.from(pitchClass: tonic, isMajor: isMajor))
                }
            }
        }
        return best?.key
    }

    /// Accumulates energy at every semitone from C2–B5 (via the Goertzel
    /// algorithm) into a 12-bin pitch-class histogram.
    private static func chromagram(samples: [Float], sampleRate: Double) -> [Double] {
        var chroma = [Double](repeating: 0, count: 12)
        let lowestMIDI = 36 // C2
        let highestMIDI = 83 // B5
        let nyquist = sampleRate / 2

        for midi in lowestMIDI...highestMIDI {
            let freq = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
            guard freq < nyquist else { continue }
            let power = goertzelPower(samples: samples, frequency: freq, sampleRate: sampleRate)
            chroma[midi % 12] += power
        }

        // Normalise so the correlation isn't scale-dependent.
        let total = chroma.reduce(0, +)
        if total > 0 {
            for i in chroma.indices { chroma[i] /= total }
        }
        return chroma
    }

    /// Goertzel estimate of signal power at a single frequency across the buffer.
    private static func goertzelPower(samples: [Float], frequency: Double, sampleRate: Double) -> Double {
        let omega = 2.0 * Double.pi * frequency / sampleRate
        let coeff = 2.0 * cos(omega)
        var s1 = 0.0, s2 = 0.0
        for sample in samples {
            let s0 = Double(sample) + coeff * s1 - s2
            s2 = s1
            s1 = s0
        }
        return s1 * s1 + s2 * s2 - coeff * s1 * s2
    }

    /// Pearson correlation between two equal-length vectors; 0 when undefined.
    private static func correlation(_ a: [Double], _ b: [Double]) -> Double {
        let n = Double(a.count)
        let meanA = a.reduce(0, +) / n
        let meanB = b.reduce(0, +) / n
        var num = 0.0, denA = 0.0, denB = 0.0
        for i in a.indices {
            let da = a[i] - meanA
            let db = b[i] - meanB
            num += da * db
            denA += da * da
            denB += db * db
        }
        let den = (denA * denB).squareRoot()
        return den == 0 ? 0 : num / den
    }
}
