import SwiftUI
import SwiftData

/// Lists all of the user's release projects (albums, EPs, etc.). Uses split view on iPad.
struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \Project.dateCreated, order: .reverse) private var projects: [Project]

    @State private var showingNewProject = false
    @State private var showingSettings = false
    @State private var projectPendingDelete: Project?
    @State private var selectedProjectID: UUID?

    var body: some View {
        Group {
            if usesSplitLayout {
                projectSplitView
            } else {
                projectCompactView
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingNewProject) { ProjectEditorView(project: nil) }
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
        .onChange(of: projectIDs) { _, ids in
            guard let selectedProjectID, !ids.contains(selectedProjectID) else { return }
            self.selectedProjectID = nil
        }
    }

    private var usesSplitLayout: Bool {
        AdaptiveLayout.usesSplitNavigation(horizontalSizeClass)
    }

    private var sidebarWidth: SplitColumnWidth {
        AdaptiveLayout.splitColumnWidth(dynamicType: dynamicTypeSize)
    }

    private var selectedProject: Project? {
        guard let selectedProjectID else { return nil }
        return projects.first { $0.id == selectedProjectID }
    }

    private var projectIDs: Set<UUID> {
        Set(projects.map(\.id))
    }

    private var projectCompactView: some View {
        NavigationStack {
            projectListContent(splitSelection: false)
                .navigationTitle("Projects")
                .toolbar { projectToolbarContent }
        }
    }

    private var projectSplitView: some View {
        NavigationSplitView {
            NavigationStack {
                projectListContent(splitSelection: true)
                    .navigationTitle("Projects")
                    .toolbar { projectToolbarContent }
            }
            .navigationSplitViewColumnWidth(
                min: sidebarWidth.min,
                ideal: sidebarWidth.ideal,
                max: sidebarWidth.max
            )
        } detail: {
            if let selectedProject {
                ProjectDetailView(project: selectedProject)
            } else {
                ContentUnavailableView {
                    Label("Select a Project", systemImage: "square.stack.3d.up")
                } description: {
                    Text("Choose a release project to edit its running order and energy flow.")
                }
                .adaptiveEmptyStateLayout()
            }
        }
    }

    @ViewBuilder
    private func projectListContent(splitSelection: Bool) -> some View {
        Group {
            if projects.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(projects) { project in
                        projectRow(project, splitSelection: splitSelection)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func projectRow(_ project: Project, splitSelection: Bool) -> some View {
        Group {
            if splitSelection {
                Button { selectedProjectID = project.id } label: {
                    ProjectRow(project: project)
                }
                .buttonStyle(.plain)
                .listSidebarSelection(isSelected: selectedProjectID == project.id, enabled: true)
            } else {
                NavigationLink {
                    ProjectDetailView(project: project)
                } label: {
                    ProjectRow(project: project)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { projectPendingDelete = project } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ToolbarContentBuilder
    private var projectToolbarContent: some ToolbarContent {
        if ReleaseSurface.settings {
            ToolbarItem(placement: .topBarLeading) {
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
                .accessibilityIdentifier(A11yID.Settings.button)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showingNewProject = true } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("New project")
        }
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
        .adaptiveEmptyStateLayout()
    }

    private func deleteProject(_ project: Project) {
        if selectedProjectID == project.id { selectedProjectID = nil }
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
                .accessibilityHidden(true)

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
