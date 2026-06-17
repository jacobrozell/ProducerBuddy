import AVFoundation
import Foundation

/// Plain-language semantics for integrated loudness readings.
enum LoudnessSemantics {
    static func formatted(lufs: Double) -> String {
        String(format: "%.1f LUFS", lufs)
    }

    static func guidance(for lufs: Double) -> String {
        switch lufs {
        case ..<(-16): return "Quiet — may sound soft after normalization"
        case -16...(-11): return "In streaming ballpark"
        case -11...(-9): return "Louder than typical streaming target"
        default: return "Very loud — may be limited on streaming"
        }
    }

    static func isCaution(lufs: Double) -> Bool {
        lufs < -16 || lufs > -11
    }
}

/// Simplified BS.1770-style integrated loudness estimate from mono PCM.
enum LoudnessAnalyzer {
    private static let maxAnalysisSeconds = 600.0

    static func estimateIntegratedLUFS(url: URL) async -> Double? {
        await Task.detached(priority: .utility) {
            guard let audio = loadMonoSamples(url: url, maxSeconds: maxAnalysisSeconds) else { return nil }
            return estimateIntegratedLUFS(samples: audio.samples, sampleRate: audio.sampleRate)
        }.value
    }

    static func estimateIntegratedLUFS(samples: [Float], sampleRate: Double) -> Double? {
        let blockSamples = max(1, Int(sampleRate * 0.4))
        let hop = max(1, blockSamples / 4)
        guard samples.count > blockSamples else {
            return blockLoudness(samples: samples)
        }

        var blockValues: [Double] = []
        var start = 0
        while start + blockSamples <= samples.count {
            let slice = samples[start..<(start + blockSamples)]
            if let value = blockLoudness(samples: Array(slice)) {
                blockValues.append(value)
            }
            start += hop
        }
        guard !blockValues.isEmpty else { return nil }

        let ungated = blockValues.reduce(0, +) / Double(blockValues.count)
        let gate = ungated - 70
        let gated = blockValues.filter { $0 > gate }
        return gated.isEmpty ? ungated : gated.reduce(0, +) / Double(gated.count)
    }

    private static func blockLoudness(samples: [Float]) -> Double? {
        guard !samples.isEmpty else { return nil }
        var sum = 0.0
        for sample in samples {
            let value = Double(sample)
            sum += value * value
        }
        let meanSquare = sum / Double(samples.count)
        guard meanSquare > 0 else { return nil }
        return -0.691 + 10 * log10(meanSquare)
    }

    private static func loadMonoSamples(url: URL, maxSeconds: Double) -> (samples: [Float], sampleRate: Double)? {
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

        var mono = [Float](repeating: 0, count: frameLength)
        for channel in 0..<channelCount {
            let data = channels[channel]
            for index in 0..<frameLength {
                mono[index] += data[index]
            }
        }
        if channelCount > 1 {
            let scale = 1 / Float(channelCount)
            for index in 0..<frameLength { mono[index] *= scale }
        }
        return (mono, nativeRate)
    }
}
