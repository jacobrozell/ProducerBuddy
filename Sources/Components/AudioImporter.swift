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

/// Multi-select variant used by the import-first Library flow. Each picked file
/// is copied into storage and has its tags read; the results are reported back
/// together once all imports finish.
struct SongImporter: ViewModifier {
    @Binding var isPresented: Bool
    let onImport: (_ results: [ImportedAudio]) -> Void

    func body(content: Content) -> some View {
        content.fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: [.audio, .mpeg4Audio, .mp3, .wav, .aiff],
            allowsMultipleSelection: true
        ) { result in
            guard case let .success(urls) = result, !urls.isEmpty else { return }
            Task {
                var imported: [ImportedAudio] = []
                for url in urls {
                    if let audio = try? await AudioStorage.importAudio(from: url) {
                        imported.append(audio)
                    }
                }
                await MainActor.run { onImport(imported) }
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

    /// Presents a multi-select audio importer that creates one result per file,
    /// with embedded metadata and a suggested title already resolved.
    func songImporter(
        isPresented: Binding<Bool>,
        onImport: @escaping (_ results: [ImportedAudio]) -> Void
    ) -> some View {
        modifier(SongImporter(isPresented: isPresented, onImport: onImport))
    }
}
