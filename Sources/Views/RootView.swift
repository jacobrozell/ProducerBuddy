import SwiftUI
import SwiftData

/// Top-level tab container. The persistent now-playing bar floats above the tab
/// bar whenever a mix is loaded.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AudioPlayer.self) private var audioPlayer
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("appearance") private var appearance: AppAppearance = .system
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        TabView {
            Tab("Library", systemImage: "music.note.list") {
                LibraryView()
            }
            Tab("Projects", systemImage: "square.stack.3d.up") {
                ProjectListView()
            }
            if ReleaseSurface.settings {
                Tab("Settings", systemImage: "gearshape") {
                    SettingsView()
                        .accessibilityIdentifier(A11yID.Settings.tab)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if audioPlayer.currentMix != nil {
                NowPlayingBar()
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Respect Reduce Motion: skip the slide animation when requested.
        .animation(reduceMotion ? nil : .snappy, value: audioPlayer.currentMix?.id)
        .preferredColorScheme(appearance.colorScheme)
        .fullScreenCover(isPresented: showOnboarding) {
            OnboardingView { hasCompletedOnboarding = true }
        }
        .task {
            // Defer one run loop so SwiftData and the tab hierarchy are ready.
            await Task.yield()
            await seedDemoTracksIfNeeded()
        }
    }

    /// Imports bundled `Resources/*.mp3` when launched with `-seed_demo_tracks`
    /// and the library is empty (agent / demo builds).
    @MainActor
    private func seedDemoTracksIfNeeded() async {
        guard DemoAudioSeeder.isRequested else { return }
        let existing = (try? modelContext.fetchCount(FetchDescriptor<Song>())) ?? 0
        guard existing == 0 else { return }
        let imported = await DemoAudioSeeder.importBundleTracks()
        guard !imported.isEmpty else { return }
        _ = SongImportService.importSongs(imported, into: modelContext)
        let allSongs = (try? modelContext.fetch(FetchDescriptor<Song>())) ?? []
        _ = SongCatalogOrganizer.organize(songs: allSongs, into: modelContext)
        DemoAudioSeeder.createDemoProjectIfNeeded(into: modelContext)
        try? modelContext.save()
        hasCompletedOnboarding = true
    }

    /// Drives the first-run cover; dismissing marks onboarding complete.
    private var showOnboarding: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding },
            set: { presented in if !presented { hasCompletedOnboarding = true } }
        )
    }
}
