import SwiftUI
import UniformTypeIdentifiers

/// View-modifier wrapper around `.fileImporter` configured for audio files.
/// Imports the chosen file into `AudioStorage` and hands back the stored
/// filename plus its measured duration.
struct AudioImporter: ViewModifier {
    @Binding var isPresented: Bool
    let onImport: (_ fileName: String, _ duration: Double, _ sourceBasename: String) -> Void

    func body(content: Content) -> some View {
        content.fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: [.audio, .mpeg4Audio, .mp3, .wav, .aiff],
            allowsMultipleSelection: false
        ) { result in
            guard case let .success(urls) = result, let url = urls.first else { return }
            let sourceBasename = url.deletingPathExtension().lastPathComponent
            do {
                let fileName = try AudioStorage.importFile(from: url)
                Task {
                    let duration = await AudioStorage.duration(of: fileName)
                    await MainActor.run { onImport(fileName, duration, sourceBasename) }
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
    @Binding var importTask: Task<Void, Never>?
    var onProgress: ((_ current: Int, _ total: Int) -> Void)?
    let onImport: (_ results: [ImportedAudio], _ failures: [String]) -> Void

    func body(content: Content) -> some View {
        content.fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: [.audio, .mpeg4Audio, .mp3, .wav, .aiff],
            allowsMultipleSelection: true
        ) { result in
            guard case let .success(urls) = result, !urls.isEmpty else { return }
            importTask?.cancel()
            importTask = Task { @MainActor in
                var imported: [ImportedAudio] = []
                var failures: [String] = []
                let total = urls.count
                for (index, url) in urls.enumerated() {
                    if Task.isCancelled { return }
                    onProgress?(index + 1, total)
                    do {
                        let audio = try await AudioStorage.importAudio(from: url)
                        imported.append(audio)
                    } catch {
                        failures.append(url.lastPathComponent)
                    }
                }
                guard !Task.isCancelled else { return }
                onImport(imported, failures)
            }
        }
    }
}

extension View {
    /// Presents an audio file importer that stores the file and reports back its
    /// filename and duration.
    func audioImporter(
        isPresented: Binding<Bool>,
        onImport: @escaping (_ fileName: String, _ duration: Double, _ sourceBasename: String) -> Void
    ) -> some View {
        modifier(AudioImporter(isPresented: isPresented, onImport: onImport))
    }

    /// Presents a multi-select audio importer that creates one result per file,
    /// with embedded metadata and a suggested title already resolved.
    func songImporter(
        isPresented: Binding<Bool>,
        importTask: Binding<Task<Void, Never>?>,
        onProgress: ((_ current: Int, _ total: Int) -> Void)? = nil,
        onImport: @escaping (_ results: [ImportedAudio], _ failures: [String]) -> Void
    ) -> some View {
        modifier(SongImporter(
            isPresented: isPresented,
            importTask: importTask,
            onProgress: onProgress,
            onImport: onImport
        ))
    }
}
