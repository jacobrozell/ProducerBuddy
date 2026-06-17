import SwiftUI

/// Release date, distributor, and streaming links for a song.
struct ReleaseInfoCard: View {
    @Bindable var song: Song
    @State private var copiedMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if song.needsReleaseInfoBanner {
                Label("Track is live? Add your release date and links.", systemImage: "calendar.badge.plus")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let date = song.releaseDate {
                LabeledContent("Release date") {
                    Text(date, style: .date)
                }
            }

            if !song.distributor.isEmpty {
                LabeledContent("Distributor") {
                    Text(song.distributor)
                }
            }

            linkRow(title: "Spotify", urlString: song.spotifyURL, icon: "music.note.list")
            linkRow(title: "Apple Music", urlString: song.appleMusicURL, icon: "apple.logo")
            linkRow(title: "SoundCloud", urlString: song.soundcloudURL, icon: "cloud")

            if !song.releaseNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Release notes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(song.releaseNotes)
                        .font(.subheadline)
                }
            }
        }
        .accessibilityIdentifier(A11yID.Song.releaseLinks)
        .overlay(alignment: .bottom) {
            if let copiedMessage {
                Text(copiedMessage)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { self.copiedMessage = nil }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func linkRow(title: String, urlString: String, icon: String) -> some View {
        let trimmed = ReleaseURLValidator.normalized(urlString)
        if !trimmed.isEmpty, let url = URL(string: trimmed) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Link("Open", destination: url)
                    .accessibilityLabel("Open on \(title)")
                    .accessibilityHint("Opens in browser")
                Button {
                    UIPasteboard.general.string = trimmed
                    copiedMessage = "Copied \(title) link"
                    Haptics.success()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Copy \(title) link")
            }
        }
    }
}
