import Foundation
import SwiftData

enum ImportTarget: Equatable, Hashable {
    case newSong
    case existingSong(UUID)
}

struct ImportPlanItem: Identifiable {
    let id = UUID()
    let audio: ImportedAudio
    let parsed: ParsedMixFilename
    let candidates: [ImportMatchCandidate]
    var target: ImportTarget
    var role: MixRole
    let needsReview: Bool
    let summary: String
}

struct ImportPlan {
    var items: [ImportPlanItem]

    var needsReview: Bool { items.contains(where: \.needsReview) }
}

/// Decides per-file import targets before committing songs and mixes.
enum ImportPlanner {
    static func plan(_ results: [ImportedAudio], existing songs: [Song]) -> ImportPlan {
        var catalog = songs
        var items: [ImportPlanItem] = []

        for audio in results {
            let item = planItem(audio, catalog: catalog)
            items.append(item)
            if case .newSong = item.target {
                let parsed = item.parsed
                let title = parsed.baseTitle.isEmpty ? audio.suggestedTitle : parsed.baseTitle
                let phantom = Song(title: title, artist: audio.artist ?? "")
                phantom.normalizedTitle = parsed.normalizedTitle
                if VersionImportSettings.autoSuggestExportPrefix {
                    phantom.exportPrefix = MixNamingParser.suggestedExportPrefix(
                        from: audio.sourceBasename
                    ) ?? ExportPrefixSuggester.suggest(fromParsedBaseTitle: parsed.baseTitle)
                }
                catalog.append(phantom)
            }
        }

        return ImportPlan(items: items)
    }

    private static func planItem(_ audio: ImportedAudio, catalog: [Song]) -> ImportPlanItem {
        let parsed = MixNamingParser.parse(basename: audio.sourceBasename)
        let duration = Int(audio.duration.rounded())
        let candidates = ImportMatcher.findMatches(
            basename: audio.sourceBasename,
            parsed: parsed,
            durationSeconds: duration,
            in: catalog
        )
        let prefixMatches = ImportMatcher.findAllPrefixMatches(
            basename: audio.sourceBasename,
            in: catalog
        )

        var needsReview = false
        var target: ImportTarget = .newSong
        var summary = "New song"
        let role = parsed.suggestedRole

        if prefixMatches.count > 1 {
            needsReview = true
            target = .existingSong(prefixMatches[0].id)
            summary = "Multiple songs match prefix"
        } else if let song = prefixMatches.first {
            let mismatch = durationMismatch(song: song, importDuration: duration)
            if mismatch && VersionImportSettings.askWhenDurationDiffers {
                needsReview = true
                summary = "Prefix `\(song.exportPrefix)` · different length"
                target = .existingSong(song.id)
            } else if VersionImportSettings.autoAddOnPrefixMatch {
                target = .existingSong(song.id)
                summary = "Export prefix `\(song.exportPrefix)`"
            } else {
                needsReview = true
                target = .existingSong(song.id)
                summary = "Prefix match `\(song.exportPrefix)`"
            }
        } else if let best = candidates.first {
            if best.confidence >= ImportMatcher.autoAddThreshold,
               candidates.count == 1,
               VersionImportSettings.autoMatchVersions {
                target = .existingSong(best.song.id)
                summary = best.reason
            } else if best.confidence >= ImportMatcher.askThreshold {
                needsReview = true
                target = .existingSong(best.song.id)
                summary = best.reason
            }
        }

        return ImportPlanItem(
            audio: audio,
            parsed: parsed,
            candidates: candidates,
            target: target,
            role: role,
            needsReview: needsReview,
            summary: summary
        )
    }

    private static func durationMismatch(song: Song, importDuration: Int) -> Bool {
        guard let primary = song.primaryMix, primary.duration > 0 else { return false }
        return abs(Int(primary.duration.rounded()) - importDuration) > 30
    }
}
