import Foundation
import AVFoundation

/// The result of analysing an audio file. Values are estimates and may be nil
/// when the audio is too short or couldn't be read.
struct AudioAnalysis: Sendable {
    let bpm: Int?
    let key: MusicalKey?
    let vocal: VocalAnalysis
}

/// Vocal presence estimate with an optional confidence score.
struct VocalAnalysis: Sendable {
    let presence: VocalPresence
    let confidence: Double?

    static let unknown = VocalAnalysis(presence: .unknown, confidence: nil)
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
              Double(audio.samples.count) > audio.sampleRate else { // need at least ~1s
            return AudioAnalysis(bpm: nil, key: nil, vocal: .unknown)
        }
        let bpm = estimateBPM(samples: audio.samples, sampleRate: audio.sampleRate)
        let key = estimateKey(samples: audio.samples, sampleRate: audio.sampleRate)
        let vocal = estimateVocalPresence(samples: audio.samples, sampleRate: audio.sampleRate)
        return AudioAnalysis(bpm: bpm, key: key, vocal: vocal)
    }

    // MARK: - Vocals

    private static let vocalLabelThreshold = VocalDetectionThresholds.labeled
    private static let vocalMinimumConfidence = VocalDetectionThresholds.minimum

    /// Heuristic vocal/instrumental estimate from mono PCM samples.
    static func estimateVocalPresence(
        samples: [Float], sampleRate: Double
    ) -> VocalAnalysis {
        let window = 2048
        let hop = 512
        guard samples.count > window * 4,
              Double(samples.count) > sampleRate else {
            return .unknown
        }

        let signalEnergy = samples.reduce(0.0) { $0 + Double($1 * $1) }
        guard signalEnergy > 1e-4 * Double(samples.count) else {
            return .unknown
        }

        var frameScores = [Double]()
        frameScores.reserveCapacity((samples.count - window) / hop + 1)
        var start = 0
        while start + window <= samples.count {
            let frame = Array(samples[start..<(start + window)])
            frameScores.append(vocalFrameScore(frame: frame, sampleRate: sampleRate))
            start += hop
        }
        guard !frameScores.isEmpty else { return .unknown }

        let modulation = modulationScore(samples: samples, sampleRate: sampleRate)
        let vocalFraction = Double(frameScores.filter { $0 > 0.5 }.count) / Double(frameScores.count)
        let meanScore = frameScores.reduce(0, +) / Double(frameScores.count)
        guard meanScore >= 0.05 || vocalFraction >= 0.05 else {
            return .unknown
        }
        let variance = frameScores.map { ($0 - meanScore) * ($0 - meanScore) }.reduce(0, +)
            / Double(frameScores.count)
        let consistency = max(0, min(1, 1 - sqrt(variance)))

        var rawScore = 0.40 * vocalFraction + 0.25 * meanScore + 0.10 * consistency + 0.25 * modulation
        if modulation > 0.30 && meanScore > 0.18 {
            rawScore = min(1, rawScore + 0.15)
        }
        if vocalFraction > 0.40 {
            rawScore = min(1, rawScore + 0.10)
        }
        if modulation < 0.15 && vocalFraction < 0.15 {
            rawScore = min(rawScore, 0.40)
        }
        rawScore = max(0, min(1, rawScore))

        let guessedPresence: VocalPresence = rawScore >= 0.5 ? .vocals : .instrumental
        let stability = max(consistency, modulation * 0.9)
        let consistencyBoost = 0.5 + 0.5 * stability
        var confidence = min(1, abs(rawScore - 0.5) * 2 * consistencyBoost)

        // Steady harmonic pads: low modulation + high harmonicity → instrumental.
        if modulation < 0.15, consistency > 0.7, guessedPresence == .instrumental {
            confidence = max(confidence, vocalLabelThreshold)
        }

        guard confidence >= vocalMinimumConfidence else {
            return VocalAnalysis(presence: .unknown, confidence: nil)
        }

        let presence: VocalPresence
        if confidence >= vocalLabelThreshold {
            presence = guessedPresence
        } else if guessedPresence == .vocals, modulation > 0.35, confidence >= 0.5 {
            presence = .vocals
        } else {
            presence = .unknown
        }
        return VocalAnalysis(presence: presence, confidence: confidence)
    }

    /// Per-frame vocal likelihood from band energy, harmonicity, and flatness.
    private static func vocalFrameScore(frame: [Float], sampleRate: Double) -> Double {
        let totalEnergy = frame.reduce(0.0) { $0 + Double($1 * $1) }
        guard totalEnergy > 1e-10 else { return 0 }

        var vocalEnergy = 0.0
        for freq in stride(from: 300.0, through: 3_400.0, by: 400.0) {
            vocalEnergy += goertzelPower(samples: frame, frequency: freq, sampleRate: sampleRate)
        }
        let bandRatio = min(1, vocalEnergy / totalEnergy)

        let minLag = max(1, Int(sampleRate / 300.0))
        let maxLag = min(frame.count - 1, Int(sampleRate / 80.0))
        var harmonicity = 0.0
        if maxLag > minLag {
            var best = 0.0
            for lag in minLag...maxLag {
                var corr = 0.0
                for index in lag..<frame.count {
                    corr += Double(frame[index] * frame[index - lag])
                }
                best = max(best, corr)
            }
            harmonicity = min(1, best / totalEnergy)
        }

        var powers = [Double]()
        let nyquist = sampleRate / 2
        for freq in stride(from: 100.0, through: min(nyquist - 1, 5_000), by: 300.0) {
            let power = goertzelPower(samples: frame, frequency: freq, sampleRate: sampleRate)
            if power > 0 { powers.append(power) }
        }
        let flatness: Double
        if powers.count >= 2 {
            let geo = pow(powers.reduce(1, *), 1.0 / Double(powers.count))
            let arith = powers.reduce(0, +) / Double(powers.count)
            flatness = arith > 0 ? min(1, geo / arith) : 1
        } else {
            flatness = 0.5
        }

        // Penalize steady pure tones outside the vocal band (e.g. sub-bass pads).
        let tonalPenalty = flatness < 0.12 && harmonicity > 0.6 && bandRatio < 0.35 ? 0.35 : 1.0
        let score = (0.35 * bandRatio + 0.30 * harmonicity + 0.35 * flatness) * tonalPenalty
        return max(0, min(1, score))
    }

    /// File-level amplitude modulation — speech and singing vary more than steady pads.
    private static func modulationScore(samples: [Float], sampleRate: Double) -> Double {
        let blockSize = max(1, Int(sampleRate * 0.2))
        guard samples.count > blockSize * 4 else { return 0 }

        var rmsValues = [Double]()
        var index = 0
        while index + blockSize <= samples.count {
            var sum = 0.0
            for offset in index..<(index + blockSize) {
                sum += Double(samples[offset] * samples[offset])
            }
            rmsValues.append(sqrt(sum / Double(blockSize)))
            index += blockSize
        }
        guard rmsValues.count >= 2 else { return 0 }

        let mean = rmsValues.reduce(0, +) / Double(rmsValues.count)
        guard mean > 1e-8 else { return 0 }
        let variance = rmsValues.map { ($0 - mean) * ($0 - mean) }.reduce(0, +)
            / Double(rmsValues.count)
        return min(1, (sqrt(variance) / mean) * 2.5)
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

        let best = bestAutocorrelationLag(onset: onset, minLag: minLag, maxLag: maxLag)
        guard best.score > 0 else { return nil }

        var bpm = 60.0 * framesPerSecond / Double(best.lag)
        // Fold octave errors into the plausible range.
        while bpm < minBPM { bpm *= 2 }
        while bpm > maxBPM { bpm /= 2 }
        return Int(bpm.rounded())
    }

    private static func bestAutocorrelationLag(
        onset: [Float], minLag: Int, maxLag: Int
    ) -> (lag: Int, score: Float) {
        var bestLag = minLag
        var bestScore = -Float.greatestFiniteMagnitude
        for lag in minLag...maxLag {
            var score: Float = 0
            for index in lag..<onset.count {
                score += onset[index] * onset[index - lag]
            }
            if score > bestScore {
                bestScore = score
                bestLag = lag
            }
        }
        return (bestLag, bestScore)
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
