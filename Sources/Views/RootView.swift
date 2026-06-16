import SwiftUI

/// Top-level tab container. The persistent now-playing bar floats above the tab
/// bar whenever a mix is loaded.
struct RootView: View {
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
    }

    /// Drives the first-run cover; dismissing marks onboarding complete.
    private var showOnboarding: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding },
            set: { presented in if !presented { hasCompletedOnboarding = true } }
        )
    }
}
