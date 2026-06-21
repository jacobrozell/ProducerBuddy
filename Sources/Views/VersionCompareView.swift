import SwiftUI
import SwiftData

/// Side-by-side A/B comparison of two mixes on the same song.
struct VersionCompareView: View {
    @Bindable var song: Song
    @Environment(\.dismiss) private var dismiss
    @Environment(AudioPlayer.self) private var audioPlayer

    @State private var leftMixID: UUID?
    @State private var rightMixID: UUID?

    private var mixes: [Mix] { song.orderedMixes }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if mixes.count < 2 {
                        ContentUnavailableView(
                            L10n.compareNeedTwoVersions,
                            systemImage: "waveform.badge.plus",
                            description: Text(L10n.compareNeedTwoVersionsHint)
                        )
                        .padding(.top, 40)
                    } else {
                        mixPickers
                        comparisonGrid
                        playbackControls
                    }
                }
                .padding()
            }
            .navigationTitle(L10n.compareTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.done) { dismiss() }
                }
            }
            .onAppear { seedSelectionIfNeeded() }
            .accessibilityIdentifier(A11yID.Song.compare)
        }
    }

    private var mixPickers: some View {
        HStack(spacing: 12) {
            mixPickerColumn(title: L10n.compareMixA, selection: leftSelection)
            mixPickerColumn(title: L10n.compareMixB, selection: rightSelection)
        }
    }

    private func mixPickerColumn(title: String, selection: Binding<UUID?>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            Picker(title, selection: selection) {
                ForEach(mixes) { mix in
                    Text(mix.displayName).tag(Optional(mix.id))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var comparisonGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 14) {
            GridRow {
                Text("")
                    .gridColumnAlignment(.leading)
                columnHeader(L10n.compareMixA, mix: leftMix)
                columnHeader(L10n.compareMixB, mix: rightMix)
            }
            compareRow(L10n.compareWaveform) {
                miniWaveform(leftMix)
                miniWaveform(rightMix)
            }
            compareRow(L10n.compareDuration) {
                valueCell(leftMix?.formattedDuration ?? "—")
                valueCell(rightMix?.formattedDuration ?? "—")
            }
            compareRow(L10n.compareBPM) {
                valueCell("\(song.bpm)")
                valueCell("\(song.bpm)")
            }
            compareRow(L10n.compareKey) {
                valueCell(song.key.displayName)
                valueCell(song.key.displayName)
            }
            compareRow(L10n.compareLUFS) {
                lufsCell(leftMix)
                lufsCell(rightMix)
            }
            compareRow(L10n.compareRole) {
                roleCell(leftMix)
                roleCell(rightMix)
            }
        }
        .padding()
        .background(Brand.surfaceElevated, in: RoundedRectangle(cornerRadius: 12))
    }

    private func columnHeader(_ title: String, mix: Mix?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if let mix {
                Text(mix.displayName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func compareRow(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        GridRow {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            content()
        }
    }

    @ViewBuilder
    private func miniWaveform(_ mix: Mix?) -> some View {
        if let mix, mix.hasWaveform {
            WaveformView(
                samples: mix.waveform,
                progress: isPlaying(mix) ? playedFraction : 0,
                playedColor: .accentColor,
                unplayedColor: Color(.systemGray4)
            )
            .frame(height: 32)
            .allowsHitTesting(false)
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 32)
        }
    }

    private func valueCell(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.monospacedDigit())
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func lufsCell(_ mix: Mix?) -> some View {
        if let lufs = mix?.integratedLUFS {
            LoudnessBadge(lufs: lufs)
        } else {
            Text("—")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func roleCell(_ mix: Mix?) -> some View {
        if let mix {
            Text(mix.role.displayName)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(mix.role.tint.opacity(0.2), in: Capsule())
                .foregroundStyle(mix.role.tint)
        } else {
            Text("—")
        }
    }

    private var playbackControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                playButton(for: leftMix, label: L10n.comparePlayA)
                playButton(for: rightMix, label: L10n.comparePlayB)
            }
            Button {
                switchBetweenSelected()
            } label: {
                Label(L10n.compareSwitchAtPlayhead, systemImage: "arrow.left.arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(leftMix == nil || rightMix == nil || leftMix?.id == rightMix?.id)

            HStack(spacing: 12) {
                setPrimaryButton(for: leftMix, label: L10n.compareSetAPrimary)
                setPrimaryButton(for: rightMix, label: L10n.compareSetBPrimary)
            }
        }
    }

    private func playButton(for mix: Mix?, label: String) -> some View {
        Button {
            guard let mix else { return }
            Haptics.tap()
            audioPlayer.play(mix)
        } label: {
            Label(label, systemImage: isPlaying(mix) ? "pause.fill" : "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(mix == nil)
    }

    private func setPrimaryButton(for mix: Mix?, label: String) -> some View {
        Button {
            guard let mix else { return }
            setPrimary(mix)
        } label: {
            Text(label)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(mix == nil || mix?.isPrimary == true)
    }

    private var leftMix: Mix? { mix(for: leftMixID) }
    private var rightMix: Mix? { mix(for: rightMixID) }

    private var leftSelection: Binding<UUID?> {
        Binding(
            get: { leftMixID },
            set: { newValue in
                leftMixID = newValue
                reconcileDistinctSelections(changed: .left)
            }
        )
    }

    private var rightSelection: Binding<UUID?> {
        Binding(
            get: { rightMixID },
            set: { newValue in
                rightMixID = newValue
                reconcileDistinctSelections(changed: .right)
            }
        )
    }

    private enum MixSide { case left, right }

    private func reconcileDistinctSelections(changed side: MixSide) {
        guard leftMixID == rightMixID, mixes.count >= 2 else { return }
        let alternate = mixes.first { $0.id != (side == .left ? leftMixID : rightMixID) }
        guard let alternate else { return }
        if side == .left {
            rightMixID = alternate.id
        } else {
            leftMixID = alternate.id
        }
    }

    private func mix(for id: UUID?) -> Mix? {
        guard let id else { return nil }
        return mixes.first { $0.id == id }
    }

    private func seedSelectionIfNeeded() {
        guard mixes.count >= 2 else { return }
        if leftMixID == nil {
            leftMixID = song.primaryMix?.id ?? mixes[0].id
        }
        if rightMixID == nil {
            let fallback = mixes.first { $0.id != leftMixID } ?? mixes[1]
            rightMixID = fallback.id
        }
    }

    private func switchBetweenSelected() {
        guard let left = leftMix, let right = rightMix, left.id != right.id else { return }
        let target = audioPlayer.currentMix?.id == left.id ? right : left
        Haptics.tap()
        audioPlayer.switchMix(to: target)
    }

    private func setPrimary(_ mix: Mix) {
        for existing in song.mixes {
            existing.isPrimary = existing.id == mix.id
        }
        Haptics.tap()
    }

    private func isPlaying(_ mix: Mix?) -> Bool {
        guard let mix else { return false }
        return audioPlayer.isPlaying && audioPlayer.currentMix?.id == mix.id
    }

    private var playedFraction: Double {
        guard audioPlayer.duration > 0 else { return 0 }
        return audioPlayer.currentTime / audioPlayer.duration
    }
}
