import SwiftUI

/// Edit a single mix's role, name, and notes.
struct MixEditorView: View {
    @Bindable var mix: Mix
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var role: MixRole = .original
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Version") {
                    Picker("Role", selection: $role) {
                        ForEach(MixRole.allCases) { option in
                            Label(option.displayName, systemImage: option.symbolName)
                                .tag(option)
                        }
                    }
                    TextField("Custom name (optional)", text: $name)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }

                if let source = mix.sourceFileName, !source.isEmpty {
                    Section("Import") {
                        LabeledContent("Source file", value: source)
                        LabeledContent("Added", value: mix.dateAdded.formatted(date: .abbreviated, time: .omitted))
                        LabeledContent("Duration", value: mix.formattedDuration)
                    }
                }
            }
            .navigationTitle("Edit Version")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
            .onAppear {
                name = mix.name
                role = mix.role
                notes = mix.notes
            }
        }
    }

    private func save() {
        mix.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        mix.role = role
        mix.notes = notes
        dismiss()
    }
}
