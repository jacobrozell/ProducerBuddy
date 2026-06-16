import SwiftUI

/// Presents a live preview of a shareable release card, lets the user pick a
/// format, and shares the rendered PNG via the system share sheet.
struct ShareCardSheet: View {
    let content: CardContent
    @Environment(\.dismiss) private var dismiss

    @State private var format: CardFormat = .square
    @State private var renderedURL: URL?
    @State private var isRendering = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("Format", selection: $format) {
                    ForEach(CardFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)

                // Preview is the same view that gets rendered to the PNG.
                ScrollView {
                    ShareCardView(content: content, format: format)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 8, y: 4)
                        .padding(.vertical, 8)
                }

                if let url = renderedURL {
                    ShareLink(item: url, preview: SharePreview("Release Card", image: Image(systemName: "photo"))) {
                        Label("Share Image", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
            }
            .padding()
            .navigationTitle("Share Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            // Re-render whenever the chosen format changes.
            .task(id: format) { render() }
        }
    }

    private func render() {
        isRendering = true
        renderedURL = ReleaseCardRenderer.renderPNG(content: content, format: format)
        isRendering = false
    }
}
