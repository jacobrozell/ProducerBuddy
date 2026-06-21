import SwiftUI
import SwiftData

@main
struct MixStackApp: App {
    /// Shared SwiftData container for the whole app.
    let modelContainer: ModelContainer

    @State private var audioPlayer = AudioPlayer()

    init() {
        UITestLaunch.prepareAppDefaultsIfNeeded()
        do {
            modelContainer = try ModelContainerFactory.makeContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        AppLog.shared.info(.app, eventName: "app_launched", message: "MixStack started")
    }

    var body: some Scene {
        WindowGroup {
            DependencyRoot()
                .environment(audioPlayer)
        }
        .modelContainer(modelContainer)
    }
}

/// Injects repositories once `modelContext` is available from the container.
private struct DependencyRoot: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        RootView()
            .environment(\.appDependencies, .live(context: modelContext))
    }
}
