import SwiftUI

/// Configure and export a branded audiogram video for social sharing.
struct AudiogramExportSheet: View {
    let mix: Mix
    let song: Song

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var startTime: Double = 0
    @State private var selectedDuration = 30
    @State private var format: CardFormat = .story
    @State private var exportedURL: URL?
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var errorMessage: String?
    @State private var exportTask: Task<Void, Never>?

    private let durationOptions = [15, 20, 30]

    private var maxDuration: Double {
        min(30, max(0, mix.duration - startTime))
    }

    private var exportDuration: Double {
        min(Double(selectedDuration), maxDuration)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Snippet") {
                    if mix.hasWaveform {
                        WaveformView(
                            samples: mix.waveform,
                            progress: mix.duration > 0 ? startTime / mix.duration : 0,
                            playedColor: Brand.accent,
                            onSeek: { fraction in
                                startTime = fraction * mix.duration
                            }
                        )
                        .frame(height: 72)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start: \(formatted(startTime))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Slider(
                            value: $startTime,
                            in: 0...max(mix.duration - 1, 0)
                        )
                        .accessibilityLabel("Snippet start")
                    }

                    Picker("Length", selection: $selectedDuration) {
                        ForEach(durationOptions, id: \.self) { seconds in
                            Text("\(seconds)s").tag(seconds)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Format", selection: $format) {
                        ForEach(CardFormat.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    if isExporting {
                        ProgressView(value: exportProgress)
                        Text("Rendering audiogram…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Cancel", role: .cancel) {
                            cancelExport()
                        }
                    } else if let exportedURL {
                        ShareLink(item: exportedURL) {
                            Label("Share Video", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Export Audiogram") {
                            exportAudiogram()
                        }
                        .disabled(exportDuration <= 0)
                    }
                }
            }
            .brandFormChrome()
            .navigationTitle("Audiogram")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Export Failed", isPresented: errorPresented) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .presentationDetents([.medium, .large])
        .onDisappear {
            cancelExport()
            removeExportedFile()
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func formatted(_ time: Double) -> String {
        let total = Int(time.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func removeExportedFile() {
        guard let exportedURL else { return }
        try? FileManager.default.removeItem(at: exportedURL)
        self.exportedURL = nil
    }

    private func cancelExport() {
        exportTask?.cancel()
        exportTask = nil
        isExporting = false
    }

    private func exportAudiogram() {
        removeExportedFile()
        isExporting = true
        exportProgress = 0

        let request = AudiogramRenderer.Request.make(
            mix: mix,
            song: song,
            options: AudiogramRenderer.ExportOptions(
                startTime: startTime,
                duration: exportDuration,
                format: format,
                reduceMotion: reduceMotion
            ),
            brand: BrandKitSettings.current()
        )

        exportTask = Task { @MainActor in
            do {
                let url = try await AudiogramRenderer.export(request) { value in
                    Task { @MainActor in exportProgress = value }
                }
                guard !Task.isCancelled else {
                    try? FileManager.default.removeItem(at: url)
                    return
                }
                exportedURL = url
                Haptics.success()
            } catch is CancellationError {
                // User cancelled — no error alert.
            } catch {
                errorMessage = "Couldn't render the video. Try a shorter snippet."
            }
            isExporting = false
            exportTask = nil
        }
    }
}
