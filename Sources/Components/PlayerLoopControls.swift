import SwiftUI

/// Loop mode picker and section bounds for the full-screen player.
struct PlayerLoopControls: View {
    @Environment(AudioPlayer.self) private var audioPlayer
    @State private var sectionStart: Double = 0
    @State private var sectionEnd: Double = 30

    var body: some View {
        VStack(spacing: 12) {
            Picker("Loop", selection: Binding(
                get: { loopKind },
                set: { setLoopKind($0) }
            )) {
                ForEach(LoopKind.allCases, id: \.rawValue) { kind in
                    Text(kind.label).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.loopPlayback)

            if case let .section(start, end) = audioPlayer.loopMode {
                sectionLoopSliders(start: start, end: end)
            }
        }
    }

    private enum LoopKind: Int, CaseIterable {
        case off, track, section

        var label: String {
            switch self {
            case .off: return L10n.loopOff
            case .track: return L10n.loopTrack
            case .section: return L10n.loopSection
            }
        }
    }

    private var loopKind: LoopKind {
        switch audioPlayer.loopMode {
        case .off: return .off
        case .wholeTrack: return .track
        case .section: return .section
        }
    }

    private func sectionLoopSliders(start: Double, end: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(format(start))
                Spacer()
                Text(format(end))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)

            let maxStart = max(sectionEnd - PlaybackLoopLogic.minimumSectionLength, 0.01)
            Slider(
                value: Binding(
                    get: { sectionStart },
                    set: { newValue in
                        sectionStart = newValue
                        audioPlayer.updateSectionLoop(start: sectionStart, end: sectionEnd)
                    }
                ),
                in: 0...maxStart
            )
            .accessibilityLabel("Loop start")

            let minEnd = min(sectionStart + PlaybackLoopLogic.minimumSectionLength, audioPlayer.duration)
            let maxEnd = max(audioPlayer.duration, 0.01)
            Slider(
                value: Binding(
                    get: { sectionEnd },
                    set: { newValue in
                        sectionEnd = newValue
                        audioPlayer.updateSectionLoop(start: sectionStart, end: sectionEnd)
                    }
                ),
                in: minEnd...maxEnd
            )
            .accessibilityLabel("Loop end")
        }
        .onAppear {
            sectionStart = start
            sectionEnd = end
        }
        .onChange(of: audioPlayer.loopMode) { _, newMode in
            if case let .section(newStart, newEnd) = newMode {
                sectionStart = newStart
                sectionEnd = newEnd
            }
        }
    }

    private func setLoopKind(_ kind: LoopKind) {
        switch kind {
        case .off:
            audioPlayer.loopMode = .off
        case .track:
            audioPlayer.loopMode = .wholeTrack
        case .section:
            audioPlayer.loopSection()
            if case let .section(start, end) = audioPlayer.loopMode {
                sectionStart = start
                sectionEnd = end
            }
        }
        Haptics.tap()
    }

    private func format(_ time: Double) -> String {
        let totalSeconds = Int(time.rounded())
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
