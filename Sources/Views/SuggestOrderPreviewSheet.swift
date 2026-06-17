import SwiftUI

/// Preview of an auto-suggested running order before the user commits changes.
struct SuggestOrderPreviewSheet: View {
    let moves: [OrderMoveChange]
    let suggestedTitles: [String]
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if moves.isEmpty {
                    ContentUnavailableView {
                        Label("Order Looks Good", systemImage: "checkmark.circle")
                    } description: {
                        Text("The current running order already follows a solid energy arc.")
                    }
                } else {
                    Section("Moving") {
                        ForEach(moves) { move in
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundStyle(.secondary)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(move.title)
                                        .font(.body.weight(.medium))
                                    Text("Position \(move.fromPosition) → \(move.toPosition)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(move.title), position \(move.fromPosition) to \(move.toPosition)")
                        }
                    }

                    Section("New Order") {
                        ForEach(Array(suggestedTitles.enumerated()), id: \.offset) { index, title in
                            Text("\(index + 1). \(title)")
                                .accessibilityLabel("Position \(index + 1), \(title)")
                        }
                    }
                }
            }
            .navigationTitle("Suggest Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .disabled(moves.isEmpty)
                    .accessibilityIdentifier(A11yID.Project.suggestOrderApply)
                }
            }
            .accessibilityIdentifier(A11yID.Project.suggestOrderPreview)
        }
        .presentationDetents([.medium, .large])
    }
}
