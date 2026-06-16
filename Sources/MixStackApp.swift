import SwiftUI
import SwiftData

@main
struct MixStackApp: App {
    /// Shared SwiftData container for the whole app.
    let modelContainer: ModelContainer

    @State private var audioPlayer = AudioPlayer()

    init() {
        do {
            modelContainer = try ModelContainer(
                for: Song.self, Mix.self, Project.self, ProjectTrack.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        AppLog.shared.info(.app, eventName: "app_launched", message: "MixStack started")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(audioPlayer)
        }
        .modelContainer(modelContainer)
    }
}
