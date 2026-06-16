import SwiftUI
import SwiftData

/// Full-screen "now playing" player presented from the mini bar. Offers a
/// waveform scrubber, ±15s skip, a loop toggle, and — when the song has more
/// than one mix — an A/B segmented control that swaps versions without losing
/// the playback position.
struct FullPlayerView: View {
    @Environment(AudioPlayer.self) private var audioPlayer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Local scrubber value; tracks playback unless the user is dragging.
    @State private var scrubValue: Double = 0
    @State private var isScrubbing = false

    private var compactHeight: Bool {
        AdaptiveLayout.isCompactHeight(verticalSizeClass)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if compactHeight {
                        landscapeBody
                    } else {
                        portraitBody
                    }
                }
                .padding(.horizontal, compactHeight ? 20 : 28)
                .padding(.vertical, 12)
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onChange(of: audioPlayer.currentTime) { _, newValue in
            guard !isScrubbing else { return }
            scrubValue = newValue
        }
        .onChange(of: audioPlayer.currentMix?.id) { _, _ in
            scrubValue = audioPlayer.currentTime
            ensureWaveform()
        }
        .onAppear {
            scrubValue = audioPlayer.currentTime
            ensureWaveform()
        }
    }

    private var landscapeBody: some View {
        HStack(alignment: .top, spacing: 20) {
            artwork
                .frame(maxWidth: AdaptiveLayout.playerArtworkSize(compactHeight: true))
            VStack(spacing: 16) {
                titleBlock
                mixPickerSection
                scrubber
                transport
                loopToggle
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var portraitBody: some View {
        VStack(spacing: 24) {
            grabber
            artwork
            titleBlock
            mixPickerSection
            scrubber
            transport
            loopToggle
        }
    }

    @ViewBuilder
    private var mixPickerSection: some View {
        if let mixes = song?.mixes, mixes.count > 1 {
            mixPicker(sortedMixes)
        }
    }

    @ViewBuilder
    private var loopToggle: some View {
        @Bindable var player = audioPlayer
        Toggle(isOn: $player.isLooping) {
            Label("Loop", systemImage: "repeat")
        }
        .toggleStyle(.button)
        .tint(Brand.accent)
        .accessibilityLabel("Loop playback")
        .accessibilityValue(player.isLooping ? "On" : "Off")
    }

    /// Lazily generates and caches the current mix's waveform if it's missing
    /// (e.g. mixes added before waveform support).
    private func ensureWaveform() {
        guard let mix = audioPlayer.currentMix, !mix.hasWaveform else { return }
        let mixID = mix.persistentModelID
        let url = mix.fileURL
        Task { @MainActor in
            let peaks = await WaveformGenerator.generate(url: url)
            guard !peaks.isEmpty,
                  let mix = modelContext.model(for: mixID) as? Mix else { return }
            mix.waveform = peaks
        }
    }

    private var song: Song? { audioPlayer.currentMix?.song }

    private var grabber: some View {
        Capsule()
            .fill(.secondary)
            .frame(width: 40, height: 5)
            .padding(.top, 4)
            .accessibilityHidden(true)
    }

    private var artwork: some View {
        RoundedRectangle(cornerRadius: compactHeight ? 16 : 24)
            .fill((song?.category.tint ?? Brand.accent).gradient)
            .aspectRatio(1, contentMode: .fit)
            .frame(maxHeight: AdaptiveLayout.playerArtworkSize(compactHeight: compactHeight))
            .overlay {
                Image(systemName: "music.quarternote.3")
                    .font(.system(size: compactHeight ? 44 : 72))
                    .foregroundStyle(Brand.textOnAccent.opacity(0.9))
            }
            .shadow(radius: compactHeight ? 6 : 12, y: compactHeight ? 3 : 6)
            .accessibilityHidden(true)
    }

    private var titleBlock: some View {
        VStack(alignment: compactHeight ? .leading : .center, spacing: 4) {
            Text(song?.title ?? "Unknown")
                .font(compactHeight ? .headline : .title2.bold())
                .lineLimit(2)
                .multilineTextAlignment(compactHeight ? .leading : .center)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(compactHeight ? .leading : .center)
        }
        .frame(maxWidth: .infinity, alignment: compactHeight ? .leading : .center)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let mixName = audioPlayer.currentMix?.displayName ?? ""
        guard let song, !song.artist.isEmpty else { return mixName }
        return "\(song.artist) · \(mixName)"
    }

    private var sortedMixes: [Mix] {
        song?.orderedMixes ?? []
    }

    @ViewBuilder
    private func mixPicker(_ mixes: [Mix]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(mixes) { mix in
                    mixChip(mix)
                }
            }
            .padding(.horizontal, 2)
        }
        .accessibilityLabel("Mix versions")
    }

    private func mixChip(_ mix: Mix) -> some View {
        let isSelected = audioPlayer.currentMix?.id == mix.id
        return Button {
            if audioPlayer.currentMix?.id != mix.id {
                audioPlayer.switchMix(to: mix)
            }
        } label: {
            HStack(spacing: 4) {
                if mix.isPrimary {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .accessibilityHidden(true)
                }
                Text(mix.displayName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Brand.accent : Brand.surfaceElevated, in: Capsule())
            .foregroundStyle(isSelected ? Brand.textOnAccent : Brand.textPrimary)
        }
        .buttonStyle(.plain)
        .minimumTapTarget(36)
        .accessibilityLabel("\(mix.displayName)\(mix.isPrimary ? ", primary" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var scrubber: some View {
        VStack(spacing: 8) {
            if let samples = audioPlayer.currentMix?.waveform, !samples.isEmpty {
                WaveformView(
                    samples: samples,
                    progress: progressFraction,
                    onSeek: { fraction in
                        isScrubbing = true
                        let time = fraction * audioPlayer.duration
                        scrubValue = time
                        audioPlayer.seek(to: time)
                        isScrubbing = false
                    }
                )
                .frame(height: compactHeight ? 48 : 64)
                .accessibilityElement()
                .accessibilityLabel("Playback position")
                .accessibilityValue(format(scrubValue))
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: audioPlayer.skip(by: 15)
                    case .decrement: audioPlayer.skip(by: -15)
                    @unknown default: break
                    }
                }
            } else {
                Slider(
                    value: $scrubValue,
                    in: 0...max(audioPlayer.duration, 0.01),
                    onEditingChanged: { editing in
                        isScrubbing = editing
                        if !editing { audioPlayer.seek(to: scrubValue) }
                    }
                )
                .accessibilityLabel("Playback position")
                .accessibilityValue(format(scrubValue))
            }
            HStack {
                Text(format(scrubValue))
                Spacer()
                Text("-" + format(max(audioPlayer.duration - scrubValue, 0)))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }
    }

    private var progressFraction: Double {
        guard audioPlayer.duration > 0 else { return 0 }
        return scrubValue / audioPlayer.duration
    }

    private var hasQueue: Bool { !audioPlayer.queue.isEmpty }

    private var transport: some View {
        HStack(spacing: compactHeight ? 24 : 36) {
            if hasQueue {
                Button { audioPlayer.playPrevious() } label: {
                    Image(systemName: "backward.fill")
                }
                .disabled(!audioPlayer.hasPrevious)
                .minimumTapTarget()
                .accessibilityLabel("Previous track")
                .accessibilityIdentifier(A11yID.Player.previous)
            } else {
                Button { audioPlayer.skip(by: -15) } label: {
                    Image(systemName: "gobackward.15")
                }
                .minimumTapTarget()
                .accessibilityLabel("Back 15 seconds")
                .accessibilityIdentifier(A11yID.Player.skipBackward)
            }

            Button {
                Haptics.tap()
                audioPlayer.togglePlayPause()
            } label: {
                Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: compactHeight ? 48 : 64))
            }
            .minimumTapTarget(56)
            .accessibilityLabel(audioPlayer.isPlaying ? "Pause" : "Play")
            .accessibilityIdentifier(A11yID.Player.playPause)

            if hasQueue {
                Button { audioPlayer.playNext() } label: {
                    Image(systemName: "forward.fill")
                }
                .disabled(!audioPlayer.hasNext)
                .minimumTapTarget()
                .accessibilityLabel("Next track")
                .accessibilityIdentifier(A11yID.Player.next)
            } else {
                Button { audioPlayer.skip(by: 15) } label: {
                    Image(systemName: "goforward.15")
                }
                .minimumTapTarget()
                .accessibilityLabel("Forward 15 seconds")
                .accessibilityIdentifier(A11yID.Player.skipForward)
            }
        }
        .font(.title2)
        .tint(Brand.textPrimary)
    }

    private func format(_ time: Double) -> String {
        let totalSeconds = Int(time.rounded())
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
