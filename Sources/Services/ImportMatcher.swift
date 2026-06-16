import Foundation

enum ImportMatchKind: String, Sendable {
    case exportPrefix
    case normalizedTitle
    case fuzzyTitle
}

struct ImportMatchCandidate: Identifiable {
    let song: Song
    let confidence: Double
    let reason: String
    let kind: ImportMatchKind

    var id: UUID { song.id }
}

/// Scores import files against existing songs (prefix-first).
enum ImportMatcher {
    static let prefixMatchWeight = 0.70
    static let autoAddThreshold = 0.85
    static let askThreshold = 0.55

    static func prefixMatch(basename: String, prefix: String) -> Bool {
        basename.lowercased().hasPrefix(prefix.lowercased())
    }

    /// Returns every song whose export prefix matches the basename.
    static func findAllPrefixMatches(basename: String, in songs: [Song]) -> [Song] {
        songs.filter { song in
            let prefix = song.exportPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !prefix.isEmpty else { return false }
            return prefixMatch(basename: basename, prefix: prefix)
        }
    }

    /// Returns the sole matching song when exactly one export prefix matches.
    static func findPrefixMatch(basename: String, in songs: [Song]) -> Song? {
        let matches = findAllPrefixMatches(basename: basename, in: songs)
        return matches.count == 1 ? matches[0] : nil
    }

    static func findMatches(
        basename: String,
        parsed: ParsedMixFilename,
        durationSeconds: Int,
        in songs: [Song]
    ) -> [ImportMatchCandidate] {
        var candidates: [ImportMatchCandidate] = []

        for song in songs {
            var score = 0.0
            var reasons: [String] = []
            var kind = ImportMatchKind.normalizedTitle

            if !song.exportPrefix.isEmpty,
               prefixMatch(basename: basename, prefix: song.exportPrefix) {
                score += prefixMatchWeight
                reasons.append("Export prefix `\(song.exportPrefix)`")
                kind = .exportPrefix
            }

            if song.normalizedTitle == parsed.normalizedTitle, !parsed.normalizedTitle.isEmpty {
                score += 0.40
                reasons.append("Same title")
            }

            if let primary = song.primaryMix {
                let delta = abs(Int(primary.duration.rounded()) - durationSeconds)
                if delta <= 2 {
                    score += 0.15
                    reasons.append("Same length")
                } else if delta > 30 {
                    score -= 0.10
                }
            }

            score = min(1.0, max(0, score))
            guard score >= askThreshold else { continue }

            candidates.append(ImportMatchCandidate(
                song: song,
                confidence: score,
                reason: reasons.joined(separator: " · "),
                kind: kind
            ))
        }

        return candidates.sorted { $0.confidence > $1.confidence }
    }
}
