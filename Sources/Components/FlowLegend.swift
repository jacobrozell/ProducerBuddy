import SwiftUI

/// A one-line key explaining what the Rise / Fall / Steady badges mean, shown
/// under the energy curve so a first-time user can read the sequencing cues.
struct FlowLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 14) {
                item(.rise, "Faster than the last track")
                item(.fall, "Slower than the last track")
            }
            HStack(spacing: 14) {
                item(.steady, "About the same tempo")
                Label("Abrupt BPM jump", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private func item(_ move: EnergyMove, _ text: String) -> some View {
        Label(text, systemImage: move.symbolName)
            .labelStyle(.titleAndIcon)
    }
}
