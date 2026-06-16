import SwiftUI

/// Compact transport shown above the tab bar while audio is loaded. Tapping the
/// progress region scrubs; the button toggles play/pause.
struct NowPlayingBar: View {
    @Environment(AudioPlayer.self) private var audioPlayer

    var body: some View {
        VStack(spacing: 6) {
            ProgressView(value: progress)
                .tint(.accentColor)

            HStack(spacing: 12) {
                Image(systemName: "waveform")
                    .foregroundStyle(.accent)

                VStack(alignment: .leading, spacing: 1) {
                    Text(audioPlayer.currentMix?.song?.title ?? "Unknown")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(audioPlayer.currentMix?.name ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(timeLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Button {
                    audioPlayer.togglePlayPause()
                } label: {
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                }

                Button {
                    audioPlayer.stop()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var progress: Double {
        guard audioPlayer.duration > 0 else { return 0 }
        return audioPlayer.currentTime / audioPlayer.duration
    }

    private var timeLabel: String {
        func fmt(_ t: Double) -> String {
            let s = Int(t.rounded())
            return String(format: "%d:%02d", s / 60, s % 60)
        }
        return "\(fmt(audioPlayer.currentTime)) / \(fmt(audioPlayer.duration))"
    }
}
