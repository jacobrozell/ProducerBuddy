import SwiftUI
import UniformTypeIdentifiers

/// Share sheet wrapper after catalog export.
struct CatalogExportShareSheet: View {
    let exportURL: URL
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ShareLink(item: exportURL) {
                Label("Share Catalog", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .navigationTitle("Export Catalog")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done, action: onDismiss)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
