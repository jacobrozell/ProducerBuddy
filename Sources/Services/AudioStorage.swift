import Foundation
import AVFoundation

/// Manages on-disk storage of imported audio files. Files live in a dedicated
/// `Audio` subdirectory of the app's Documents folder and are referenced by
/// relative filename so the records remain valid across launches.
enum AudioStorage {
    /// Directory where imported audio is copied. Created lazily on first access.
    static var audioDirectory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Audio", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Copies a user-picked file into the audio directory under a unique name.
    /// - Parameter sourceURL: a security-scoped URL from the document picker.
    /// - Returns: the stored filename (relative to `audioDirectory`).
    @discardableResult
    static func importFile(from sourceURL: URL) throws -> String {
        let needsStop = sourceURL.startAccessingSecurityScopedResource()
        defer { if needsStop { sourceURL.stopAccessingSecurityScopedResource() } }

        let ext = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let fileName = "\(UUID().uuidString).\(ext)"
        let destination = audioDirectory.appendingPathComponent(fileName)
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return fileName
    }

    /// Reads the duration in seconds of an audio file already in storage.
    static func duration(of fileName: String) async -> Double {
        let url = audioDirectory.appendingPathComponent(fileName)
        let asset = AVURLAsset(url: url)
        guard let duration = try? await asset.load(.duration) else { return 0 }
        return CMTimeGetSeconds(duration)
    }

    /// Removes a stored audio file, ignoring missing-file errors.
    static func deleteFile(named fileName: String) {
        let url = audioDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}
