import SwiftUI

/// Compact vocal/instrumental indicator for library rows.
struct VocalPresenceBadge: View {
    let presence: VocalPresence

    var body: some View {
        Label(presence.shortName, systemImage: presence.symbolName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color(.tertiarySystemFill), in: Capsule())
            .foregroundStyle(.secondary)
            .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        presence == .vocals ? "With vocals" : "Instrumental"
    }
}
