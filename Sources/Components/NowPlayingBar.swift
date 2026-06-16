import SwiftUI

/// Compact transport shown above the tab bar while audio is loaded. Tapping the
/// progress region scrubs; the button toggles play/pause.
struct NowPlayingBar: View {
    @Environment(AudioPlayer.self) private var audioPlayer
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var showingFullPlayer = false

    private var compactHeight: Bool {
        AdaptiveLayout.isCompactHeight(verticalSizeClass)
    }

    var body: some View {
        VStack(spacing: compactHeight ? 4 : 6) {
            ProgressView(value: progress)
                .tint(Brand.accent)
                .accessibilityLabel("Playback progress")
                .accessibilityValue(timeLabel)

            HStack(spacing: 12) {
                trackSummary
                Spacer(minLength: 8)
                transportControls
            }
        }
        .padding(.horizontal)
        .padding(.vertical, compactHeight ? 6 : 8)
        .background(.bar)
        .sheet(isPresented: $showingFullPlayer) {
            FullPlayerView()
        }
    }

    private var trackSummary: some View {
        Button {
            showingFullPlayer = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "waveform")
                    .foregroundStyle(Brand.accent)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text(audioPlayer.currentMix?.song?.title ?? "Unknown")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(compactHeight ? 1 : 2)
                        .multilineTextAlignment(.leading)
                    Text(audioPlayer.currentMix?.name ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11yID.Player.bar)
        .accessibilityLabel("\(audioPlayer.currentMix?.song?.title ?? "Unknown"), \(timeLabel)")
        .accessibilityHint("Opens full player")
    }

    private var transportControls: some View {
        HStack(spacing: 8) {
            Text(timeLabel)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Button {
                Haptics.tap()
                audioPlayer.togglePlayPause()
            } label: {
                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .minimumTapTarget()
            .accessibilityLabel(audioPlayer.isPlaying ? "Pause" : "Play")
            .accessibilityIdentifier(A11yID.Player.playPause)

            Button {
                audioPlayer.stop()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .minimumTapTarget()
            .accessibilityLabel("Stop")
            .accessibilityIdentifier(A11yID.Player.stop)
        }
    }

    private var progress: Double {
        guard audioPlayer.duration > 0 else { return 0 }
        return audioPlayer.currentTime / audioPlayer.duration
    }

    private var timeLabel: String {
        func fmt(_ time: Double) -> String {
            let totalSeconds = Int(time.rounded())
            return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
        }
        return "\(fmt(audioPlayer.currentTime)) of \(fmt(audioPlayer.duration))"
    }
}
