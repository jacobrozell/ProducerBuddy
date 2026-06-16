import SwiftUI

/// One row in the library list. Tapping the artwork-style play button starts the
/// song's primary mix; the rest of the row navigates to detail.
struct SongRow: View {
    let song: Song
    @Environment(AudioPlayer.self) private var audioPlayer

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if let mix = song.primaryMix {
                    Haptics.tap()
                    audioPlayer.play(mix)
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(song.category.tint.gradient)
                        .frame(width: 46, height: 46)
                    Image(systemName: isThisPlaying ? "pause.fill" : "play.fill")
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .disabled(song.primaryMix == nil)
            .opacity(song.primaryMix == nil ? 0.5 : 1)
            .accessibilityLabel(isThisPlaying ? "Pause \(song.title)" : "Play \(song.title)")
            .accessibilityIdentifier(A11yID.Song.play)

            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if !song.artist.isEmpty {
                        Text(song.artist)
                    }
                    Text("\(song.bpm) BPM")
                    if !song.genre.isEmpty {
                        Text("· \(song.genre)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if song.hasConfidentVocalLabel {
                    VocalPresenceBadge(presence: song.vocalPresence)
                }
                if song.rating > 0 {
                    StarRatingView(rating: .constant(song.rating), isEditable: false)
                }
                if song.mixes.count > 1 {
                    Text("\(song.mixes.count) versions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if let mix = song.primaryMix, mix.role != .original {
                    Text(mix.role.displayName)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(mix.role.tint)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var isThisPlaying: Bool {
        audioPlayer.isPlaying && audioPlayer.currentMix?.id == song.primaryMix?.id
    }
}
