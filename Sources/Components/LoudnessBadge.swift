import SwiftUI

/// Compact loudness readout for a mix row.
struct LoudnessBadge: View {
    let lufs: Double

    var body: some View {
        Text(LoudnessSemantics.formatted(lufs: lufs))
            .font(.caption2.weight(.semibold).monospacedDigit())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint.opacity(0.16), in: Capsule())
            .foregroundStyle(tint)
            .accessibilityLabel("\(LoudnessSemantics.formatted(lufs: lufs)). \(LoudnessSemantics.guidance(for: lufs))")
    }

    private var tint: Color {
        LoudnessSemantics.isCaution(lufs: lufs) ? .orange : .secondary
    }
}
