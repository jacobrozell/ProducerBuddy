import SwiftUI
import SwiftData

/// Export prefix editor on song detail.
struct SongExportPrefixSection: View {
    @Bindable var song: Song
    let allSongs: [Song]

    @State private var exportPrefixDraft = ""
    @State private var prefixValidation: ExportPrefixValidation?

    var body: some View {
        Section {
            HStack {
                TextField("NightDrive_", text: $exportPrefixDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier(A11yID.Song.exportPrefix)
                    .onChange(of: exportPrefixDraft) { _, newValue in
                        validatePrefix(newValue)
                    }
                if !exportPrefixDraft.isEmpty {
                    Button("Copy", systemImage: "doc.on.doc") {
                        UIPasteboard.general.string = exportPrefixDraft
                    }
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Copy export prefix")
                }
            }
            if let prefixValidation {
                if let error = prefixValidation.error {
                    Text(error).font(.caption).foregroundStyle(.red)
                } else if let warning = prefixValidation.warning {
                    Text(warning).font(.caption).foregroundStyle(.orange)
                }
            }
            Text(
                "Name FL exports like \(exportPrefixDraft.isEmpty ? "YourBeat_" : exportPrefixDraft)"
                + "master.mp3 and they stack here automatically."
            )
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Save Prefix") { saveExportPrefix() }
                .disabled(!(prefixValidation?.isValid ?? true))
        } header: {
            Text("Export Naming")
        }
        .onAppear {
            exportPrefixDraft = song.exportPrefix
            validatePrefix(exportPrefixDraft)
        }
    }

    private func validatePrefix(_ value: String) {
        prefixValidation = ExportPrefixValidator.validate(
            value,
            excludingSongID: song.id,
            existingSongs: allSongs
        )
    }

    private func saveExportPrefix() {
        let trimmed = exportPrefixDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        validatePrefix(trimmed)
        guard prefixValidation?.isValid ?? true else { return }
        song.exportPrefix = trimmed
        song.exportPrefixIsManual = !trimmed.isEmpty
        Haptics.success()
    }
}
