import Foundation
import SwiftData

/// Builds a portable `.mixstack` catalog zip from the current SwiftData store.
@MainActor
enum CatalogExporter {
    static let fileExtension = "mixstack"

    static func export(from context: ModelContext) throws -> URL {
        let songs = try context.fetch(FetchDescriptor<Song>())
        let projects = try context.fetch(FetchDescriptor<Project>())

        let bundle = CatalogBundlePayload(
            manifest: CatalogManifest(
                schemaVersion: CatalogManifest.currentSchemaVersion,
                appVersion: appVersion,
                exportedAt: .now,
                songCount: songs.count,
                projectCount: projects.count
            ),
            songs: songs.map(snapshot(for:)),
            projects: projects.map(snapshot(for:)),
            brand: brandSnapshot()
        )

        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("catalog-export-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(bundle.manifest).write(to: workspace.appendingPathComponent("manifest.json"))
        try encoder.encode(bundle.songs).write(to: workspace.appendingPathComponent("songs.json"))
        try encoder.encode(bundle.projects).write(to: workspace.appendingPathComponent("projects.json"))
        if let brand = bundle.brand {
            try encoder.encode(brand).write(to: workspace.appendingPathComponent("brand.json"))
        }

        let audioDirectory = workspace.appendingPathComponent("audio", isDirectory: true)
        try FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        for song in songs {
            for mix in song.mixes {
                let source = AudioStorage.audioDirectory.appendingPathComponent(mix.fileName)
                guard FileManager.default.fileExists(atPath: source.path) else { continue }
                let destination = audioDirectory.appendingPathComponent(mix.fileName)
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: source, to: destination)
            }
        }

        if let logoFilename = bundle.brand?.logoFilename {
            let logoURL = BrandStorage.url(for: logoFilename)
            if FileManager.default.fileExists(atPath: logoURL.path) {
                let brandDirectory = workspace.appendingPathComponent("brand", isDirectory: true)
                try FileManager.default.createDirectory(at: brandDirectory, withIntermediateDirectories: true)
                try FileManager.default.copyItem(
                    at: logoURL,
                    to: brandDirectory.appendingPathComponent(logoFilename)
                )
            }
        }

        let zipURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MixStack-Catalog-\(formattedDate()).\(fileExtension)")
        try ZipArchive.createArchive(from: workspace, to: zipURL)
        try? FileManager.default.removeItem(at: workspace)
        return zipURL
    }

    private static func snapshot(for song: Song) -> CatalogSongSnapshot {
        CatalogSongSnapshot(
            id: song.id,
            title: song.title,
            artist: song.artist,
            genre: song.genre,
            bpm: song.bpm,
            keyRaw: song.keyRaw,
            categoryRaw: song.categoryRaw,
            rating: song.rating,
            notes: song.notes,
            isFavorite: song.isFavorite,
            dateAdded: song.dateAdded,
            vocalPresenceRaw: song.vocalPresenceRaw,
            vocalConfidence: song.vocalConfidence,
            vocalPresenceIsManual: song.vocalPresenceIsManual,
            exportPrefix: song.exportPrefix,
            exportPrefixIsManual: song.exportPrefixIsManual,
            normalizedTitle: song.normalizedTitle,
            releaseNotes: song.releaseNotes,
            releaseDate: song.releaseDate,
            distributor: song.distributor,
            spotifyURL: song.spotifyURL,
            appleMusicURL: song.appleMusicURL,
            soundcloudURL: song.soundcloudURL,
            mixes: song.mixes.map(snapshot(for:))
        )
    }

    private static func snapshot(for mix: Mix) -> CatalogMixSnapshot {
        CatalogMixSnapshot(
            id: mix.id,
            name: mix.name,
            fileName: mix.fileName,
            duration: mix.duration,
            notes: mix.notes,
            isPrimary: mix.isPrimary,
            dateAdded: mix.dateAdded,
            waveform: mix.waveform,
            roleRaw: mix.roleRaw,
            sourceFileName: mix.sourceFileName,
            versionLabel: mix.versionLabel,
            sortOrder: mix.sortOrder,
            integratedLUFS: mix.integratedLUFS,
            loudnessAnalyzedAt: mix.loudnessAnalyzedAt
        )
    }

    private static func snapshot(for project: Project) -> CatalogProjectSnapshot {
        CatalogProjectSnapshot(
            id: project.id,
            title: project.title,
            subtitle: project.subtitle,
            kindRaw: project.kindRaw,
            notes: project.notes,
            dateCreated: project.dateCreated,
            tracks: project.tracks.map {
                CatalogTrackSnapshot(id: $0.id, position: $0.position, songID: $0.song?.id ?? UUID())
            }
        )
    }

    private static func brandSnapshot() -> CatalogBrandSnapshot {
        let brand = BrandKitSettings.current()
        return CatalogBrandSnapshot(
            accentColorHex: brand.accentHex,
            displayName: brand.displayName,
            tagline: brand.tagline,
            cardStyle: brand.cardStyle.rawValue,
            logoFilename: brand.logoFilename
        )
    }

    private static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private static func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: .now)
    }
}
