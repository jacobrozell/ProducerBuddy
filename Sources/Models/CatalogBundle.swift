import Foundation

/// Portable catalog snapshot for export/import (see `CatalogSync.md`).
struct CatalogManifest: Codable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let appVersion: String
    let exportedAt: Date
    let songCount: Int
    let projectCount: Int
}

struct CatalogMixSnapshot: Codable, Sendable, Identifiable {
    let id: UUID
    let name: String
    let fileName: String
    let duration: Double
    let notes: String
    let isPrimary: Bool
    let dateAdded: Date
    let waveform: [Float]
    let roleRaw: String
    let sourceFileName: String?
    let versionLabel: String?
    let sortOrder: Int
    let integratedLUFS: Double?
    let loudnessAnalyzedAt: Date?
}

struct CatalogSongSnapshot: Codable, Sendable, Identifiable {
    let id: UUID
    let title: String
    let artist: String
    let genre: String
    let bpm: Int
    let keyRaw: String
    let categoryRaw: String
    let rating: Int
    let notes: String
    let isFavorite: Bool
    let dateAdded: Date
    let vocalPresenceRaw: String
    let vocalConfidence: Double?
    let vocalPresenceIsManual: Bool
    let exportPrefix: String
    let exportPrefixIsManual: Bool
    let normalizedTitle: String
    let releaseNotes: String
    let releaseDate: Date?
    let distributor: String
    let spotifyURL: String
    let appleMusicURL: String
    let soundcloudURL: String
    let mixes: [CatalogMixSnapshot]
}

struct CatalogTrackSnapshot: Codable, Sendable, Identifiable {
    let id: UUID
    let position: Int
    let songID: UUID
}

struct CatalogProjectSnapshot: Codable, Sendable, Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let kindRaw: String
    let notes: String
    let dateCreated: Date
    let tracks: [CatalogTrackSnapshot]
}

struct CatalogBrandSnapshot: Codable, Sendable {
    let accentColorHex: String
    let displayName: String
    let tagline: String
    let cardStyle: String
    let logoFilename: String?
}

struct CatalogBundlePayload: Codable, Sendable {
    let manifest: CatalogManifest
    let songs: [CatalogSongSnapshot]
    let projects: [CatalogProjectSnapshot]
    let brand: CatalogBrandSnapshot?
}

enum CatalogImportMode: Sendable {
    case merge
    case replace
}
