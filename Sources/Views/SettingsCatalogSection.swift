import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Settings data section for catalog export/import.
struct SettingsCatalogSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AudioPlayer.self) private var audioPlayer

    let songs: [Song]
    let isExportingCatalog: Bool
    let onExport: () -> Void
    let onImportComplete: (String) -> Void

    @State private var showingCatalogImporter = false
    @State private var pendingCatalogImportURL: URL?
    @State private var showingImportModeDialog = false
    @State private var showingReplaceConfirm = false
    @State private var pendingImportMode: CatalogImportMode = .merge

    var body: some View {
        Group {
            Button(action: onExport) {
                Label(
                    isExportingCatalog ? "Exporting Catalog…" : L10n.exportCatalog,
                    systemImage: "square.and.arrow.up.on.square"
                )
            }
            .disabled(isExportingCatalog || songs.isEmpty)
            .accessibilityIdentifier(A11yID.Settings.exportCatalog)

            Button {
                showingCatalogImporter = true
            } label: {
                Label(L10n.importCatalog, systemImage: "square.and.arrow.down.on.square")
            }
            .accessibilityIdentifier(A11yID.Settings.importCatalog)
        }
        .fileImporter(
            isPresented: $showingCatalogImporter,
            allowedContentTypes: catalogImportTypes,
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result, let url = urls.first else { return }
            pendingCatalogImportURL = url
            showingImportModeDialog = true
        }
        .confirmationDialog(
            "Import catalog",
            isPresented: $showingImportModeDialog,
            titleVisibility: .visible
        ) {
            Button(L10n.importMerge) {
                pendingImportMode = .merge
                performCatalogImport()
            }
            Button(L10n.importReplace, role: .destructive) {
                pendingImportMode = .replace
                showingReplaceConfirm = true
            }
            Button(L10n.cancel, role: .cancel) {
                pendingCatalogImportURL = nil
            }
        } message: {
            Text("Merge skips songs that already exist. Replace wipes your library first.")
        }
        .confirmationDialog(
            L10n.importReplaceConfirm,
            isPresented: $showingReplaceConfirm,
            titleVisibility: .visible
        ) {
            Button("Replace Everything", role: .destructive) {
                pendingImportMode = .replace
                performCatalogImport()
            }
            Button(L10n.cancel, role: .cancel) {
                pendingCatalogImportURL = nil
            }
        }
    }

    private var catalogImportTypes: [UTType] {
        var types: [UTType] = [.zip]
        if let mixstack = UTType(filenameExtension: CatalogExporter.fileExtension) {
            types.append(mixstack)
        }
        return types
    }

    @MainActor
    private func performCatalogImport() {
        guard let url = pendingCatalogImportURL else { return }
        let mode = pendingImportMode
        pendingCatalogImportURL = nil
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }

        do {
            let counts = try CatalogImporter.importBundle(
                from: url,
                mode: mode,
                into: modelContext,
                audioPlayer: audioPlayer
            )
            onImportComplete("\(L10n.catalogImported) \(counts.songs) songs, \(counts.projects) projects.")
            Haptics.success()
        } catch {
            onImportComplete("Import failed: \(error.localizedDescription)")
        }
    }
}
