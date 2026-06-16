import SwiftUI

/// Full-screen "now playing" player presented from the mini bar. Offers a
/// draggable scrubber, ±15s skip, a loop toggle, and — when the song has more
/// than one mix — an A/B segmented control that swaps versions without losing
/// the playback position.
struct FullPlayerView: View {
    @Environment(AudioPlayer.self) private var audioPlayer
    @Environment(\.dismiss) private var dismiss

    /// Local scrubber value; tracks playback unless the user is dragging.
    @State private var scrubValue: Double = 0
    @State private var isScrubbing = false

    var body: some View {
        @Bindable var player = audioPlayer

        VStack(spacing: 28) {
            grabber
            artwork
            titleBlock
            if let mixes = song?.mixes, mixes.count > 1 {
                mixPicker(mixes)
            }
            scrubber
            transport
            Toggle(isOn: $player.isLooping) {
                Label("Loop", systemImage: "repeat")
            }
            .toggleStyle(.button)
            .tint(.accentColor)
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.top, 8)
        .presentationDragIndicator(.hidden)
        .onChange(of: audioPlayer.currentTime) { _, newValue in
            guard !isScrubbing else { return }
            scrubValue = newValue
        }
        .onAppear { scrubValue = audioPlayer.currentTime }
    }

    private var song: Song? { audioPlayer.currentMix?.song }

    private var grabber: some View {
        Capsule()
            .fill(.secondary)
            .frame(width: 40, height: 5)
            .padding(.top, 8)
    }

    private var artwork: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill((song?.category.tint ?? .accentColor).gradient)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Image(systemName: "music.quarternote.3")
                    .font(.system(size: 72))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .shadow(radius: 12, y: 6)
            .padding(.horizontal, 12)
    }

    private var titleBlock: some View {
        VStack(spacing: 4) {
            Text(song?.title ?? "Unknown")
                .font(.title2.bold())
                .lineLimit(1)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var subtitle: String {
        let mixName = audioPlayer.currentMix?.name ?? ""
        guard let song, !song.artist.isEmpty else { return mixName }
        return "\(song.artist) · \(mixName)"
    }

    private func mixPicker(_ mixes: [Mix]) -> some View {
        Picker("Mix", selection: mixSelection) {
            ForEach(mixes.sorted(by: { $0.dateAdded < $1.dateAdded })) { mix in
                Text(mix.name).tag(mix.id)
            }
        }
        .pickerStyle(.segmented)
    }

    /// Binding that drives the A/B mix picker, swapping mixes in place.
    private var mixSelection: Binding<UUID> {
        Binding(
            get: { audioPlayer.currentMix?.id ?? UUID() },
            set: { newID in
                if let mix = song?.mixes.first(where: { $0.id == newID }) {
                    audioPlayer.switchMix(to: mix)
                }
            }
        )
    }

    private var scrubber: some View {
        VStack(spacing: 4) {
            Slider(
                value: $scrubValue,
                in: 0...max(audioPlayer.duration, 0.01),
                onEditingChanged: { editing in
                    isScrubbing = editing
                    if !editing { audioPlayer.seek(to: scrubValue) }
                }
            )
            HStack {
                Text(format(scrubValue))
                Spacer()
                Text("-" + format(max(audioPlayer.duration - scrubValue, 0)))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }

    /// True when a project queue is loaded, enabling prev/next instead of just
    /// the ±15s skip controls.
    private var hasQueue: Bool { !audioPlayer.queue.isEmpty }

    private var transport: some View {
        HStack(spacing: 36) {
            if hasQueue {
                Button { audioPlayer.playPrevious() } label: {
                    Image(systemName: "backward.fill")
                }
                .disabled(!audioPlayer.hasPrevious)
            } else {
                Button { audioPlayer.skip(by: -15) } label: {
                    Image(systemName: "gobackward.15")
                }
            }

            Button { audioPlayer.togglePlayPause() } label: {
                Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
            }

            if hasQueue {
                Button { audioPlayer.playNext() } label: {
                    Image(systemName: "forward.fill")
                }
                .disabled(!audioPlayer.hasNext)
            } else {
                Button { audioPlayer.skip(by: 15) } label: {
                    Image(systemName: "goforward.15")
                }
            }
        }
        .font(.title)
        .tint(.primary)
    }

    private func format(_ t: Double) -> String {
        let s = Int(t.rounded())
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
