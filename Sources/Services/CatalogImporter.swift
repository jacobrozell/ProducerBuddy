import Foundation
import SwiftData
import UIKit

enum CatalogImportError: Error {
    case unsupportedSchema(Int)
    case invalidBundle
}

private struct DecodedCatalogBundle {
    let songs: [CatalogSongSnapshot]
    let projects: [CatalogProjectSnapshot]
    let brand: CatalogBrandSnapshot?
}

/// Restores a portable catalog zip into SwiftData.
@MainActor
enum CatalogImporter {
    static func importBundle(
        from zipURL: URL,
        mode: CatalogImportMode,
        into context: ModelContext,
        audioPlayer: AudioPlayer
    ) throws -> (songs: Int, projects: Int) {
        let workspace = try extractWorkspace(from: zipURL)
        defer { try? FileManager.default.removeItem(at: workspace) }

        let bundle = try decodeBundle(at: workspace)
        if mode == .replace {
            try wipeCatalog(in: context, audioPlayer: audioPlayer)
        }

        var songByID = try existingSongsByID(in: context)
        let importedSongs = try importSongs(
            bundle.songs,
            workspace: workspace,
            songByID: &songByID,
            into: context
        )
        let importedProjects = try importProjects(
            bundle.projects,
            songByID: songByID,
            into: context
        )
        if let brand = bundle.brand {
            applyBrand(brand, from: workspace)
        }

        try context.save()
        return (importedSongs, importedProjects)
    }

    private static func extractWorkspace(from zipURL: URL) throws -> URL {
        let workspace = FileManager.default.temporaryDirectory
            .appendingPathComponent("catalog-import-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
        try ZipArchive.extractArchive(from: zipURL, to: workspace)
        return workspace
    }

    private static func decodeBundle(at workspace: URL) throws -> DecodedCatalogBundle {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let manifest = try decoder.decode(
            CatalogManifest.self,
            from: Data(contentsOf: workspace.appendingPathComponent("manifest.json"))
        )
        guard manifest.schemaVersion == CatalogManifest.currentSchemaVersion else {
            throw CatalogImportError.unsupportedSchema(manifest.schemaVersion)
        }

        let songs = try decoder.decode(
            [CatalogSongSnapshot].self,
            from: Data(contentsOf: workspace.appendingPathComponent("songs.json"))
        )
        let projects = try decoder.decode(
            [CatalogProjectSnapshot].self,
            from: Data(contentsOf: workspace.appendingPathComponent("projects.json"))
        )
        let brandURL = workspace.appendingPathComponent("brand.json")
        let brand: CatalogBrandSnapshot?
        if FileManager.default.fileExists(atPath: brandURL.path) {
            brand = try decoder.decode(CatalogBrandSnapshot.self, from: Data(contentsOf: brandURL))
        } else {
            brand = nil
        }
        return DecodedCatalogBundle(songs: songs, projects: projects, brand: brand)
    }

    private static func existingSongsByID(in context: ModelContext) throws -> [UUID: Song] {
        Dictionary(uniqueKeysWithValues: (try context.fetch(FetchDescriptor<Song>())).map { ($0.id, $0) })
    }

    private static func importSongs(
        _ snapshots: [CatalogSongSnapshot],
        workspace: URL,
        songByID: inout [UUID: Song],
        into context: ModelContext
    ) throws -> Int {
        var imported = 0
        for snapshot in snapshots {
            guard songByID[snapshot.id] == nil else { continue }
            let song = Song(title: snapshot.title)
            apply(snapshot, to: song)
            context.insert(song)
            songByID[song.id] = song
            imported += 1
            try importMixes(snapshot.mixes, for: song, workspace: workspace, into: context)
        }
        return imported
    }

    private static func importMixes(
        _ snapshots: [CatalogMixSnapshot],
        for song: Song,
        workspace: URL,
        into context: ModelContext
    ) throws {
        for mixSnapshot in snapshots {
            let mix = Mix(
                id: mixSnapshot.id,
                name: mixSnapshot.name,
                fileName: mixSnapshot.fileName,
                duration: mixSnapshot.duration,
                notes: mixSnapshot.notes,
                isPrimary: mixSnapshot.isPrimary,
                dateAdded: mixSnapshot.dateAdded,
                waveform: mixSnapshot.waveform,
                role: MixRole(rawValue: mixSnapshot.roleRaw) ?? .original,
                sourceFileName: mixSnapshot.sourceFileName,
                versionLabel: mixSnapshot.versionLabel,
                sortOrder: mixSnapshot.sortOrder
            )
            mix.integratedLUFS = mixSnapshot.integratedLUFS
            mix.loudnessAnalyzedAt = mixSnapshot.loudnessAnalyzedAt
            mix.song = song
            context.insert(mix)

            let source = workspace.appendingPathComponent("audio/\(mixSnapshot.fileName)")
            guard FileManager.default.fileExists(atPath: source.path) else { continue }
            let destination = AudioStorage.audioDirectory.appendingPathComponent(mixSnapshot.fileName)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
        }
    }

    private static func importProjects(
        _ snapshots: [CatalogProjectSnapshot],
        songByID: [UUID: Song],
        into context: ModelContext
    ) throws -> Int {
        var imported = 0
        let existingProjects = Set((try context.fetch(FetchDescriptor<Project>())).map(\.id))
        for snapshot in snapshots where !existingProjects.contains(snapshot.id) {
            let project = Project(
                id: snapshot.id,
                title: snapshot.title,
                subtitle: snapshot.subtitle,
                kind: ProjectKind(rawValue: snapshot.kindRaw) ?? .album,
                notes: snapshot.notes,
                dateCreated: snapshot.dateCreated
            )
            context.insert(project)
            imported += 1

            for trackSnapshot in snapshot.tracks {
                guard let song = songByID[trackSnapshot.songID] else { continue }
                let track = ProjectTrack(id: trackSnapshot.id, position: trackSnapshot.position, song: song)
                track.project = project
                context.insert(track)
            }
        }
        return imported
    }

    private static func wipeCatalog(in context: ModelContext, audioPlayer: AudioPlayer) throws {
        audioPlayer.stop()
        let songs = try context.fetch(FetchDescriptor<Song>())
        for song in songs {
            for mix in song.mixes {
                AudioStorage.deleteFile(named: mix.fileName)
            }
            context.delete(song)
        }
        for project in try context.fetch(FetchDescriptor<Project>()) {
            context.delete(project)
        }
        BrandKitSettings.restoreDefaults()
        BrandStorage.clearAll()
    }

    private static func apply(_ snapshot: CatalogSongSnapshot, to song: Song) {
        song.id = snapshot.id
        song.title = snapshot.title
        song.artist = snapshot.artist
        song.genre = snapshot.genre
        song.bpm = snapshot.bpm
        song.keyRaw = snapshot.keyRaw
        song.categoryRaw = snapshot.categoryRaw
        song.rating = snapshot.rating
        song.notes = snapshot.notes
        song.isFavorite = snapshot.isFavorite
        song.dateAdded = snapshot.dateAdded
        song.vocalPresenceRaw = snapshot.vocalPresenceRaw
        song.vocalConfidence = snapshot.vocalConfidence
        song.vocalPresenceIsManual = snapshot.vocalPresenceIsManual
        song.exportPrefix = snapshot.exportPrefix
        song.exportPrefixIsManual = snapshot.exportPrefixIsManual
        song.normalizedTitle = snapshot.normalizedTitle
        song.releaseNotes = snapshot.releaseNotes
        song.releaseDate = snapshot.releaseDate
        song.distributor = snapshot.distributor
        song.spotifyURL = snapshot.spotifyURL
        song.appleMusicURL = snapshot.appleMusicURL
        song.soundcloudURL = snapshot.soundcloudURL
    }

    private static func applyBrand(_ brand: CatalogBrandSnapshot, from workspace: URL) {
        let defaults = UserDefaults.standard
        defaults.set(brand.accentColorHex, forKey: "brand.accentColorHex")
        defaults.set(brand.displayName, forKey: "brand.displayName")
        defaults.set(brand.tagline, forKey: "brand.tagline")
        defaults.set(brand.cardStyle, forKey: "brand.cardStyle")

        if let logoFilename = brand.logoFilename {
            let source = workspace.appendingPathComponent("brand/\(logoFilename)")
            if FileManager.default.fileExists(atPath: source.path),
               let data = try? Data(contentsOf: source),
               let image = UIImage(data: data),
               let imported = try? BrandStorage.importLogo(image: image) {
                defaults.set(imported, forKey: "brand.logoFilename")
            }
        } else {
            defaults.removeObject(forKey: "brand.logoFilename")
        }
    }
}
