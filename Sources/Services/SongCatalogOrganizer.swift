import Foundation
import SwiftData

struct CatalogOrganizeResult: Equatable {
    let prefixesAssigned: Int
    let songsMerged: Int
}

/// One-time catalog cleanup: export prefixes for FL `Project_N` rows and merge
/// duplicate songs that should have been versions.
enum SongCatalogOrganizer {
    static func organize(songs: [Song], into context: ModelContext) -> CatalogOrganizeResult {
        let prefixesAssigned = assignMissingExportPrefixes(songs)
        let groups = findMergeGroups(songs)
        var songsMerged = 0

        for group in groups {
            for source in group.sources {
                mergeSong(source, into: group.destination, context: context)
                songsMerged += 1
            }
        }

        if prefixesAssigned > 0 || songsMerged > 0 {
            try? context.save()
        }

        return CatalogOrganizeResult(prefixesAssigned: prefixesAssigned, songsMerged: songsMerged)
    }

    /// Assigns `Project_6_`-style prefixes to FL demo rows when missing.
    @discardableResult
    static func assignMissingExportPrefixes(_ songs: [Song]) -> Int {
        var count = 0
        for song in songs where song.exportPrefix.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let prefix = inferExportPrefix(for: song), !prefix.isEmpty else { continue }
            song.exportPrefix = prefix
            if song.normalizedTitle.isEmpty {
                song.normalizedTitle = MixNamingParser.normalize(song.title)
            }
            count += 1
        }
        return count
    }

    static func inferExportPrefix(for song: Song) -> String? {
        let basename = song.primaryMix?.sourceFileName ?? song.title
        return MixNamingParser.suggestedExportPrefix(from: basename)
    }

    struct MergeGroup {
        let destination: Song
        let sources: [Song]
        let reason: String
    }

    static func findMergeGroups(_ songs: [Song]) -> [MergeGroup] {
        var buckets: [String: [Song]] = [:]
        for song in songs {
            buckets[versionGroupKey(for: song), default: []].append(song)
        }

        return buckets.compactMap { key, group in
            guard group.count > 1 else { return nil }
            let sorted = group.sorted { $0.dateAdded < $1.dateAdded }
            let destination = sorted[0]
            let sources = Array(sorted.dropFirst())
            return MergeGroup(
                destination: destination,
                sources: sources,
                reason: "Same version group · \(key)"
            )
        }
    }

    static func versionGroupKey(for song: Song) -> String {
        if let source = song.primaryMix?.sourceFileName, !source.isEmpty {
            return MixNamingParser.parse(basename: source).normalizedTitle
        }
        if !song.normalizedTitle.isEmpty { return song.normalizedTitle }
        return MixNamingParser.normalize(song.title)
    }

    static func mergeSong(_ source: Song, into destination: Song, context: ModelContext) {
        let mixesToMove = source.mixes
        for (index, mix) in mixesToMove.enumerated() {
            mix.isPrimary = false
            mix.sortOrder = destination.mixes.count + index
            mix.song = destination
        }
        if destination.exportPrefix.isEmpty, !source.exportPrefix.isEmpty {
            destination.exportPrefix = source.exportPrefix
        }
        context.delete(source)
    }
}
