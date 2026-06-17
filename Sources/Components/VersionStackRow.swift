import SwiftUI

/// One row in the song's version stack.
struct VersionStackRow: View {
    let mix: Mix
    let onTogglePrimary: () -> Void
    let onEdit: () -> Void
    var onAnalyzeLoudness: (() -> Void)?
    @Environment(AudioPlayer.self) private var audioPlayer

    var body: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.tap()
                audioPlayer.play(mix)
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? "Pause \(mix.displayName)" : "Play \(mix.displayName)")

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(mix.displayName)
                        .font(.body.weight(.medium))
                    Text(mix.role.displayName)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(mix.role.tint.opacity(0.2), in: Capsule())
                        .foregroundStyle(mix.role.tint)
                }
                HStack(spacing: 8) {
                    Text(mix.formattedDuration)
                        .foregroundStyle(.secondary)
                    if let lufs = mix.integratedLUFS {
                        LoudnessBadge(lufs: lufs)
                    } else if let onAnalyzeLoudness {
                        Button("Analyze LUFS", action: onAnalyzeLoudness)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            if mix.hasWaveform {
                WaveformView(
                    samples: mix.waveform,
                    progress: isCurrent ? playedFraction : 0,
                    playedColor: .accentColor,
                    unplayedColor: Color(.systemGray4)
                )
                .frame(width: 72, height: 24)
                .allowsHitTesting(false)
            }

            Button(action: onTogglePrimary) {
                Image(systemName: mix.isPrimary ? "star.fill" : "star")
                    .foregroundStyle(mix.isPrimary ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(mix.isPrimary ? "Primary version" : "Set as primary")
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: onEdit)
        .accessibilityHint("Double tap to edit")
    }

    private var isPlaying: Bool {
        audioPlayer.isPlaying && audioPlayer.currentMix?.id == mix.id
    }

    private var isCurrent: Bool {
        audioPlayer.currentMix?.id == mix.id
    }

    private var playedFraction: Double {
        guard isCurrent, audioPlayer.duration > 0 else { return 0 }
        return audioPlayer.currentTime / audioPlayer.duration
    }
}
