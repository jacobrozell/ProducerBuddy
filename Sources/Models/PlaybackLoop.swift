import Foundation

/// How the player repeats playback — whole track or a chosen section.
enum PlaybackLoopMode: Equatable, Sendable {
    case off
    case wholeTrack
    case section(start: Double, end: Double)
}

/// Pure helpers for clamping loop regions to a track duration.
enum PlaybackLoopLogic {
    static let minimumSectionLength: Double = 0.5

    static func normalizedSection(
        start: Double,
        end: Double,
        duration: Double
    ) -> (start: Double, end: Double)? {
        guard duration > 0 else { return nil }
        let clampedStart = min(max(0, start), duration)
        let clampedEnd = min(max(0, end), duration)
        guard clampedEnd - clampedStart >= minimumSectionLength else { return nil }
        return (clampedStart, clampedEnd)
    }

    static func shouldRestart(currentTime: Double, end: Double, epsilon: Double = 0.05) -> Bool {
        currentTime >= end - epsilon
    }

    static func defaultSection(
        around time: Double,
        duration: Double,
        length: Double = 30
    ) -> (start: Double, end: Double)? {
        let start = min(max(0, time), max(0, duration - minimumSectionLength))
        let end = min(duration, start + length)
        return normalizedSection(start: start, end: end, duration: duration)
    }
}
