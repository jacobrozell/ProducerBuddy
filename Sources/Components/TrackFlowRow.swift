import SwiftUI

/// A row in the project running order showing the track's position, song info,
/// and how its energy moves relative to the previous track. A warning icon
/// appears for abrupt BPM jumps.
struct TrackFlowRow: View {
    let position: Int
    let song: Song?
    let analysis: FlowAnalysis
    var showWorkflowBadge = false

    @State private var showingMoveInfo = false
    @State private var showingWarningInfo = false
    @State private var showingKeyInfo = false

    var body: some View {
        HStack(spacing: 12) {
            Text("\(position)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)

            VStack(alignment: .leading, spacing: 3) {
                Text(song?.title ?? "Missing song")
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("\(song?.bpm ?? 0) BPM")
                    if let code = song?.key.camelotCode {
                        Text("· \(code)")
                    }
                    if analysis.bpmDelta != 0 {
                        Text(deltaLabel)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if showWorkflowBadge, let song, song.category != .released {
                CategoryBadge(category: song.category)
            }

            if analysis.keyClash {
                Button {
                    showingKeyInfo = true
                } label: {
                    Image(systemName: "music.note")
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .minimumTapTarget(36)
                .accessibilityLabel(analysis.keyText ?? "Key clash with previous track")
                .popover(isPresented: $showingKeyInfo) {
                    badgePopover(
                        title: "Key Clash",
                        message: analysis.keyText ?? "This key may not mix smoothly with the previous track."
                    )
                }
            }

            if analysis.hasWarning {
                Button {
                    showingWarningInfo = true
                } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .minimumTapTarget(36)
                .accessibilityLabel(analysis.warningText ?? "Abrupt BPM jump")
                .popover(isPresented: $showingWarningInfo) {
                    badgePopover(
                        title: "Abrupt Jump",
                        message: analysis.warningText ?? "Large tempo change from the previous track."
                    )
                }
            }

            moveBadge
        }
        .padding(.vertical, 2)
    }

    private var moveBadge: some View {
        Button {
            showingMoveInfo = true
        } label: {
            Label(analysis.move.displayName, systemImage: analysis.move.symbolName)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(moveTint.opacity(0.18), in: Capsule())
                .foregroundStyle(moveTint)
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(analysis.move.displayName), \(analysis.move.explanation)")
        .accessibilityHint("Shows explanation")
        .popover(isPresented: $showingMoveInfo) {
            badgePopover(title: analysis.move.displayName, message: analysis.move.explanation)
        }
    }

    private func badgePopover(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: 280)
        .presentationCompactAdaptation(.popover)
    }

    private var deltaLabel: String {
        analysis.bpmDelta > 0 ? "+\(analysis.bpmDelta)" : "\(analysis.bpmDelta)"
    }

    private var moveTint: Color {
        switch analysis.move {
        case .opener: return .blue
        case .rise: return .green
        case .fall: return .purple
        case .steady: return .gray
        }
    }
}
