import Foundation

/// Pure filter and section helpers for the library list (unit-tested).
enum LibraryFilterLogic {
    static let bpmRangeLimit = 60...200

    static func matchesBPMRange(song: Song, min bpmMin: Int, max bpmMax: Int) -> Bool {
        let lo = Swift.min(bpmMin, bpmMax)
        let hi = Swift.max(bpmMin, bpmMax)
        guard lo > bpmRangeLimit.lowerBound || hi < bpmRangeLimit.upperBound else { return true }
        return song.bpm >= lo && song.bpm <= hi
    }

    static func matchesKeyFilter(song: Song, selectedKeys: Set<MusicalKey>) -> Bool {
        guard !selectedKeys.isEmpty else { return true }
        return selectedKeys.contains(song.key)
    }

    static func matchesFavoritesOnly(song: Song, favoritesOnly: Bool) -> Bool {
        !favoritesOnly || song.isFavorite
    }

    static func matchesSearch(song: Song, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let needle = query.lowercased()
        return song.title.lowercased().contains(needle)
            || song.artist.lowercased().contains(needle)
            || song.genre.lowercased().contains(needle)
            || song.notes.lowercased().contains(needle)
    }

    /// BPM bucket label for section headers when sorted by tempo.
    static func bpmSectionTitle(for bpm: Int) -> String {
        switch bpm {
        case ..<90: return "60–90 BPM"
        case 90..<110: return "90–110 BPM"
        case 110..<128: return "110–128 BPM"
        case 128..<150: return "128–150 BPM"
        default: return "150+ BPM"
        }
    }

    static let bpmSectionOrder = [
        "60–90 BPM", "90–110 BPM", "110–128 BPM", "128–150 BPM", "150+ BPM"
    ]

    /// Rating bucket for section headers when sorted by stars.
    static func ratingSectionTitle(for rating: Int) -> String {
        rating > 0 ? "\(rating)★" : "Unrated"
    }

    static let ratingSectionOrder = ["5★", "4★", "3★", "2★", "1★", "Unrated"]

    struct Section: Identifiable {
        let title: String
        let songs: [Song]
        var id: String { title.isEmpty ? "all" : title }
    }

    /// Groups songs into labeled sections for BPM/Rating sorts; flat list otherwise.
    static func sections(for songs: [Song], sort: LibrarySort) -> [Section] {
        switch sort {
        case .bpm:
            let grouped = Dictionary(grouping: songs, by: { bpmSectionTitle(for: $0.bpm) })
            return bpmSectionOrder.compactMap { title in
                guard let group = grouped[title], !group.isEmpty else { return nil }
                return Section(title: title, songs: group.sorted { $0.bpm < $1.bpm })
            }
        case .rating:
            let grouped = Dictionary(grouping: songs, by: { ratingSectionTitle(for: $0.rating) })
            return ratingSectionOrder.compactMap { title in
                guard let group = grouped[title], !group.isEmpty else { return nil }
                return Section(title: title, songs: group.sorted { $0.rating > $1.rating })
            }
        default:
            return [Section(title: "", songs: songs)]
        }
    }

    static func isBPMFilterActive(min bpmMin: Int, max bpmMax: Int) -> Bool {
        bpmMin > bpmRangeLimit.lowerBound || bpmMax < bpmRangeLimit.upperBound
    }
}
