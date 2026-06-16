import SwiftUI

/// Top-level tab container. The persistent now-playing bar floats above the tab
/// bar whenever a mix is loaded.
struct RootView: View {
    @Environment(AudioPlayer.self) private var audioPlayer

    var body: some View {
        TabView {
            Tab("Library", systemImage: "music.note.list") {
                LibraryView()
            }
            Tab("Projects", systemImage: "square.stack.3d.up") {
                ProjectListView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if audioPlayer.currentMix != nil {
                NowPlayingBar()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: audioPlayer.currentMix?.id)
    }
}
