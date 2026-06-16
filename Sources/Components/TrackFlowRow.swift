import SwiftUI

/// A row in the project running order showing the track's position, song info,
/// and how its energy moves relative to the previous track. A warning icon
/// appears for abrupt BPM jumps.
struct TrackFlowRow: View {
    let position: Int
    let song: Song?
    let analysis: FlowAnalysis

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
                    if analysis.bpmDelta != 0 {
                        Text(deltaLabel)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if analysis.hasWarning {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .help(analysis.warningText ?? "")
            }

            moveBadge
        }
        .padding(.vertical, 2)
    }

    private var moveBadge: some View {
        Label(analysis.move.displayName, systemImage: analysis.move.symbolName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(moveTint.opacity(0.18), in: Capsule())
            .foregroundStyle(moveTint)
            .labelStyle(.titleAndIcon)
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
