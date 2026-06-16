import Foundation
import AVFoundation

/// Reduces an audio file to a small array of normalized amplitude peaks suitable
/// for drawing a waveform. Streams the file in blocks so memory stays flat even
/// for long tracks, and runs off the main actor.
enum WaveformGenerator {
    /// Produces `buckets` peak values in 0...1 across the whole file.
    /// - Returns: the peaks, or an empty array if the file couldn't be read.
    static func generate(url: URL, buckets: Int = 240) async -> [Float] {
        guard buckets > 0,
              let file = try? AVAudioFile(forReading: url) else { return [] }

        let format = file.processingFormat
        let total = file.length
        guard total > 0 else { return [] }

        let channelCount = Int(format.channelCount)
        let blockSize: AVAudioFrameCount = 65_536
        var peaks = [Float](repeating: 0, count: buckets)
        var globalIndex: Int64 = 0

        while true {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: blockSize),
                  (try? file.read(into: buffer, frameCount: blockSize)) != nil,
                  let channels = buffer.floatChannelData else { break }

            let frames = Int(buffer.frameLength)
            if frames == 0 { break }

            for i in 0..<frames {
                // Peak of the downmixed sample.
                var peak: Float = 0
                for ch in 0..<channelCount { peak += abs(channels[ch][i]) }
                peak /= Float(channelCount)

                let position = globalIndex + Int64(i)
                let bucket = min(buckets - 1, Int(position * Int64(buckets) / total))
                if peak > peaks[bucket] { peaks[bucket] = peak }
            }

            globalIndex += Int64(frames)
            if buffer.frameLength < blockSize { break } // reached EOF
        }

        return normalized(peaks)
    }

    /// Reduces in-memory mono samples to `buckets` normalized peaks. The
    /// streaming `generate` performs the same bucket-max reduction; this pure
    /// form exists so the core math is unit-testable without an audio file.
    static func peaks(from samples: [Float], buckets: Int) -> [Float] {
        guard buckets > 0, !samples.isEmpty else { return [] }
        var peaks = [Float](repeating: 0, count: buckets)
        let count = samples.count
        for (i, sample) in samples.enumerated() {
            let bucket = min(buckets - 1, i * buckets / count)
            let amplitude = abs(sample)
            if amplitude > peaks[bucket] { peaks[bucket] = amplitude }
        }
        return normalized(peaks)
    }

    /// Scales peaks so the tallest fills the view; leaves all-zero input as-is.
    private static func normalized(_ peaks: [Float]) -> [Float] {
        guard let maxPeak = peaks.max(), maxPeak > 0 else { return peaks }
        return peaks.map { $0 / maxPeak }
    }
}
