import SwiftUI
import SwiftData

/// Multi-select picker for adding songs to a project's running order. Songs
/// already in the project are excluded.
struct AddTracksView: View {
    let project: Project

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Song.title) private var allSongs: [Song]

    @State private var selected: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Group {
                if availableSongs.isEmpty {
                    ContentUnavailableView(
                        "No Songs to Add",
                        systemImage: "music.note",
                        description: Text("Every song in your library is already in this project.")
                    )
                } else {
                    List(availableSongs, selection: $selected) { song in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(song.title).font(.body.weight(.medium))
                            Text("\(song.bpm) BPM\(song.genre.isEmpty ? "" : " · \(song.genre)")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(song.id)
                    }
                    .environment(\.editMode, .constant(.active))
                }
            }
            .navigationTitle("Add Tracks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selected.count))", action: add)
                        .disabled(selected.isEmpty)
                }
            }
        }
    }

    /// Songs not already part of the project.
    private var availableSongs: [Song] {
        let existing = Set(project.tracks.compactMap { $0.song?.id })
        return allSongs.filter { !existing.contains($0.id) }
    }

    private func add() {
        var nextPosition = project.tracks.count
        for song in availableSongs where selected.contains(song.id) {
            let track = ProjectTrack(position: nextPosition, song: song)
            track.project = project
            modelContext.insert(track)
            nextPosition += 1
        }
        dismiss()
    }
}
