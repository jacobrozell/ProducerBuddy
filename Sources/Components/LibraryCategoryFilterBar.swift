import SwiftUI

/// Horizontal category chips and the filters entry point on the library screen.
struct LibraryCategoryFilterBar: View {
    @Binding var categoryFilter: SongCategory?
    let filtersAreActive: Bool
    let onShowFilters: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isOn: categoryFilter == nil) {
                    categoryFilter = nil
                }
                filtersButton
                ForEach(SongCategory.allCases) { category in
                    FilterChip(title: category.displayName, isOn: categoryFilter == category) {
                        categoryFilter = (categoryFilter == category) ? nil : category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private var filtersButton: some View {
        Button(action: onShowFilters) {
            HStack(spacing: 4) {
                Text("Filters")
                if filtersAreActive {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(filtersAreActive ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
            .foregroundStyle(filtersAreActive ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(filtersAreActive ? "Filters, active" : "Filters")
        .accessibilityIdentifier(A11yID.Library.filtersButton)
    }
}

/// Toggleable pill used in the category filter bar.
struct FilterChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isOn ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
                .foregroundStyle(isOn ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
