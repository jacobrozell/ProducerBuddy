import SwiftUI
import SwiftData

/// Create or edit a project's metadata.
struct ProjectEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let project: Project?

    @State private var title = ""
    @State private var subtitle = ""
    @State private var kind: ProjectKind = .album
    @State private var notes = ""

    private var isEditing: Bool { project != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Title", text: $title)
                    TextField("Subtitle", text: $subtitle)
                    Picker("Type", selection: $kind) {
                        ForEach(ProjectKind.allCases) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(isEditing ? "Edit Project" : "New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    private func loadIfEditing() {
        guard let project else { return }
        title = project.title
        subtitle = project.subtitle
        kind = project.kind
        notes = project.notes
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if let project {
            project.title = trimmed
            project.subtitle = subtitle
            project.kind = kind
            project.notes = notes
        } else {
            let new = Project(title: trimmed, subtitle: subtitle, kind: kind, notes: notes)
            modelContext.insert(new)
        }
        dismiss()
    }
}
