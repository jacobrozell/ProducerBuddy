import SwiftUI
import SwiftData

/// Lists all of the user's release projects (albums, EPs, etc.).
struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.dateCreated, order: .reverse) private var projects: [Project]

    @State private var showingNewProject = false
    @State private var showingSettings = false
    @State private var projectPendingDelete: Project?

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                if ReleaseSurface.settings {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Settings")
                        .accessibilityIdentifier(A11yID.Settings.button)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingNewProject) {
                ProjectEditorView(project: nil)
            }
            .confirmationDialog(
                deleteDialogTitle,
                isPresented: deleteDialogPresented,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let project = projectPendingDelete { deleteProject(project) }
                }
                Button("Cancel", role: .cancel) { projectPendingDelete = nil }
            } message: {
                if let project = projectPendingDelete {
                    Text("Songs stay in your library; only \"\(project.title)\" and its running order are removed.")
                }
            }
        }
    }

    private var list: some View {
        List {
            ForEach(projects) { project in
                NavigationLink {
                    ProjectDetailView(project: project)
                } label: {
                    ProjectRow(project: project)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        projectPendingDelete = project
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Projects", systemImage: "square.stack.3d.up")
        } description: {
            Text("Create an album or EP and start sequencing your tracks.")
        } actions: {
            Button("New Project") { showingNewProject = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private func deleteProject(_ project: Project) {
        modelContext.delete(project)
        projectPendingDelete = nil
    }

    private var deleteDialogTitle: String {
        guard let project = projectPendingDelete else { return "Delete Project?" }
        return "Delete \"\(project.title)\"?"
    }

    private var deleteDialogPresented: Binding<Bool> {
        Binding(
            get: { projectPendingDelete != nil },
            set: { if !$0 { projectPendingDelete = nil } }
        )
    }
}

/// One row in the project list, summarising track count and runtime.
private struct ProjectRow: View {
    let project: Project

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.gradient)
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: "opticaldisc")
                        .font(.title2)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(project.title)
                    .font(.headline)
                Text("\(project.kind.displayName) · \(project.tracks.count) tracks · \(runtime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var runtime: String {
        let total = Int(project.totalDuration.rounded())
        guard total > 0 else { return "0:00" }
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
