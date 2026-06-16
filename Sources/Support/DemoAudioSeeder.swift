import Foundation
import SwiftData

/// Imports MP3s bundled under `Resources/` for local demo and agent testing.
///
/// Drop personal tracks in `Resources/*.mp3` (gitignored), rebuild, then either:
/// - Launch with `-seed_demo_tracks` to import when the library is empty, or
/// - Use **Load Demo Tracks** in Settings.
enum DemoAudioSeeder {
    static let seedLaunchArgument = "-seed_demo_tracks"

    static var isRequested: Bool {
        CommandLine.arguments.contains(seedLaunchArgument)
    }

    static var hasBundleTracks: Bool {
        !bundleTrackURLs().isEmpty
    }

    /// Sorted MP3 URLs from the app bundle (nil when Resources were not packaged).
    static func bundleTrackURLs() -> [URL] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) else {
            return []
        }
        return urls.sorted {
            $0.deletingPathExtension().lastPathComponent.localizedStandardCompare(
                $1.deletingPathExtension().lastPathComponent
            ) == .orderedAscending
        }
    }

    /// Copies each bundled track into `AudioStorage` and reads duration/tags.
    static func importBundleTracks() async -> [ImportedAudio] {
        var imported: [ImportedAudio] = []
        for url in bundleTrackURLs() {
            do {
                let audio = try await AudioStorage.importBundledAudio(from: url)
                imported.append(audio)
            } catch {
                #if DEBUG
                print("DemoAudioSeeder: skipped \(url.lastPathComponent): \(error)")
                #endif
            }
        }
        return imported
    }

    /// Builds a demo EP with every song in the library, ordered by title.
    @MainActor
    static func createDemoProjectIfNeeded(into context: ModelContext) {
        let projectCount = (try? context.fetchCount(FetchDescriptor<Project>())) ?? 0
        guard projectCount == 0 else { return }

        let descriptor = FetchDescriptor<Song>(sortBy: [SortDescriptor(\.title)])
        guard let songs = try? context.fetch(descriptor), songs.count >= 2 else { return }

        let project = Project(title: "Demo EP", subtitle: "Your bundled tracks", kind: .ep)
        context.insert(project)
        for (index, song) in songs.enumerated() {
            let track = ProjectTrack(position: index, song: song)
            track.project = project
            context.insert(track)
        }
    }
}
