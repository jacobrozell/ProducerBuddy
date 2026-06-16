import SwiftUI
import UIKit

/// Renders `ShareCardView`s into PNG files on disk so they can be handed to a
/// `ShareLink` and posted to social apps as real images.
@MainActor
enum ReleaseCardRenderer {
    /// Renders the given content/format to a PNG in the temporary directory.
    /// - Returns: a file URL to the PNG, or nil if rendering failed.
    static func renderPNG(content: CardContent, format: CardFormat) -> URL? {
        let renderer = ImageRenderer(content: ShareCardView(content: content, format: format))
        // 3× gives social-ready pixels (e.g. 1020×1812 for a story).
        renderer.scale = 3

        guard let image = renderer.uiImage,
              let data = image.pngData() else { return nil }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileStem(for: content)).png")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// A filesystem-safe stem derived from the content's title.
    private static func fileStem(for content: CardContent) -> String {
        let raw: String
        switch content {
        case .song(let song): raw = song.title
        case .project(let project): raw = project.title
        }
        let safe = raw
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        return safe.isEmpty ? "MixStack-Card" : safe
    }
}
