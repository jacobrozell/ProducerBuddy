import SwiftUI

/// Small pill showing a song's workflow category with its symbol and tint.
struct CategoryBadge: View {
    let category: SongCategory

    var body: some View {
        Label(category.displayName, systemImage: category.symbolName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(category.tint.opacity(0.18), in: Capsule())
            .foregroundStyle(category.tint)
    }
}
