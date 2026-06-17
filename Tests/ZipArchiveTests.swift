import Foundation
import Testing
@testable import MixStack

@Suite("ZIP archive")
struct ZipArchiveTests {

    @Test("Round-trip preserves files in a directory tree")
    func roundTrip() throws {
        let source = FileManager.default.temporaryDirectory
            .appendingPathComponent("zip-source-\(UUID().uuidString)", isDirectory: true)
        let extracted = FileManager.default.temporaryDirectory
            .appendingPathComponent("zip-dest-\(UUID().uuidString)", isDirectory: true)
        let archive = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-\(UUID().uuidString).zip")

        defer {
            try? FileManager.default.removeItem(at: source)
            try? FileManager.default.removeItem(at: extracted)
            try? FileManager.default.removeItem(at: archive)
        }

        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: source.appendingPathComponent("audio", isDirectory: true),
            withIntermediateDirectories: true
        )
        try Data("hello".utf8).write(to: source.appendingPathComponent("manifest.json"))
        try Data("track".utf8).write(to: source.appendingPathComponent("audio/track.m4a"))

        try ZipArchive.createArchive(from: source, to: archive)
        try ZipArchive.extractArchive(from: archive, to: extracted)

        #expect(FileManager.default.fileExists(atPath: extracted.appendingPathComponent("manifest.json").path))
        #expect(FileManager.default.fileExists(atPath: extracted.appendingPathComponent("audio/track.m4a").path))
    }
}
