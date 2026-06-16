import Foundation
import SwiftData

/// Builds the app's SwiftData container. UI tests use in-memory storage via `-ui_test_reset`.
enum ModelContainerFactory {
    enum StorageMode: Sendable {
        case appDefault
        case inMemory
        case customURL(URL)
    }

    static func makeContainer(mode: StorageMode = storageModeForCurrentProcess()) throws -> ModelContainer {
        let configuration: ModelConfiguration
        switch mode {
        case .inMemory:
            configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        case .appDefault:
            let url = appStoreURL()
            try ensureParentDirectoryExists(for: url)
            configuration = ModelConfiguration(url: url)
        case let .customURL(url):
            try ensureParentDirectoryExists(for: url)
            configuration = ModelConfiguration(url: url)
        }
        return try ModelContainer(
            for: Song.self, Mix.self, Project.self, ProjectTrack.self,
            configurations: configuration
        )
    }

    static func storageModeForCurrentProcess() -> StorageMode {
        if ProcessInfo.processInfo.arguments.contains(UITestLaunch.resetArgument) {
            return .inMemory
        }
        return .appDefault
    }

    private static func appStoreURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("MixStack.store")
    }

    private static func ensureParentDirectoryExists(for storeURL: URL) throws {
        let directory = storeURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
