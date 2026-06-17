import SwiftUI

/// One row in the library list. Tapping the artwork-style play button starts the
/// song's primary mix; the rest of the row navigates to detail.
struct SongRow: View {
    let song: Song
    @Environment(AudioPlayer.self) private var audioPlayer
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 12) {
            playButton

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(song.title)
                        .font(.headline)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    if song.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                            .accessibilityLabel("Favorite")
                    }
                }
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
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            }
            .layoutPriority(1)

            if !dynamicTypeSize.isAccessibilitySize {
                trailingMeta
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(rowAccessibilityLabel)
    }

    private var playButton: some View {
        Button {
            if let mix = song.primaryMix {
                Haptics.tap()
                audioPlayer.play(mix)
            }
        } label: {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(song.category.tint.gradient)
                    .frame(width: artworkSize, height: artworkSize)
                Image(systemName: isThisPlaying ? "pause.fill" : "play.fill")
                    .foregroundStyle(.white)
                Image(systemName: song.category.symbolName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(5)
                    .background(.black.opacity(0.22), in: Circle())
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
        .disabled(song.primaryMix == nil)
        .opacity(song.primaryMix == nil ? 0.5 : 1)
        .accessibilityLabel(playAccessibilityLabel)
        .accessibilityIdentifier(A11yID.Song.play)
    }

    @ViewBuilder
    private var trailingMeta: some View {
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

    private var artworkSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 56 : 46
    }

    private var isThisPlaying: Bool {
        audioPlayer.isPlaying && audioPlayer.currentMix?.id == song.primaryMix?.id
    }

    private var playAccessibilityLabel: String {
        let action = isThisPlaying ? "Pause" : "Play"
        return "\(action) \(song.title), \(song.category.displayName)"
    }

    private var rowAccessibilityLabel: String {
        var parts = [song.title]
        if !song.artist.isEmpty { parts.append(song.artist) }
        parts.append("\(song.bpm) BPM")
        parts.append(song.category.displayName)
        if song.isFavorite { parts.append("favorite") }
        if song.rating > 0 { parts.append("\(song.rating) stars") }
        if song.mixes.count > 1 { parts.append("\(song.mixes.count) versions") }
        return parts.joined(separator: ", ")
    }
}
