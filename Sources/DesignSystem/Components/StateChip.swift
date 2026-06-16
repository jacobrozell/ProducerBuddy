import SwiftUI

/// Read-only capsule for format, category, or filter tags.
struct StateChip: View {
    let title: String
    var tint: Color = Brand.accent

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs)
            .background(tint.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.35), lineWidth: 1))
            .accessibilityLabel(title)
    }
}
