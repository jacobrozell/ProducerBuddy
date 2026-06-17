import Foundation

/// Maps waveform peaks to a time range for audiogram rendering.
enum WaveformSlice {
    /// Index of the peak bucket at `time` seconds into a track.
    static func peakIndex(for time: Double, trackDuration: Double, sampleCount: Int) -> Int {
        guard trackDuration > 0, sampleCount > 0 else { return 0 }
        let fraction = min(max(time / trackDuration, 0), 1)
        return min(sampleCount - 1, Int(fraction * Double(sampleCount)))
    }

    /// Returns `barCount` peak heights centered around `centerTime` for animation.
    static func visiblePeaks(
        samples: [Float],
        centerTime: Double,
        trackDuration: Double,
        barCount: Int
    ) -> [Float] {
        guard !samples.isEmpty, barCount > 0, trackDuration > 0 else {
            return Array(repeating: 0.15, count: max(barCount, 1))
        }

        let centerIndex = peakIndex(for: centerTime, trackDuration: trackDuration, sampleCount: samples.count)
        let half = barCount / 2
        return (0..<barCount).map { offset in
            let index = min(max(centerIndex - half + offset, 0), samples.count - 1)
            return max(0.08, samples[index])
        }
    }
}
