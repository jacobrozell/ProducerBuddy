import Foundation
import SwiftData

struct ImportOutcome: Sendable, Equatable {
    let newSongs: Int
    let addedVersions: Int
}

/// Creates songs and primary mixes from imported audio, then schedules background
/// waveform and metadata work. Shared by the library importer and demo seeding.
enum SongImportService {
    private struct PendingBackgroundWork {
        let songID: PersistentIdentifier?
        let mixID: PersistentIdentifier
        let fileURL: URL
        let analyzeSong: Bool
    }

    @MainActor
    static func importSongs(
        _ results: [ImportedAudio],
        into context: ModelContext,
        scheduleBackgroundWork: Bool = true
    ) -> ImportOutcome {
        let existing = (try? context.fetch(FetchDescriptor<Song>())) ?? []
        let plan = ImportPlanner.plan(results, existing: existing)
        return execute(plan, into: context, scheduleBackgroundWork: scheduleBackgroundWork)
    }

    @MainActor
    static func execute(
        _ plan: ImportPlan,
        into context: ModelContext,
        scheduleBackgroundWork: Bool = true
    ) -> ImportOutcome {
        var existing = (try? context.fetch(FetchDescriptor<Song>())) ?? []
        var pending: [PendingBackgroundWork] = []
        var newSongs = 0
        var addedVersions = 0

        for item in plan.items {
            switch item.target {
            case .newSong:
                let audio = item.audio
                let parsed = item.parsed
                let title = parsed.baseTitle.isEmpty ? audio.suggestedTitle : parsed.baseTitle
                let song = Song(title: title, artist: audio.artist ?? "")
                if VersionImportSettings.autoSuggestExportPrefix {
                    song.exportPrefix = MixNamingParser.suggestedExportPrefix(
                        from: audio.sourceBasename
                    ) ?? ExportPrefixSuggester.suggest(fromParsedBaseTitle: parsed.baseTitle)
                }
                song.normalizedTitle = parsed.normalizedTitle
                context.insert(song)
                existing.append(song)

                let mix = attachMix(
                    to: song,
                    audio: audio,
                    parsed: parsed,
                    context: context,
                    isFirstMix: true,
                    role: item.role
                )
                pending.append(PendingBackgroundWork(
                    songID: song.persistentModelID,
                    mixID: mix.persistentModelID,
                    fileURL: mix.fileURL,
                    analyzeSong: true
                ))
                newSongs += 1

            case .existingSong(let songID):
                guard let song = existing.first(where: { $0.id == songID }) else { continue }
                let mix = attachMix(
                    to: song,
                    audio: item.audio,
                    parsed: item.parsed,
                    context: context,
                    role: item.role
                )
                pending.append(PendingBackgroundWork(
                    songID: nil,
                    mixID: mix.persistentModelID,
                    fileURL: mix.fileURL,
                    analyzeSong: false
                ))
                addedVersions += 1
            }
        }

        try? context.save()

        guard scheduleBackgroundWork else {
            return ImportOutcome(newSongs: newSongs, addedVersions: addedVersions)
        }

        for item in pending {
            scheduleWaveformGeneration(mixID: item.mixID, fileURL: item.fileURL, context: context)
            if item.analyzeSong, let songID = item.songID {
                scheduleMetadataDetection(songID: songID, fileURL: item.fileURL, context: context)
            }
        }

        return ImportOutcome(newSongs: newSongs, addedVersions: addedVersions)
    }

    @MainActor
    @discardableResult
    static func attachMix(
        to song: Song,
        audio: ImportedAudio,
        parsed: ParsedMixFilename,
        context: ModelContext,
        isFirstMix: Bool = false,
        role: MixRole? = nil
    ) -> Mix {
        let isPrimary = isFirstMix || song.mixes.isEmpty
        let mix = Mix(
            name: "",
            fileName: audio.fileName,
            duration: audio.duration,
            isPrimary: isPrimary,
            role: role ?? parsed.suggestedRole,
            sourceFileName: audio.sourceBasename,
            versionLabel: parsed.versionLabel,
            sortOrder: song.mixes.count
        )
        mix.song = song
        context.insert(mix)
        return mix
    }

    @MainActor
    private static func scheduleWaveformGeneration(
        mixID: PersistentIdentifier, fileURL: URL, context: ModelContext
    ) {
        Task { @MainActor in
            let peaks = await WaveformGenerator.generate(url: fileURL)
            guard !peaks.isEmpty, let mix = context.model(for: mixID) as? Mix else { return }
            mix.waveform = peaks
        }
    }

    @MainActor
    private static func scheduleMetadataDetection(
        songID: PersistentIdentifier, fileURL: URL, context: ModelContext
    ) {
        Task { @MainActor in
            let analysis = await AudioAnalyzer.analyze(url: fileURL)
            guard let song = context.model(for: songID) as? Song else { return }
            if let bpm = analysis.bpm { song.bpm = bpm }
            if let key = analysis.key, key != .unknown { song.key = key }
            song.applyDetectedVocals(analysis.vocal)
        }
    }
}
