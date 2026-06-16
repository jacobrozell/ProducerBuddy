import SwiftUI
import SwiftData

/// Pick a project to add a single song to (library swipe action).
struct AddToProjectSheet: View {
    let song: Song

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.title) private var projects: [Project]

    @State private var showingNewProject = false

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    ContentUnavailableView {
                        Label("No Projects", systemImage: "square.stack.3d.up")
                    } description: {
                        Text("Create a project first, then add \"\(song.title)\" to its running order.")
                    } actions: {
                        Button("New Project") { showingNewProject = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(projects) { project in
                        Button {
                            add(song, to: project)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(project.title)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text("\(project.kind.displayName) · \(project.tracks.count) tracks")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(projectAlreadyContains(project))
                        .accessibilityHint(
                            projectAlreadyContains(project)
                                ? "Already in this project"
                                : "Add to running order"
                        )
                    }
                }
            }
            .navigationTitle("Add to Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("New Project", systemImage: "plus") { showingNewProject = true }
                }
            }
            .sheet(isPresented: $showingNewProject) {
                ProjectEditorView(project: nil, onCreated: { project in
                    add(song, to: project)
                })
            }
        }
        .accessibilityIdentifier(A11yID.Library.addToProjectSheet)
    }

    private func projectAlreadyContains(_ project: Project) -> Bool {
        project.tracks.contains { $0.song?.id == song.id }
    }

    private func add(_ song: Song, to project: Project) {
        guard !projectAlreadyContains(project) else { return }
        let track = ProjectTrack(position: project.tracks.count, song: song)
        track.project = project
        modelContext.insert(track)
        Haptics.success()
        dismiss()
    }
}
