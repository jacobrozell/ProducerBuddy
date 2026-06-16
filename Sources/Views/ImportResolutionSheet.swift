import SwiftUI
import SwiftData

/// Review and confirm imports that need user input before committing.
struct ImportResolutionSheet: View {
    @Binding var plan: ImportPlan
    let songs: [Song]
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Some files match existing songs. Choose where each one should go.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach($plan.items) { $item in
                    if item.needsReview {
                        ImportResolutionRow(item: $item, songs: songs)
                    } else {
                        resolvedRow(item)
                    }
                }
            }
            .navigationTitle("Import Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import All", action: confirm)
                }
            }
            .accessibilityIdentifier(A11yID.Library.importResolution)
        }
    }

    private func resolvedRow(_ item: ImportPlanItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.audio.sourceBasename)
                .font(.body.weight(.medium))
            Text(item.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func confirm() {
        onConfirm()
        dismiss()
    }
}

private struct ImportResolutionRow: View {
    @Binding var item: ImportPlanItem
    let songs: [Song]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.audio.sourceBasename)
                .font(.headline)

            Text(item.summary)
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Destination", selection: $item.target) {
                Text("New song").tag(ImportTarget.newSong)
                if !item.candidates.isEmpty {
                    Section("Matches") {
                        ForEach(item.candidates) { candidate in
                            Text(candidate.song.title).tag(ImportTarget.existingSong(candidate.song.id))
                        }
                    }
                } else {
                    ForEach(songs) { song in
                        Text(song.title).tag(ImportTarget.existingSong(song.id))
                    }
                }
            }

            Picker("Version type", selection: $item.role) {
                ForEach(MixRole.allCases) { role in
                    Text(role.displayName).tag(role)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
