import SwiftUI
import UniformTypeIdentifiers

/// View-modifier wrapper around `.fileImporter` configured for audio files.
/// Imports the chosen file into `AudioStorage` and hands back the stored
/// filename plus its measured duration.
struct AudioImporter: ViewModifier {
    @Binding var isPresented: Bool
    let onImport: (_ fileName: String, _ duration: Double) -> Void

    func body(content: Content) -> some View {
        content.fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: [.audio, .mpeg4Audio, .mp3, .wav, .aiff],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result, let url = urls.first else { return }
            do {
                let fileName = try AudioStorage.importFile(from: url)
                Task {
                    let duration = await AudioStorage.duration(of: fileName)
                    await MainActor.run { onImport(fileName, duration) }
                }
            } catch {
                // Import failures are silently ignored; the user can retry.
            }
        }
    }
}

extension View {
    /// Presents an audio file importer that stores the file and reports back its
    /// filename and duration.
    func audioImporter(
        isPresented: Binding<Bool>,
        onImport: @escaping (_ fileName: String, _ duration: Double) -> Void
    ) -> some View {
        modifier(AudioImporter(isPresented: isPresented, onImport: onImport))
    }
}
